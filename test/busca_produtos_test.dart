import 'package:flutter_test/flutter_test.dart';
import 'package:webapp_pedido_mesa/services/busca/busca_produtos.dart';

/// Nomes como costumam vir do cadastro
const cardapio = [
  'PAO FRANCES',
  'PAO NA CHAPA C/ MANT',
  'PAO DE QUEIJO',
  'PAO DE QUEIJO RECHEADO',
  'MISTO QUENTE',
  'CAFE EXPRESSO',
  'CAFE C/ LEITE GDE',
  'CAPPUCCINO',
  'SUCO DE LARANJA',
  'REFRI LATA COCA COLA',
  'AGUA S/ GAS 500ML',
  'BOLO DE CHOCOLATE',
  'TAPIOCA DE QUEIJO',
  'MISTO QUENTE QUEIJO E PRESUNTO',
  'PRESUNTO FATIADO',
];

List<String> busca(String q) => buscarProdutos(q, cardapio, (String s) => s);

void main() {
  test('normalizar tira acento e deixa minúsculo', () {
    expect(normalizar('Pão Francês'), 'pao frances');
  });

  test('frase do cliente com erro de digitação', () {
    expect(busca('quero um pao com menteiga').first, 'PAO NA CHAPA C/ MANT');
    expect(busca('Quero um pão com manteiga, por favor').first,
        'PAO NA CHAPA C/ MANT');
  });

  test('digitando pela metade continua funcionando', () {
    expect(busca('pao de quei').take(2),
        ['PAO DE QUEIJO', 'PAO DE QUEIJO RECHEADO']);
    expect(busca('capu').first, 'CAPPUCCINO');
  });

  test('erro de digitação', () {
    expect(busca('pao de qeijo').first, 'PAO DE QUEIJO');
    expect(busca('capucino').first, 'CAPPUCCINO');
    expect(busca('chocolatte').first, 'BOLO DE CHOCOLATE');
  });

  test('sinônimos e abreviações do cadastro', () {
    expect(busca('refrigerante').first, 'REFRI LATA COCA COLA');
    expect(busca('cafe com leite grande').first, 'CAFE C/ LEITE GDE');
    expect(busca('agua sem gas').first, 'AGUA S/ GAS 500ML');
  });

  test('quantidade na frase não atrapalha', () {
    expect(busca('2 cafe com leite').first, 'CAFE C/ LEITE GDE');
  });

  test('achou o exato: não enche a lista com outros pães', () {
    final r = busca('pao de queijo');
    expect(r, isNot(contains('PAO FRANCES')));
    expect(r.first, 'PAO DE QUEIJO');
  });

  test('não achou nada', () {
    expect(busca('picanha'), isEmpty);
    expect(busca('   '), isEmpty);
  });

  group('pedido falado', () {
    List<(int, String?)> pedido(String f) => [
          for (final l in interpretarPedido(f, cardapio, (String s) => s))
            (l.quantidade, l.opcoes.firstOrNull),
        ];

    test('vários itens com quantidade', () {
      expect(pedido('quero um pão com manteiga e dois cafés com leite'), [
        (1, 'PAO NA CHAPA C/ MANT'),
        (2, 'CAFE C/ LEITE GDE'),
      ]);
    });

    test('vírgula, número e plural', () {
      expect(pedido('3 pães de queijo, um suco de laranja mais 2 expressos'), [
        (3, 'PAO DE QUEIJO'),
        (1, 'SUCO DE LARANJA'),
        (2, 'CAFE EXPRESSO'),
      ]);
    });

    test('"e" dentro do nome do produto não separa', () {
      expect(pedido('um misto de queijo e presunto'),
          [(1, 'MISTO QUENTE QUEIJO E PRESUNTO')]);
    });

    test('item que não existe fica sem opção', () {
      expect(pedido('uma picanha e um cappuccino'), [
        (1, null),
        (1, 'CAPPUCCINO'),
      ]);
    });

    test('só palavras vazias não viram item', () {
      expect(pedido('oi, bom dia'), isEmpty);
    });
  });

  group('item genérico: cliente escolhe', () {
    LinhaPedido<String> linha(String f) =>
        interpretarPedido(f, cardapio, (String s) => s).single;

    test('"um café" tem vários cafés: pergunta qual', () {
      final l = linha('um café');
      expect(l.ambigua, isTrue);
      expect(l.opcoes, containsAll(['CAFE EXPRESSO', 'CAFE C/ LEITE GDE']));
    });

    test('pedido específico não pergunta', () {
      expect(linha('um café com leite').ambigua, isFalse);
      expect(linha('um expresso').ambigua, isFalse);
      expect(linha('pão de queijo').ambigua, isFalse);
      expect(linha('pão com manteiga').ambigua, isFalse);
    });
  });
}
