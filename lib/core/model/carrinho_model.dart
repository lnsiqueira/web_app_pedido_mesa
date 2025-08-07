import 'package:flutter/material.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';

class CarrinhoModel extends ChangeNotifier {
  final List<ItemCarrinho> _itens = [];

  List<ItemCarrinho> get itens => _itens;

  void adicionar(ItemModel produto) {
    final index = _itens.indexWhere((item) => item.produto.plu == produto.plu);

    if (index >= 0) {
      _itens[index].quantidade++;
    } else {
      _itens.add(ItemCarrinho(produto: produto));
    }

    notifyListeners();
  }

  void remover(ItemModel produto) {
    _itens.removeWhere((item) => item.produto.plu == produto.plu);
    notifyListeners();
  }

  void limpar() {
    _itens.clear();
    notifyListeners();
  }

  int get totalItens =>
      _itens.fold(0, (total, item) => total + item.quantidade);

  double get totalGeral {
    return _itens.fold(
      0.0,
      (total, item) => total + (item.produto.preco! * item.quantidade),
    );
  }
}
