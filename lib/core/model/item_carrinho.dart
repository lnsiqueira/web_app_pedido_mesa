import 'package:webapp_pedido_mesa/core/model/item.dart';

class ItemCarrinho {
  final ItemModel produto;
  int quantidade;

  /// Unidades adicionadas pelo popup de sugestões (relatório da Dashboard).
  int qtdSugestao = 0;

  ItemCarrinho({required this.produto, this.quantidade = 1});
}
