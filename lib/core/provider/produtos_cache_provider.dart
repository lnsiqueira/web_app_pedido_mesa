import 'package:flutter/foundation.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';

class ProdutosCacheProvider extends ChangeNotifier {
  final Map<int, List<ItemModel>> _cachePorCategoria = {};

  bool contemCategoria(int idCategoria) {
    return _cachePorCategoria.containsKey(idCategoria);
  }

  List<ItemModel> obterProdutos(int idCategoria) {
    return _cachePorCategoria[idCategoria] ?? [];
  }

  void atualizarProdutos(int idCategoria, List<ItemModel> produtos) {
    _cachePorCategoria[idCategoria] = produtos;
    notifyListeners();
  }

  void limparCache() {
    _cachePorCategoria.clear();
    notifyListeners();
  }
}
