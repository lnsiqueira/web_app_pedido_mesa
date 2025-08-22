import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';

class CarrinhoStorage {
  static const String keyCarrinho = 'carrinho';

  // Salvar carrinho no SharedPreferences
  static Future<void> salvarCarrinho(List<ItemCarrinho> itens) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        itens
            .map(
              (i) => {
                'produto': {
                  'desProduto': i.produto.desProduto,
                  'preco': i.produto.preco,
                },
                'quantidade': i.quantidade,
              },
            )
            .toList();
    prefs.setString(keyCarrinho, jsonEncode(jsonList));
  }

  // Recuperar carrinho do SharedPreferences
  static Future<List<ItemCarrinho>> recuperarCarrinho() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(keyCarrinho);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((jsonItem) {
      final produtoJson = jsonItem['produto'];
      return ItemCarrinho(
        produto: ItemModel(
          desProduto: produtoJson['desProduto'],
          preco: produtoJson['preco'],
        ),
        quantidade: jsonItem['quantidade'],
      );
    }).toList();
  }

  // Limpar carrinho do SharedPreferences
  static Future<void> limparCarrinho() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyCarrinho);
  }
}

// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:webapp_pedido_mesa/core/model/item.dart';
// import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';

// class CarrinhoStorage {
//   static const String keyCarrinho = 'carrinho';

//   // Salvar carrinho no SharedPreferences
//   static Future<void> salvarCarrinho(List<ItemCarrinho> itens) async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonList =
//         itens
//             .map(
//               (i) => {
//                 'produto': {
//                   'desProduto': i.produto.desProduto,
//                   'preco': i.produto.preco,
//                 },
//                 'quantidade': i.quantidade,
//               },
//             )
//             .toList();
//     prefs.setString(keyCarrinho, jsonEncode(jsonList));
//   }

//   // Recuperar carrinho do SharedPreferences
//   static Future<List<ItemCarrinho>> recuperarCarrinho() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = prefs.getString(keyCarrinho);
//     if (jsonString == null) return [];
//     final List<dynamic> jsonList = jsonDecode(jsonString);
//     return jsonList.map((jsonItem) {
//       final produtoJson = jsonItem['produto'];
//       return ItemCarrinho(
//         produto: ItemModel(
//           desProduto: produtoJson['desProduto'],
//           preco: produtoJson['preco'],
//         ),
//         quantidade: jsonItem['quantidade'],
//       );
//     }).toList();
//   }

//   // Limpar carrinho do SharedPreferences
//   static Future<void> limparCarrinho() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(keyCarrinho);
//   }
// }

// // Modelo de exemplo
// class ProdutoStorage {
//   final String desProduto;
//   final double preco;
//   ProdutoStorage({required this.desProduto, required this.preco});
// }
