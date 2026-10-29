import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/categorias.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';

/// Cardápio igual ao do tablet (cardápio de mesa): mesmas categorias,
/// mesma ordem e mesmas regras de horário.
class CardapioService {
  /// Categorias da última carga (as que estão aparecendo agora)
  static List<Categoria> ultimas = [];

  static final _produtos = <int, Future<List<ItemModel>>>{};

  /// Produtos ativos da categoria (sem preço; uma busca por sessão)
  static Future<List<ItemModel>> produtosDe(int idCategoria) =>
      _produtos[idCategoria] ??= () async {
        try {
          final r = await http
              .get(Uri.parse('${Urls.urlApiAzure}Categorias/'
                  'categoria-produto-by-filial/$idCategoria'
                  '?idFilial=$codFilialCardapio'))
              .timeout(const Duration(seconds: 15));
          if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
          final data = jsonDecode(utf8.decode(r.bodyBytes));
          return [
            for (final j in (data as List).whereType<Map<String, dynamic>>())
              ItemModel.fromJson(j),
          ].where((p) => p.ativo != false && (p.plu ?? '').isNotEmpty).toList();
        } catch (e) {
          debugPrint('Produtos $idCategoria: $e');
          _produtos.remove(idCategoria);
          return <ItemModel>[];
        }
      }();
  static int? _minutos(dynamic hora) {
    final partes = (hora ?? '').toString().split(':');
    if (partes.length < 2) return null;
    final h = int.tryParse(partes[0]), m = int.tryParse(partes[1]);
    return (h == null || m == null) ? null : h * 60 + m;
  }

  /// [m] (minutos do dia) dentro da faixa; aceita faixa que passa da
  /// meia-noite (ex.: 18:00 às 00:00).
  static bool _naFaixa(int m, int ini, int fimBruto) {
    final fim = fimBruto == 0 ? 24 * 60 : fimBruto;
    return ini < fim ? (m >= ini && m < fim) : (m >= ini || m < fim);
  }

  static Future<List<Map<String, dynamic>>> _categoriasDe(String filial) async {
    final r = await http
        .get(Uri.parse(
            '${Urls.urlApiAzure}Categorias/categoria-by-filial-all/$filial'))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('Categorias: HTTP ${r.statusCode}');
    }
    final data = jsonDecode(utf8.decode(r.bodyBytes));
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .where((c) => c['id'] != null && c['ativo'] != false)
        .toList();
  }

  /// Categorias "ocultar no horário" definidas na Dashboard
  /// (Filial/{filial}.cardapioMesaCategoriasOcultas).
  static Future<Map<int, (int, int)>> _ocultas(String filial) async {
    try {
      final dados = filial == codFilial
          ? dadosFilialFirestore
          : (await FirebaseFirestore.instance
                      .collection('Filial')
                      .doc(filial)
                      .get()
                      .timeout(const Duration(seconds: 5)))
                  .data() ??
              {};
      final ocultas = dados['cardapioMesaCategoriasOcultas'];
      if (ocultas is! Map) return {};
      final r = <int, (int, int)>{};
      ocultas.forEach((id, faixa) {
        if (faixa is! Map) return;
        final ini = _minutos(faixa['inicio']), fim = _minutos(faixa['fim']);
        final idCat = int.tryParse(id.toString());
        if (idCat != null && ini != null && fim != null) r[idCat] = (ini, fim);
      });
      return r;
    } catch (e) {
      debugPrint('categoriasOcultas: $e');
      return {};
    }
  }

  /// Usa o cardápio da própria filial; se ela ainda não tiver cardápio,
  /// usa o de Higienópolis ([filialCardapioPadrao]). Define
  /// [codFilialCardapio], usado também para buscar os produtos.
  static Future<List<Categoria>> categorias() async {
    var lista = await _categoriasDe(codFilial);
    codFilialCardapio = codFilial;
    if (lista.isEmpty && codFilial != filialCardapioPadrao) {
      lista = await _categoriasDe(filialCardapioPadrao);
      codFilialCardapio = filialCardapioPadrao;
    }
    final ocultas = await _ocultas(codFilialCardapio);

    final agora = DateTime.now();
    final m = agora.hour * 60 + agora.minute;
    bool noHorario(Map<String, dynamic> c) {
      final ini = _minutos(c['horaInicio']), fim = _minutos(c['horaFim']);
      if (ini == null || fim == null) return false;
      // dia todo (00:00 às 23:59) não conta como horário específico
      if (ini == 0 && (fim >= 23 * 60 + 59 || fim == 0)) return false;
      return _naFaixa(m, ini, fim);
    }

    final visiveis = lista.where((c) {
      final faixa = ocultas[(c['id'] as num).toInt()];
      return faixa == null || !_naFaixa(m, faixa.$1, faixa.$2);
    });
    // categorias no horário delas primeiro; o resto na ordem da Dashboard
    return ultimas = [
      ...visiveis.where(noHorario),
      ...visiveis.where((c) => !noHorario(c)),
    ].map(Categoria.fromJson).toList();
  }
}

/// Grupo de produtos cadastrado na Dashboard (ex.: "Pão de queijo" com as
/// opções "Fatia" e "Inteiro"): aparece como um card só.
class GrupoProdutos {
  GrupoProdutos({
    required this.id,
    required this.nome,
    required this.imagem,
    required this.opcoes,
  });

  final int id;
  final String nome;
  final String imagem;

  /// id do produto na categoria -> rótulo da opção (ordem da Dashboard)
  final List<MapEntry<int, String>> opcoes;

  /// Grupo "Pizza Meio a Meio" (com os PLUs MEIA de cada sabor): o cliente
  /// escolhe as duas metades
  bool get meioAMeio => nome.toLowerCase().contains('meio a meio');

  static Future<List<GrupoProdutos>>? _cache;

  /// Grupos da filial do cardápio (uma busca por sessão). Se falhar, o
  /// cardápio funciona normal, sem agrupar.
  static Future<List<GrupoProdutos>> todos() => _cache ??= () async {
        try {
          final r = await http
              .get(Uri.parse('${Urls.urlApiAzure}Complementos/grupos'
                  '?idFilial=$codFilialCardapio'))
              .timeout(const Duration(seconds: 15));
          if (r.statusCode != 200) return <GrupoProdutos>[];
          final data = jsonDecode(utf8.decode(r.bodyBytes));
          if (data is! List) return <GrupoProdutos>[];
          return [
            for (final g in data.whereType<Map>())
              GrupoProdutos(
                id: (g['id'] as num?)?.toInt() ?? 0,
                nome: (g['nome'] ?? '').toString().trim(),
                imagem: (g['imagem'] ?? '').toString().trim(),
                opcoes: [
                  for (final i
                      in ((g['itens'] as List?) ?? []).whereType<Map>())
                    MapEntry((i['idCategoriaProduto'] as num?)?.toInt() ?? 0,
                        (i['rotulo'] ?? '').toString().trim()),
                ],
              ),
          ].where((g) => g.opcoes.length >= 2).toList();
        } catch (e) {
          debugPrint('Grupos: $e');
          _cache = null;
          return <GrupoProdutos>[];
        }
      }();
}

/// Acréscimos e selos (vegano/vegetariano) cadastrados na Dashboard para a
/// filial do cardápio. Se falhar, o cardápio funciona normal, sem eles.
class Complementos {
  static Future<List<dynamic>> _buscar(String rota) async {
    try {
      final r = await http
          .get(Uri.parse('${Urls.urlApiAzure}Complementos/$rota'
              '?idFilial=$codFilialCardapio'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return const [];
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      return data is List ? data : const [];
    } catch (e) {
      debugPrint('Complementos $rota: $e');
      return const [];
    }
  }

  static Future<Map<int, ({bool vegetariano, bool vegano})>>? _selos;

  /// id do produto na categoria -> selos
  static Future<Map<int, ({bool vegetariano, bool vegano})>> selos() =>
      _selos ??= _buscar('selos').then((l) => {
            for (final s in l.whereType<Map>())
              ((s['idCategoriaProduto'] as num?)?.toInt() ?? 0): (
                vegetariano: s['vegetariano'] == true,
                vegano: s['vegano'] == true,
              ),
          });

  static Future<List<dynamic>>? _acrescimos;
  static final _precos = <String, Future<double?>>{};

  static final _mercadorias = <String, Future<Map?>>{};

  /// Mercadoria fiscal da Bratter (preço e opções), uma busca por PLU
  static Future<Map?> _mercadoria(String plu) =>
      _mercadorias[plu] ??= () async {
        try {
          final url = '${Urls.urlApiAzure}Proxy/mercadoriafiscal'
              '?codigoproduto=$plu&imagens=false'
              '&urlBratter=${Uri.encodeComponent(Urls.urlApiBratter)}'
              '&tokenBratter=${GlobalKeys.tokenBratter}';
          final r = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 15));
          if (r.statusCode != 200) return null;
          final j = jsonDecode(utf8.decode(r.bodyBytes));
          return j is Map ? j : null;
        } catch (e) {
          debugPrint('Mercadoria $plu: $e');
          _mercadorias.remove(plu);
          return null;
        }
      }();

  /// Produto com preço e opções da Bratter (para mostrar e abrir)
  static Future<ItemModel> completar(ItemModel p) async {
    if (p.preco != null) return p;
    final j = await _mercadoria(p.plu ?? '');
    if (j == null) return p;
    return p.copyWith(
      preco: double.tryParse(j['preco'].toString()),
      obs: [
        for (final o in ((j['obs'] as List?) ?? []).whereType<Map>())
          ItemObsModel.fromJson(Map<String, dynamic>.from(o)),
      ],
    );
  }

  static Future<double?> _preco(String plu) => _precos[plu] ??= () async {
        try {
          final url = '${Urls.urlApiAzure}Proxy/mercadoriafiscal'
              '?codigoproduto=$plu&imagens=false'
              '&urlBratter=${Uri.encodeComponent(Urls.urlApiBratter)}'
              '&tokenBratter=${GlobalKeys.tokenBratter}';
          final r = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 15));
          if (r.statusCode != 200) return null;
          final j = jsonDecode(utf8.decode(r.bodyBytes));
          return j is Map ? double.tryParse(j['preco'].toString()) : null;
        } catch (e) {
          debugPrint('Preço acréscimo $plu: $e');
          return null;
        }
      }();

  /// Acréscimos do produto, já com preço (os sem preço na Bratter ficam de
  /// fora, para não lançar errado na comanda).
  static Future<List<AcrescimoEscolhido>> doProduto(int? idProduto) async {
    if (idProduto == null) return const [];
    final todos = await (_acrescimos ??= _buscar('acrescimos'));
    final doProduto = todos.whereType<Map>().where((a) =>
        (a['idCategoriaProduto'] as num?)?.toInt() == idProduto &&
        (a['pluAcrescimo']?.toString() ?? '').isNotEmpty);
    final r = <AcrescimoEscolhido>[];
    for (final a in doProduto) {
      final plu = a['pluAcrescimo'].toString();
      // só observação: sem preço, não consulta a Bratter
      final preco = plu.trim().toUpperCase() == 'OBS' ? 0.0 : await _preco(plu);
      if (preco == null) continue;
      r.add(AcrescimoEscolhido(
        plu: plu,
        nome: (a['nome'] ?? '').toString().trim(),
        preco: preco,
      ));
    }
    return r;
  }
}

/// Produtos como aparecem na tela: os de um grupo (Dashboard) viram um item
/// só, `(grupo, opções)`, na posição do primeiro do grupo — como no tablet.
List<Object> agruparProdutos(
    List<ItemModel> produtos, List<GrupoProdutos> grupos) {
  final r = <Object>[];
  final mostrados = <int>{};
  for (final p in produtos) {
    final grupo = p.id == null
        ? null
        : grupos.where((g) => g.opcoes.any((o) => o.key == p.id)).firstOrNull;
    if (grupo == null) {
      r.add(p);
      continue;
    }
    if (mostrados.contains(grupo.id)) continue;
    final opcoes = [
      for (final o in grupo.opcoes)
        for (final x in produtos.where((x) => x.id == o.key))
          MapEntry(x, o.value.isEmpty ? (x.desProduto ?? '').trim() : o.value),
    ];
    if (opcoes.length < 2) {
      r.add(p);
      continue;
    }
    mostrados.add(grupo.id);
    r.add((grupo, opcoes));
  }
  // pizza meio a meio é o primeiro card da categoria
  final iMeio = r.indexWhere((x) =>
      x is (GrupoProdutos, List<MapEntry<ItemModel, String>>) &&
      x.$1.meioAMeio);
  if (iMeio > 0) r.insert(0, r.removeAt(iMeio));
  return r;
}

/// Renova o token da Bratter pelo Proxy (o site pode ficar aberto muito
/// tempo e o token vence).
Future<void> renovarTokenBratter() async {
  try {
    final url = '${Urls.urlApiAzure}Proxy/token'
        '?username=${GlobalKeys.userApiBratter}'
        '&password=${GlobalKeys.passwordApiBratter}'
        '&urlBratter=${Uri.encodeComponent('${Urls.urlApiBratter}User')}';
    final r =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return;
    final t = jsonDecode(r.body)['token']?.toString() ?? '';
    if (t.isNotEmpty) GlobalKeys.tokenBratter = t;
  } catch (e) {
    debugPrint('Renovar token Bratter: $e');
  }
}
