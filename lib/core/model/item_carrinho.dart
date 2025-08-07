import 'package:webapp_pedido_mesa/core/model/item.dart';

class ItemCarrinho {
  final ItemModel produto;
  int quantidade;

  ItemCarrinho({required this.produto, this.quantidade = 1});
}
