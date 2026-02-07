import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';

// class BottomCarrinhoBar extends StatelessWidget {
//   const BottomCarrinhoBar({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<CarrinhoModel>(
//       builder: (context, carrinho, _) {
//         if (carrinho.totalItens == 0) {
//           return const SizedBox.shrink();
//         }

//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           decoration: BoxDecoration(
//             color: Colors.black,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.25),
//                 blurRadius: 8,
//                 offset: const Offset(0, -2),
//               ),
//             ],
//           ),
//           child: SafeArea(
//             top: false,
//             child: Row(
//               children: [
//                 // Ícone + badge
//                 Stack(
//                   children: [
//                     const Icon(
//                       Icons.shopping_cart,
//                       color: Colors.white,
//                       size: 26,
//                     ),
//                     Positioned(
//                       right: -6,
//                       top: -6,
//                       child: Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Text(
//                           carrinho.totalItens.toString(),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(width: 12),

//                 // Texto
//                 Expanded(
//                   child: Text(
//                     '${carrinho.totalItens} itens no carrinho',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),

//                 // Botão
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const CarrinhoPage(),
//                       ),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     foregroundColor: Colors.black,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 12,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: const Text(
//                     'Ver carrinho',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
class BottomCarrinhoBar extends StatelessWidget {
  const BottomCarrinhoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarrinhoModel>(
      builder: (context, carrinho, _) {
        if (carrinho.totalItens == 0) {
          return const SizedBox.shrink();
        }
        final textoItens = carrinho.totalItens == 1
            ? '1 item no carrinho'
            : '${carrinho.totalItens} itens no carrinho';

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CarrinhoPage(),
                  ),
                );
              },
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black
                          .withOpacity(0.55), // bem mais claro no início
                      Colors.black.withOpacity(0.65), // meio ainda claro
                      Colors.black
                          .withOpacity(0.85), // escurece só perto do CTA
                    ],
                    stops: const [
                      0.0,
                      0.6,
                      1.0,
                    ],
                  ),
                  // gradient: LinearGradient(
                  //   begin: Alignment.centerRight,
                  //   end: Alignment.centerLeft,
                  //   colors: [
                  //     Colors.black.withOpacity(0.5),
                  //     Colors.black.withOpacity(0.62),
                  //     Colors.black.withOpacity(0.8),
                  //   ],
                  //   stops: const [
                  //     0.0,
                  //     0.6,
                  //     1.0,
                  //   ],
                  // ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Ícone com badge mais clean
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              carrinho.totalItens.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Texto
                    Expanded(
                      child: Text(
                        textoItens,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // CTA sutil (sem parecer botão pesado)
                    Row(
                      children: const [
                        Text(
                          'Ver',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.orange,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
