// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
// import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';

// class BotaoPagamentoFlutuante extends StatelessWidget {
//   const BotaoPagamentoFlutuante({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       left: 16,
//       right: 16,
//       bottom: 18,
//       child: Consumer<CarrinhoModel>(
//         builder: (context, carrinho, _) {
//           if (carrinho.totalItens == 0) {
//             return const SizedBox.shrink();
//           }

//           return SafeArea(
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(22),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const CarrinhoPage(),
//                     ),
//                   );
//                 },
//                 child: Ink(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(22),
//                     gradient: LinearGradient(
//                       colors: [
//                         Colors.orange.shade600,
//                         Colors.orange.shade800,
//                       ],
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.orange.withOpacity(0.25),
//                         blurRadius: 18,
//                         offset: const Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 18,
//                       vertical: 16,
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 46,
//                           height: 46,
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.14),
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           child: const Icon(
//                             Icons.shopping_bag_rounded,
//                             color: Colors.white,
//                             size: 24,
//                           ),
//                         ),
//                         const SizedBox(width: 14),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const Text(
//                                 'Ver pedido',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               Text(
//                                 '${carrinho.totalItens} itens adicionados',
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.85),
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 14,
//                             vertical: 10,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.14),
//                             borderRadius: BorderRadius.circular(999),
//                           ),
//                           child: Row(
//                             children: const [
//                               Text(
//                                 'Abrir',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w700,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                               SizedBox(width: 6),
//                               Icon(
//                                 Icons.arrow_forward_ios_rounded,
//                                 color: Colors.white,
//                                 size: 12,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';

class BotaoPagamentoFlutuante extends StatelessWidget {
  const BotaoPagamentoFlutuante({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 18,
      child: Consumer<CarrinhoModel>(
        builder: (context, carrinho, _) {
          if (carrinho.totalItens == 0) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 18,
                  sigmaY: 18,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CarrinhoPage(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                          width: 1.2,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.orange.withOpacity(0.10),
                            Colors.black.withOpacity(0.10),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            // Ícone glass
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.20),
                                    Colors.white.withOpacity(0.06),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.shopping_bag_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Texto
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Ver pedido',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${carrinho.totalItens} '
                                    '${carrinho.totalItens == 1 ? 'item adicionado' : 'itens adicionados'}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.72),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Botão lateral glass
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.18),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Text(
                                    'Abrir',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
