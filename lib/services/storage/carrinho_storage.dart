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

  // // Recuperar carrinho do SharedPreferences
  // static Future<List<ItemCarrinho>> recuperarCarrinho() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final jsonString = prefs.getString(keyCarrinho);
  //   if (jsonString == null) return [];
  //   final List<dynamic> jsonList = jsonDecode(jsonString);
  //   return jsonList.map((jsonItem) {
  //     final produtoJson = jsonItem['produto'];
  //     final preco =
  //         (produtoJson['preco'] is String)
  //             ? double.tryParse(produtoJson['preco']) ?? 0.0
  //             : (produtoJson['preco'] ?? 0.0);

  //     return ItemCarrinho(
  //       produto: ItemModel(
  //         desProduto: produtoJson['desProduto'] ?? '',
  //         preco: preco,
  //       ),
  //       quantidade: jsonItem['quantidade'] ?? 0,
  //     );
  //   }).toList();
  // }

  static Future<List<ItemCarrinho>> recuperarCarrinho() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(keyCarrinho);

      if (jsonString == null || jsonString.isEmpty) {
        print('[DEBUG] Nenhum carrinho encontrado no SharedPreferences.');
        return [];
      }

      print('[DEBUG] JSON recuperado: $jsonString');

      final List<dynamic> jsonList = jsonDecode(jsonString);

      print('[DEBUG] Estrutura decodificada: $jsonList');

      return jsonList
          .map((jsonItem) {
            if (jsonItem is! Map<String, dynamic>) {
              print('[ERRO] Item inválido no JSON: $jsonItem');
              return null;
            }

            final produtoJson = jsonItem['produto'] as Map<String, dynamic>?;

            if (produtoJson == null) {
              print('[ERRO] Produto inválido no item: $jsonItem');
              return null;
            }

            final preco =
                (produtoJson['preco'] is String)
                    ? double.tryParse(produtoJson['preco']) ?? 0.0
                    : (produtoJson['preco'] ?? 0.0);

            return ItemCarrinho(
              produto: ItemModel(
                desProduto: produtoJson['desProduto'] ?? '',
                preco: preco,
              ),
              quantidade:
                  (jsonItem['quantidade'] is int)
                      ? jsonItem['quantidade']
                      : int.tryParse(jsonItem['quantidade'].toString()) ?? 0,
            );
          })
          .where((item) => item != null)
          .cast<ItemCarrinho>()
          .toList();
    } catch (e, stack) {
      print('[ERRO] Falha ao recuperar carrinho: $e');
      print(stack);
      return [];
    }
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
