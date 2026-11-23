import 'package:webapp_pedido_mesa/screens/item/sugestoes_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configuração no formato que a Dashboard grava (cardapioMesaSugestoes).
Map<String, dynamic> filial(Map<String, dynamic> sugestoes) =>
    {'cardapioMesaSugestoes': sugestoes};

Map<String, dynamic> etapa({
  bool desativada = false,
  bool ligada = false,
  String titulo = '',
  List<String> plus = const [],
  List<int> categorias = const [],
}) =>
    {
      if (desativada) 'desativada': true,
      if (ligada) 'ligada': true,
      'somente': false,
      'produtos': [
        for (final p in plus) {'id': 0, 'plu': p, 'nome': 'P$p'}
      ],
      'categorias': [
        for (final c in categorias) {'id': c, 'nome': 'C$c'}
      ],
      'titulo': titulo,
    };

List<String> etapas(Map<String, dynamic> f, [int? cat]) =>
    planoSugestoesParaTeste(f, cat).map((e) => e.etapa).toList();

void main() {
  test('sem configuração: bebida e depois sobremesa', () {
    expect(etapas({}), ['bebida', 'sobremesa']);
    expect(etapas(filial({})), ['bebida', 'sobremesa']);
  });

  test('configuração antiga (sem ordem/extras) continua igual', () {
    final f = filial({
      'bebida': etapa(plus: ['10']),
      'sobremesa': etapa(),
    });
    expect(etapas(f), ['bebida', 'sobremesa']);
  });

  test('ordem geral invertida', () {
    final f = filial({
      'bebida': etapa(),
      'sobremesa': etapa(),
      'ordem': ['sobremesa', 'bebida'],
    });
    expect(etapas(f), ['sobremesa', 'bebida']);
    // categoria sem ordem própria segue a geral
    expect(etapas(f, 7), ['sobremesa', 'bebida']);
  });

  test('bebida desligada na geral', () {
    final f = filial({
      'bebida': etapa(desativada: true),
      'sobremesa': etapa(),
    });
    expect(etapas(f), ['sobremesa']);
  });

  test('Matinais vazio segue a geral desligada', () {
    final f = filial({
      'bebida': etapa(desativada: true),
      'sobremesa': etapa(),
      'porCategoria': {
        '7': {'nome': 'Matinais', 'bebida': etapa(), 'sobremesa': etapa()},
      },
    });
    expect(etapas(f, 7), ['sobremesa']);
  });

  test('Matinais com bebidas escolhidas aparece mesmo com a geral desligada',
      () {
    final f = filial({
      'bebida': etapa(desativada: true),
      'sobremesa': etapa(),
      'porCategoria': {
        '7': {
          'nome': 'Matinais',
          'bebida': etapa(plus: ['555']),
          'sobremesa': etapa(),
        },
      },
    });
    final plano = planoSugestoesParaTeste(f, 7);
    expect(plano.map((e) => e.etapa), ['bebida', 'sobremesa']);
    expect(plano.first.plus, ['555']);
    // outra categoria continua sem bebida
    expect(etapas(f, 8), ['sobremesa']);
  });

  test('Matinais com só o texto da bebida usa o texto, mesmo com geral off',
      () {
    final f = filial({
      'bebida': etapa(desativada: true),
      'porCategoria': {
        '7': {'bebida': etapa(titulo: 'Um café?')},
      },
    });
    final plano = planoSugestoesParaTeste(f, 7);
    expect(plano.first.etapa, 'bebida');
    expect(plano.first.titulo, 'Um café?');
  });

  test('desligar só nos Matinais', () {
    final f = filial({
      'bebida': etapa(),
      'sobremesa': etapa(),
      'porCategoria': {
        '7': {'bebida': etapa(desativada: true)},
      },
    });
    expect(etapas(f, 7), ['sobremesa']);
    expect(etapas(f, 8), ['bebida', 'sobremesa']);
  });

  test('nova sugestão: só aparece com algo escolhido, na ordem salva', () {
    final f = filial({
      'bebida': etapa(),
      'sobremesa': etapa(),
      'extra_1': etapa(plus: ['900'], titulo: 'Leva um salgado?'),
      'extra_2': etapa(), // vazia: não aparece
      'extras': [
        {'chave': 'extra_1', 'nome': 'Salgados'},
        {'chave': 'extra_2', 'nome': 'Combos'},
      ],
      'ordem': ['extra_1', 'bebida', 'extra_2', 'sobremesa'],
    });
    final plano = planoSugestoesParaTeste(f, null);
    expect(plano.map((e) => e.etapa), ['extra_1', 'bebida', 'sobremesa']);
    expect(plano.first.titulo, 'Leva um salgado?');
    expect(plano.first.plus, ['900']);
  });

  test('nova sugestão com categoria escolhida aparece', () {
    final f = filial({
      'extra_1': etapa(categorias: [33]),
      'extras': [
        {'chave': 'extra_1', 'nome': 'Salgados'},
      ],
    });
    final plano = planoSugestoesParaTeste(f, null);
    expect(plano.map((e) => e.etapa), ['bebida', 'sobremesa', 'extra_1']);
    expect(plano.last.categorias, [33]);
  });

  test('nova sugestão desligada ou removida não aparece', () {
    final desligada = filial({
      'extra_1': etapa(plus: ['900'], desativada: true),
      'extras': [
        {'chave': 'extra_1', 'nome': 'Salgados'},
      ],
    });
    expect(etapas(desligada), ['bebida', 'sobremesa']);
    // removida na Dashboard: some da lista "extras" (e da ordem)
    final removida = filial({
      'extra_1': etapa(plus: ['900']),
      'ordem': ['extra_1', 'sobremesa', 'bebida'],
    });
    expect(etapas(removida), ['sobremesa', 'bebida']);
  });

  test('nova sugestão vazia nos Matinais segue a geral', () {
    final f = filial({
      'extra_1': etapa(plus: ['900']),
      'extras': [
        {'chave': 'extra_1', 'nome': 'Salgados'},
      ],
      'porCategoria': {
        '7': {
          'extra_1': etapa(),
          'ordem': ['extra_1', 'bebida', 'sobremesa'],
        },
        '8': {'extra_1': etapa(desativada: true)},
      },
    });
    expect(etapas(f, 7), ['extra_1', 'bebida', 'sobremesa']);
    expect(planoSugestoesParaTeste(f, 7).first.plus, ['900']);
    expect(etapas(f, 8), ['bebida', 'sobremesa']);
  });

  test('ordem com chaves desconhecidas ou repetidas não quebra', () {
    final f = filial({
      'ordem': ['xyz', 'sobremesa', 'sobremesa', 42],
    });
    expect(etapas(f), ['sobremesa', 'bebida']);
  });

  test('Matinais ligada só lá (geral desligada) mostra bebidas pelo nome', () {
    final f = filial({
      'bebida': etapa(desativada: true),
      'porCategoria': {
        '7': {'bebida': etapa(ligada: true)},
      },
    });
    expect(etapas(f, 7), ['bebida', 'sobremesa']);
    expect(etapas(f, 8), ['sobremesa']);
  });
}
