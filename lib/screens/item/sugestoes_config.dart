import 'package:flutter/foundation.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';

// Leitura da configuração das sugestões gravada pela Dashboard
// (Filial/{filial}.cardapioMesaSugestoes), no mesmo formato e com as mesmas
// regras do cardápio de mesa do tablet. Separado da tela para poder ser
// testado sem o navegador.

/// Produtos escolhidos na Dashboard para uma etapa (bebida / sobremesa)
class SugestaoConfig {
  const SugestaoConfig(
      {this.ids = const [],
      this.plus = const [],
      this.fora = const [],
      this.categorias = const [],
      this.titulo = '',
      this.somente = false,
      this.desativada = false,
      this.ligada = false});

  /// Desligada na Dashboard: esta etapa não aparece
  final bool desativada;

  /// Ligada só nesta categoria, mesmo sem nada escolhido (não segue a geral,
  /// que pode estar desligada)
  final bool ligada;

  bool get temProdutos => ids.isNotEmpty || plus.isNotEmpty;

  bool get temEscolhidos => temProdutos || categorias.isNotEmpty;

  /// Produto fora do cardápio (cadastrado só na sugestão, com nome e foto
  /// próprios); null = produto do cardápio. Mesma posição de [plus].
  final List<ItemModel?> fora;

  /// Configurada na Dashboard (produtos, categorias, texto ou o switch):
  /// a da categoria deixa de seguir a geral
  bool get definida =>
      temEscolhidos || titulo.isNotEmpty || desativada || ligada;

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

  static SugestaoConfig ler(dynamic m) {
    if (m is! Map) return const SugestaoConfig();
    final produtos = ((m['produtos'] as List?) ?? [])
        .whereType<Map>()
        .where((p) => (p['plu']?.toString() ?? '').isNotEmpty)
        .toList();
    return SugestaoConfig(
      ids: [for (final p in produtos) (p['id'] as num?)?.toInt() ?? 0],
      plus: [for (final p in produtos) p['plu']?.toString() ?? ''],
      fora: [
        for (final p in produtos)
          p['fora'] == true
              ? ItemModel(
                  plu: p['plu'].toString(),
                  desProduto: p['nome']?.toString().trim() ?? '',
                  imageUrl: p['imagem']?.toString().trim() ?? '',
                )
              : null,
      ],
      categorias: [
        for (final c in ((m['categorias'] as List?) ?? []).whereType<Map>())
          if ((c['id'] as num?) != null) (c['id'] as num).toInt(),
      ],
      titulo: m['titulo']?.toString().trim() ?? '',
      somente: m['somente'] == true,
      desativada: m['desativada'] == true,
      ligada: m['ligada'] == true,
    );
  }
}

/// Ordem das etapas definida na Dashboard: '' = geral, id da categoria =
/// sugestão própria dela. Sem nada: bebida e depois sobremesa.
Map<String, List<String>> sugestoesOrdens = const {};

/// Sugestões criadas na Dashboard além de bebida e sobremesa ("Nova
/// sugestão", ex.: Salgados): (chave, nome). Só aparecem com algo escolhido.
List<(String, String)> sugestoesExtras = const [];

List<String> get sugestoesEtapasConhecidas =>
    ['bebida', 'sobremesa', for (final e in sugestoesExtras) e.$1];

bool ehChaveExtraSugestao(String chaveConfig) =>
    chaveConfig.split('/').last.startsWith('extra_');

List<String>? _lerOrdem(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : null;

/// Ordem salva (só etapas que existem) + as que faltarem, na ordem padrão
List<String> ordemFinalSugestoes(List<String>? salva) {
  final conhecidas = sugestoesEtapasConhecidas;
  final o =
      (salva ?? const <String>[]).where(conhecidas.contains).toSet().toList();
  return [...o, ...conhecidas.where((k) => !o.contains(k))];
}

/// Lê cardapioMesaSugestoes (mesmo formato do tablet). Chaves do mapa:
/// 'bebida'/'sobremesa'/'extra_…' (geral) e 'idCategoria/bebida' etc.
/// (sugestão própria de uma categoria, campo porCategoria).
Map<String, SugestaoConfig> lerConfigSugestoes(Map<String, dynamic>? filial) {
  final s = filial?['cardapioMesaSugestoes'];
  if (s is! Map) {
    sugestoesOrdens = const {};
    sugestoesExtras = const [];
    return const {};
  }
  sugestoesExtras = [
    for (final e in ((s['extras'] as List?) ?? []).whereType<Map>())
      if ((e['chave']?.toString() ?? '').startsWith('extra_'))
        (e['chave'].toString(), e['nome']?.toString().trim() ?? ''),
  ];
  final etapas = sugestoesEtapasConhecidas;
  final porCategoria = s['porCategoria'];
  sugestoesOrdens = {
    if (_lerOrdem(s['ordem']) case final o?) '': o,
    if (porCategoria is Map)
      for (final e in porCategoria.entries)
        if (e.value is Map)
          if (_lerOrdem(e.value['ordem']) case final o?) e.key.toString(): o,
  };
  return {
    for (final etapa in etapas) etapa: SugestaoConfig.ler(s[etapa]),
    if (porCategoria is Map)
      for (final e in porCategoria.entries)
        if (e.value is Map)
          for (final etapa in etapas)
            '${e.key}/$etapa': SugestaoConfig.ler(e.value[etapa]),
  };
}

/// Para teste: quais etapas podem aparecer para um prato da categoria, na
/// ordem (igual ao tablet). Bebida/sobremesa ligadas sempre podem (sem nada
/// escolhido usam as categorias pelo nome); as criadas só com algo escolhido.
@visibleForTesting
List<({String etapa, String titulo, List<String> plus, List<int> categorias})>
    planoSugestoesParaTeste(Map<String, dynamic> filial, int? idCategoria) {
  final config = lerConfigSugestoes(filial);
  final ordem = ordemFinalSugestoes(
      sugestoesOrdens['$idCategoria'] ?? sugestoesOrdens['']);
  return [
    for (final etapa in ordem)
      if (cfgEtapaSugestao(config, etapa, idCategoria) case final k
          when !k.desativada &&
              (etapa == 'bebida' || etapa == 'sobremesa' || k.temEscolhidos))
        (
          etapa: etapa,
          titulo: k.titulo,
          plus: k.plus,
          categorias: k.categorias,
        ),
  ];
}

/// Config da etapa: a própria da categoria do prato (se definida) ou a geral
SugestaoConfig cfgEtapaSugestao(
    Map<String, SugestaoConfig> config, String etapa, int? idCategoria) {
  final propria = config['$idCategoria/$etapa'];
  if (propria != null && propria.definida) return propria;
  return config[etapa] ?? const SugestaoConfig();
}
