import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';

void main() {
  // dois acréscimos diferentes com o mesmo PLU (Dashboard), como no
  // Cappuccino médio
  const aveia = AcrescimoEscolhido(
      id: 31, plu: '221', nome: 'Leite de aveia', preco: 6.7);
  const zero = AcrescimoEscolhido(
      id: 32, plu: '221', nome: 'Leite zero lactose', preco: 6.7);

  test('acréscimos com o mesmo PLU são diferentes pelo id', () {
    expect(aveia.chave, isNot(zero.chave));
    // sem id continua como antes
    const semId = AcrescimoEscolhido(plu: '221', nome: 'x', preco: 1);
    expect(semId.chave, '221');
  });

  test('total conta cada acréscimo marcado uma vez', () {
    final p = ItemModel(plu: '100', desProduto: 'CAPPUCCINO MEDIO', preco: 10)
        .copyWith(acrescimos: [aveia, zero]);
    expect(p.precoComAcrescimos, closeTo(23.4, 0.001));
  });

  test('no carrinho, cada acréscimo vira uma linha diferente', () {
    SharedPreferences.setMockInitialValues({});
    final carrinho = CarrinhoModel();
    final base =
        ItemModel(plu: '100', desProduto: 'CAPPUCCINO MEDIO', preco: 10);
    carrinho.adicionar(base.copyWith(acrescimos: [aveia]));
    carrinho.adicionar(base.copyWith(acrescimos: [zero]));
    carrinho.adicionar(base.copyWith(acrescimos: [aveia]));
    expect(carrinho.itens.length, 2);
    expect(carrinho.itens.first.quantidade, 2);
  });
}
