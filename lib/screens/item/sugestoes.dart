import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/categorias.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/screens/item/produto_popup.dart';
import 'package:webapp_pedido_mesa/services/cardapio_service.dart';

// Sugestões para aumentar o ticket médio, iguais às do cardápio de mesa do
// tablet: se o cliente pediu comida e ainda não tem bebida e/ou sobremesa,
// oferece primeiro as bebidas e depois as sobremesas. Os produtos podem ser
// escolhidos na Dashboard (Filial/{filial}.cardapioMesaSugestoes).

String _normalizar(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = de.indexOf(ch);
    b.write(i >= 0 ? para[i] : ch);
  }
  return b.toString();
}

/// Palavras de categorias de bebida, na ordem de preferência
const _palavrasBebida = [
  'suco', 'refri', 'bebida', 'agua', 'vitamina', 'smoothie', 'milkshake',
  'drink', 'cafe', ' cha ', ' chas ', //
];

/// Palavras de categorias de doces, na ordem de preferência
const _palavrasDoce = [
  'sobremesa', 'doce', 'chocolate', 'sorvete', 'brigadeiro', 'bolo',
  'confeitaria', //
];

int _posicao(Categoria c, List<String> palavras) {
  final nome = ' ${_normalizar(c.desCategoria)} ';
  return palavras.indexWhere(nome.contains);
}

bool _ehBebida(Categoria c) => _posicao(c, _palavrasBebida) >= 0;
bool _ehDoce(Categoria c) => _posicao(c, _palavrasDoce) >= 0;

/// Produtos escolhidos na Dashboard para uma etapa (bebida / sobremesa)
class _Config {
  const _Config(
      {this.ids = const [],
      this.plus = const [],
      this.categorias = const [],
      this.titulo = '',
      this.somente = false});

  /// categorias inteiras escolhidas na Dashboard (ids), na ordem
  final List<int> categorias;

  /// texto do popup definido na Dashboard (vazio = padrão)
  final String titulo;

  final List<int> ids;
  final List<String> plus;

  /// true: mostra só os escolhidos; false: escolhidos primeiro
  final bool somente;

  bool contem(ItemModel p) =>
      (p.id != null && ids.contains(p.id)) ||
      plus.contains(p.plu) ||
      categorias.contains(p.idCategoriaFilial);

  static _Config ler(dynamic m) {
    if (m is! Map) return const _Config();
    final produtos = ((m['produtos'] as List?) ?? []).whereType<Map>().toList();
    return _Config(
      ids: [for (final p in produtos) (p['id'] as num?)?.toInt() ?? 0],
      plus: [for (final p in produtos) p['plu']?.toString() ?? ''],
      categorias: [
        for (final c in ((m['categorias'] as List?) ?? []).whereType<Map>())
          if ((c['id'] as num?) != null) (c['id'] as num).toInt(),
      ],
      titulo: m['titulo']?.toString().trim() ?? '',
      somente: m['somente'] == true,
    );
  }
}

Future<(_Config, _Config)> _carregarConfig() async {
  try {
    final dados = codFilialCardapio == codFilial
        ? dadosFilialFirestore
        : (await FirebaseFirestore.instance
                    .collection('Filial')
                    .doc(codFilialCardapio)
                    .get()
                    .timeout(const Duration(seconds: 3)))
                .data() ??
            {};
    final s = dados['cardapioMesaSugestoes'];
    if (s is! Map) return (const _Config(), const _Config());
    return (_Config.ler(s['bebida']), _Config.ler(s['sobremesa']));
  } catch (_) {
    return (const _Config(), const _Config());
  }
}

/// Já ofereceu para o carrinho atual (volta a oferecer num carrinho novo)
bool sugestoesOferecidas = false;
bool _abertas = false;

/// Antes de enviar o pedido (se ainda não ofereceu ao adicionar um prato)
Future<void> oferecerSugestoesAntesDeEnviar(BuildContext context) async {
  if (sugestoesOferecidas) return;
  await _oferecer(context);
}

/// Logo depois de adicionar um prato (não bebida/doce)
Future<void> oferecerSugestoesAposAdicionar(
        BuildContext context, ItemModel adicionado) =>
    _oferecer(context, adicionado: adicionado);

class _Etapa {
  const _Etapa(this.icone, this.titulo, this.subtitulo, this.produtos);

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final Future<List<Object>> produtos;
}

Future<(_Config, _Config)>? _config;
final _etapas = <bool, Future<List<Object>>>{};

/// Carrega as sugestões em segundo plano assim que o cardápio abre: na hora
/// de mostrar, bebidas e sobremesas já estão prontas (sem espera).
void preCarregarSugestoes() {
  _produtosEtapa(bebida: true);
  _produtosEtapa(bebida: false);
}

/// Produtos de uma etapa (bebida / sobremesa), com preço; não dependem do
/// carrinho, então ficam guardados para a sessão.
Future<List<Object>> _produtosEtapa({required bool bebida}) =>
    _etapas[bebida] ??= () async {
      final categorias = CardapioService.ultimas;
      final (cfgBebida, cfgDoce) = await (_config ??= _carregarConfig());
      final cfg = bebida ? cfgBebida : cfgDoce;
      final palavras = bebida ? _palavrasBebida : _palavrasDoce;
      final filtro = bebida ? _ehBebida : _ehDoce;
      final todos = <ItemModel>[];
      // escolhidos na Dashboard: podem estar em qualquer categoria
      if (cfg.ids.isNotEmpty || cfg.plus.isNotEmpty) {
        final listas = await Future.wait(
            categorias.map((c) => CardapioService.produtosDe(c.id)));
        final tudo = listas.expand((l) => l).toList();
        for (var i = 0; i < cfg.ids.length; i++) {
          final p = tudo.where((x) => x.id == cfg.ids[i]).firstOrNull ??
              (i < cfg.plus.length
                  ? tudo.where((x) => x.plu == cfg.plus[i]).firstOrNull
                  : null);
          if (p != null && !todos.any((x) => x.plu == p.plu)) todos.add(p);
        }
      }
      // categorias escolhidas (só as que aparecem agora, pelo horário)
      final escolhidas = [
        for (final id in cfg.categorias)
          ...categorias.where((c) => c.id == id),
      ];
      final listasEscolhidas = await Future.wait(
          escolhidas.map((c) => CardapioService.produtosDe(c.id)));
      for (final p in listasEscolhidas.expand((l) => l)) {
        if (!todos.any((x) => x.plu == p.plu)) todos.add(p);
      }
      if (!cfg.somente || todos.isEmpty) {
        final cats = categorias
            .where(filtro)
            .where((c) => !cfg.categorias.contains(c.id))
            .toList()
          ..sort(
              (a, b) => _posicao(a, palavras).compareTo(_posicao(b, palavras)));
        // categorias em paralelo
        final listas = await Future.wait(
            cats.map((c) => CardapioService.produtosDe(c.id)));
        for (final p in listas.expand((l) => l)) {
          if (!todos.any((x) => x.plu == p.plu)) todos.add(p);
        }
      }
      // preço e opções da Bratter (só dos que serão mostrados)
      final completos =
          await Future.wait(todos.take(14).map(Complementos.completar));
      final comPreco = completos.where((p) => p.preco != null).toList();
      // sem nada (ex.: sem rede): tenta de novo na próxima vez
      if (comPreco.isEmpty) _etapas.remove(bebida);
      // produtos agrupados (Dashboard) aparecem juntos, num card só
      return agruparProdutos(comPreco, await GrupoProdutos.todos());
    }();

Future<void> _oferecer(BuildContext context, {ItemModel? adicionado}) async {
  if (_abertas) return;
  final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
  final categorias = CardapioService.ultimas;
  if (carrinho.itens.isEmpty || categorias.isEmpty) return;
  final porId = {for (final c in categorias) c.id: c};
  final (cfgBebida, cfgDoce) = await (_config ??= _carregarConfig());
  String texto(_Config cfg, String padrao) =>
      cfg.titulo.isNotEmpty ? cfg.titulo : padrao;

  bool bebida(ItemModel p) {
    final c = porId[p.idCategoriaFilial];
    return (c != null && _ehBebida(c)) || cfgBebida.contem(p);
  }

  bool doce(ItemModel p) {
    final c = porId[p.idCategoriaFilial];
    return (c != null && _ehDoce(c)) || cfgDoce.contem(p);
  }

  // o próprio produto adicionado é bebida ou doce: não oferece nada
  if (adicionado != null && (bebida(adicionado) || doce(adicionado))) return;

  final itens = carrinho.itens.map((i) => i.produto).toList();
  final temBebida = itens.any(bebida);
  final temDoce = itens.any((p) => !bebida(p) && doce(p));
  final pratos = itens.where((p) => !bebida(p) && !doce(p)).toList();
  // todo salgado adicionado oferece bebida (mesmo já tendo uma); no
  // "enviar pedido" só oferece o que falta
  final oferecerBebida = adicionado != null || !temBebida;
  if (pratos.isEmpty || (!oferecerBebida && temDoce)) return;

  String capitalizar(String s) {
    final t = s.trim().toLowerCase();
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }

  final nomePrato = adicionado?.desProduto ?? pratos.first.desProduto ?? '';
  final etapas = [
    if (oferecerBebida)
      _Etapa(
        Icons.local_drink_rounded,
        texto(cfgBebida, 'Que tal uma bebida?'),
        'Pra acompanhar o seu ${capitalizar(nomePrato)}',
        _produtosEtapa(bebida: true),
      ),
    if (!temDoce)
      _Etapa(
        Icons.icecream_rounded,
        texto(cfgDoce, 'Vai uma sobremesa?'),
        'Pra fechar a refeição com chave de ouro',
        _produtosEtapa(bebida: false),
      ),
  ];
  if (!context.mounted) return;

  sugestoesOferecidas = true;
  _abertas = true;
  try {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SugestoesSheet(etapas: etapas),
    );
  } finally {
    _abertas = false;
  }
}

class _SugestoesSheet extends StatefulWidget {
  const _SugestoesSheet({required this.etapas});

  final List<_Etapa> etapas;

  @override
  State<_SugestoesSheet> createState() => _SugestoesSheetState();
}

class _SugestoesSheetState extends State<_SugestoesSheet> {
  int _etapa = 0;
  bool _adicionou = false;

  void _avancar() {
    if (_etapa + 1 >= widget.etapas.length) {
      Navigator.pop(context);
      return;
    }
    setState(() => _etapa++);
  }

  Future<void> _abrir(Object item) async {
    final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
    final antes = carrinho.totalItens;
    if (item is (GrupoProdutos, List<MapEntry<ItemModel, String>>)) {
      await escolherOpcaoGrupo(context, item.$1, item.$2, sugerir: false);
    } else {
      await abrirProdutoPopup(context, item as ItemModel, sugerir: false);
    }
    if (!mounted || carrinho.totalItens == antes) return;
    setState(() => _adicionou = true);
    _avancar();
  }

  @override
  Widget build(BuildContext context) {
    final etapa = widget.etapas[_etapa];
    final ultima = _etapa + 1 >= widget.etapas.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1E3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(etapa.icone, color: const Color(0xFFE8710A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _adicionou && _etapa > 0
                            ? 'Ótima escolha! ${etapa.titulo}'
                            : etapa.titulo,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                      Text(etapa.subtitulo,
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              // key por etapa: ao trocar, não mostra a lista da etapa anterior
              child: FutureBuilder<List<Object>>(
                key: ValueKey(_etapa),
                future: etapa.produtos,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done ||
                      !snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFE8710A)));
                  }
                  final lista = snap.data!;
                  if (lista.isEmpty) {
                    return Center(
                      child: Text('Nada para sugerir agora',
                          style: TextStyle(color: Colors.grey.shade600)),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _card(lista[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _avancar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  ultima ? 'Não, obrigado' : 'Não, obrigado · próxima',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Object item) {
    final String nome, imagem;
    final double preco;
    var aPartirDe = false;
    if (item is (GrupoProdutos, List<MapEntry<ItemModel, String>>)) {
      final (grupo, opcoes) = item;
      final precos = opcoes.map((o) => o.key.preco ?? 0).toList();
      nome = grupo.nome.isNotEmpty
          ? grupo.nome
          : (opcoes.first.key.desProduto ?? '').trim();
      imagem = grupo.imagem.isNotEmpty
          ? grupo.imagem
          : (opcoes.first.key.imageUrl ?? '');
      preco = precos.reduce((a, b) => a < b ? a : b);
      aPartirDe = precos.toSet().length > 1;
    } else {
      final p = item as ItemModel;
      nome = (p.desProduto ?? '').trim();
      imagem = p.imageUrl ?? '';
      preco = p.preco ?? 0;
    }
    return GestureDetector(
      onTap: () => _abrir(item),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 140,
                height: 110,
                child: imagem.isNotEmpty
                    ? Image.network(imagem,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                            'images/default_logo.png',
                            fit: BoxFit.cover))
                    : Image.asset('images/default_logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 6),
            // nome sempre com a altura de 2 linhas: o preço fica na mesma
            // posição em todos os cards
            SizedBox(
              height: 34,
              child: Text(
                nome.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, height: 1.15),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  // "a partir de" menor; a linha sempre cabe inteira
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(children: [
                        if (aPartirDe)
                          const TextSpan(
                            text: 'a partir de ',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        TextSpan(
                            text:
                                'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}'),
                      ]),
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE8710A)),
                    ),
                  ),
                ),
                const Icon(Icons.add_circle_rounded,
                    color: Color(0xFFE8710A), size: 26),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
