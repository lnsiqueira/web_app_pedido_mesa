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
}
