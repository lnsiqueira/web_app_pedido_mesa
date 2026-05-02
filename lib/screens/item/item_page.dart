import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/provider/produtos_cache_provider.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';
import 'package:webapp_pedido_mesa/widgets/botao_pagamento_flutuante.dart';
import 'package:webapp_pedido_mesa/widgets/logo_pulsando.dart';

class ItensPage extends StatefulWidget {
  final int idCategoria;
  final String nomeCategoria;

  const ItensPage(
      {super.key, required this.idCategoria, required this.nomeCategoria});

  @override
  State<ItensPage> createState() => _ItensPageState();
}

class _ItensPageState extends State<ItensPage> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos({bool forceRefresh = false}) async {
    final produtosProvider = Provider.of<ProdutosCacheProvider>(
      context,
      listen: false,
    );

    if (produtosProvider.contemCategoria(widget.idCategoria) && !forceRefresh) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url =
        '${Urls.urlApiAzure}/Categorias/categoria-produto-by-filial/${widget.idCategoria}?idFilial=${GlobalKeys.codFilial}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<ItemModel> lista = List<ItemModel>.from(
          data.map((json) => ItemModel.fromJson(json)),
        );

        // PRIMEIRO mostra os produtos SEM preço
        produtosProvider.atualizarProdutos(
          widget.idCategoria,
          lista,
        );
        setState(() {
          isLoading = false;
        });

        // Processa de 10 em 10
        const int lote = 10;

        for (int i = 0; i < lista.length; i += lote) {
          final fim = (i + lote < lista.length) ? i + lote : lista.length;

          final subLista = lista.sublist(i, fim);

          final atualizados = await Future.wait(
            subLista.map((p) async {
              try {
                final info = await _buscarPrecoProduto(p.plu!);

                return p.copyWith(
                  preco: info.preco,
                  obs: info.obs,
                );
              } catch (e) {
                print('Erro produto ${p.plu}: $e');
                return p;
              }
            }),
          );

          // Atualiza apenas os itens do lote
          for (final itemAtualizado in atualizados) {
            final index = lista.indexWhere(
              (x) => x.plu == itemAtualizado.plu,
            );

            if (index != -1) {
              lista[index] = itemAtualizado;
            }
          }

          // Atualiza provider a cada lote
          produtosProvider.atualizarProdutos(
            widget.idCategoria,
            List<ItemModel>.from(lista),
          );
        }
      }
    } catch (e) {
      print('Erro: $e');
    } finally {
      // setState(() {
      //   isLoading = false;
      // });
    }
  }
  // Future<void> _carregarProdutos({bool forceRefresh = false}) async {
  //   final produtosProvider = Provider.of<ProdutosCacheProvider>(
  //     context,
  //     listen: false,
  //   );

  //   // Se já existe cache e não for atualização forçada, usa ele
  //   if (produtosProvider.contemCategoria(widget.idCategoria) && !forceRefresh) {
  //     return;
  //   }

  //   setState(() {
  //     isLoading = true;
  //   });

  //   final url =
  //       '${Urls.urlApiAzure}/Categorias/categoria-produto-by-filial/${widget.idCategoria}?idFilial=${GlobalKeys.codFilial}';

  //   try {
  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);

  //       List<ItemModel> lista = List<ItemModel>.from(
  //         data.map((json) => ItemModel.fromJson(json)),
  //       );

  //       final listaComPrecoEObs = await Future.wait(
  //         lista.map((p) async {
  //           try {
  //             final info = await _buscarPrecoProduto(p.plu!);
  //             return p.copyWith(
  //               preco: info.preco,
  //               obs: info.obs,
  //             );
  //           } catch (e) {
  //             print('Erro ao processar produto ${p.plu}: $e');
  //             return p;
  //           }
  //         }),
  //       );

  //       // Atualiza no provider
  //       produtosProvider.atualizarProdutos(
  //           widget.idCategoria, listaComPrecoEObs);
  //     } else {
  //       print('Erro ao carregar produtos: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Erro: $e');
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<ProdutoInfo> _buscarPrecoProduto(String plu) async {
    try {
      var urlBratter = Urls.urlApiBratter;
      final encodedUrl = Uri.encodeComponent(urlBratter);

      final url =
          '${Urls.urlApiAzure}Proxy/mercadoriafiscal?codigoproduto=$plu&imagens=false&urlBratter=$encodedUrl&tokenBratter=${GlobalKeys.tokenBratter}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        double? preco = double.tryParse(data['preco'].toString());

        List<ItemObsModel> obs = (data['obs'] as List?)
                ?.map((o) => ItemObsModel.fromJson(o))
                .toList() ??
            [];

        return ProdutoInfo(preco: preco, obs: obs);
      } else {
        print(
            'Erro ao buscar preço/obs do produto $plu: ${response.statusCode}');
        return ProdutoInfo();
      }
    } catch (e) {
      print('Erro ao buscar preço/obs: $e');
      return ProdutoInfo();
    }
  }

  void _mostrarPopupObs(ItemModel produto) {
    final obs = List<ItemObsModel>.from(produto.obs ?? []);
    final textControllers = {
      for (int i = 0; i < obs.length; i++)
        if (obs[i].tipo == 'texto') i: TextEditingController()
    };
    int quantidade = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final total = (produto.preco ?? 0) * quantidade;

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                // return Container(
                //   decoration: const BoxDecoration(
                //     color: Colors.white,
                //     borderRadius:
                //         BorderRadius.vertical(top: Radius.circular(24)),
                //   ),
                //   child: Column(
                //     children: [
                //       // Drag handle
                //       Container(
                //         margin: const EdgeInsets.only(top: 12, bottom: 8),
                //         width: 36,
                //         height: 4,
                //         decoration: BoxDecoration(
                //           color: Colors.grey.shade300,
                //           borderRadius: BorderRadius.circular(99),
                //         ),
                //       ),

                //       // Header
                //       Padding(
                //         padding: const EdgeInsets.symmetric(
                //             horizontal: 20, vertical: 12),
                //         child: Row(
                //           children: [
                //             Container(
                //               width: 48,
                //               height: 48,
                //               decoration: BoxDecoration(
                //                 color: Colors.orange.shade50,
                //                 borderRadius: BorderRadius.circular(14),
                //               ),
                //               child: Icon(Icons.fastfood_rounded,
                //                   color: Colors.orange.shade700, size: 24),
                //             ),
                //             const SizedBox(width: 14),
                //             Expanded(
                //               child: Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   Text(
                //                     produto.desProduto ?? '',
                //                     style: const TextStyle(
                //                         fontSize: 16,
                //                         fontWeight: FontWeight.w600),
                //                     maxLines: 1,
                //                     overflow: TextOverflow.ellipsis,
                //                   ),
                //                   Text(
                //                     'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                //                     style: TextStyle(
                //                       fontSize: 14,
                //                       color: Colors.orange.shade800,
                //                       fontWeight: FontWeight.w500,
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //       Divider(height: 1, color: Colors.grey.shade200),

                //       // Scrollable content
                //       Expanded(
                //         child: ListView(
                //           controller: scrollController,
                //           padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                //           children: [
                //             // Quantidade
                //             const Text('Quantidade',
                //                 style: TextStyle(
                //                     fontSize: 11,
                //                     fontWeight: FontWeight.w600,
                //                     letterSpacing: 0.8,
                //                     color: Colors.grey)),
                //             const SizedBox(height: 12),
                //             Row(
                //               children: [
                //                 _QtyButton(
                //                   icon: Icons.remove,
                //                   onTap: () => setStateSB(() {
                //                     if (quantidade > 1) quantidade--;
                //                   }),
                //                 ),
                //                 SizedBox(
                //                   width: 40,
                //                   child: Text(
                //                     '$quantidade',
                //                     textAlign: TextAlign.center,
                //                     style: const TextStyle(
                //                         fontSize: 16,
                //                         fontWeight: FontWeight.w600),
                //                   ),
                //                 ),
                //                 _QtyButton(
                //                   icon: Icons.add,
                //                   onTap: () => setStateSB(() => quantidade++),
                //                 ),
                //               ],
                //             ),

                //             // Obs de escolha (chips "com")
                //             if (obs.any((o) => o.tipo == 'escolha')) ...[
                //               const SizedBox(height: 24),
                //               const Text('Personalize seu pedido',
                //                   style: TextStyle(
                //                       fontSize: 11,
                //                       fontWeight: FontWeight.w600,
                //                       letterSpacing: 0.8,
                //                       color: Colors.grey)),
                //               const SizedBox(height: 12),
                //               Wrap(
                //                 spacing: 8,
                //                 runSpacing: 8,
                //                 children: obs.mapIndexed((i, o) {
                //                   if (o.tipo != 'escolha')
                //                     return const SizedBox.shrink();
                //                   final selected = o.modificador == 'C';
                //                   return GestureDetector(
                //                     onTap: () => setStateSB(() {
                //                       obs[i] = o.copyWith(
                //                         modificador: selected ? null : 'C',
                //                         clearModificador: selected,
                //                       );
                //                     }),
                //                     child: AnimatedContainer(
                //                       duration:
                //                           const Duration(milliseconds: 150),
                //                       padding: const EdgeInsets.symmetric(
                //                           horizontal: 14, vertical: 9),
                //                       decoration: BoxDecoration(
                //                         color: selected
                //                             ? Colors.orange.shade50
                //                             : Colors.white,
                //                         border: Border.all(
                //                           color: selected
                //                               ? Colors.orange.shade700
                //                               : Colors.grey.shade300,
                //                           width: selected ? 1.5 : 0.8,
                //                         ),
                //                         borderRadius: BorderRadius.circular(99),
                //                       ),
                //                       child: Row(
                //                         mainAxisSize: MainAxisSize.min,
                //                         children: [
                //                           if (selected) ...[
                //                             Container(
                //                               width: 16,
                //                               height: 16,
                //                               decoration: BoxDecoration(
                //                                 color: Colors.orange.shade700,
                //                                 shape: BoxShape.circle,
                //                               ),
                //                               child: const Icon(Icons.check,
                //                                   size: 11,
                //                                   color: Colors.white),
                //                             ),
                //                             const SizedBox(width: 6),
                //                           ],
                //                           Text(
                //                             o.titulo ?? '',
                //                             style: TextStyle(
                //                               fontSize: 14,
                //                               fontWeight: FontWeight.w500,
                //                               color: selected
                //                                   ? Colors.orange.shade800
                //                                   : Colors.black87,
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //                     ),
                //                   );
                //                 }).toList(),
                //               ),
                //             ],

                //             // Campo de texto livre
                //             const SizedBox(height: 24),
                //             Container(
                //               decoration: BoxDecoration(
                //                 border: Border.all(
                //                     color: Colors.grey.shade300, width: 0.8),
                //                 borderRadius: BorderRadius.circular(14),
                //               ),
                //               padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                //               child: Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   Text('Alguma observação?',
                //                       style: TextStyle(
                //                           fontSize: 12,
                //                           color: Colors.grey.shade500)),
                //                   const SizedBox(height: 4),
                //                   ...obs.mapIndexed((i, o) {
                //                     if (o.tipo != 'texto')
                //                       return const SizedBox.shrink();
                //                     return TextField(
                //                       controller: textControllers[i],
                //                       maxLines: 3,
                //                       minLines: 1,
                //                       decoration: const InputDecoration(
                //                         hintText:
                //                             'Ex: sem cebola, bem passado…',
                //                         border: InputBorder.none,
                //                         isDense: true,
                //                       ),
                //                       style: const TextStyle(fontSize: 14),
                //                     );
                //                   }),
                //                 ],
                //               ),
                //             ),
                //             const SizedBox(height: 24),
                //           ],
                //         ),
                //       ),

                //       // Footer
                //       Padding(
                //         padding: EdgeInsets.fromLTRB(20, 12, 20,
                //             MediaQuery.of(context).padding.bottom + 16),
                //         child: Row(
                //           children: [
                //             // Botão cancelar
                //             Expanded(
                //               flex: 1,
                //               child: OutlinedButton(
                //                 onPressed: () => Navigator.pop(context),
                //                 style: OutlinedButton.styleFrom(
                //                   minimumSize: const Size(0, 50),
                //                   side: BorderSide(
                //                       color: Colors.grey.shade300, width: 0.8),
                //                   shape: RoundedRectangleBorder(
                //                       borderRadius: BorderRadius.circular(12)),
                //                 ),
                //                 child: const Text('Cancelar',
                //                     style: TextStyle(
                //                         color: Colors.black54, fontSize: 15)),
                //               ),
                //             ),
                //             const SizedBox(width: 10),
                //             // Botão adicionar
                //             Expanded(
                //               flex: 2,
                //               child: ElevatedButton(
                //                 onPressed: () {
                //                   final List<ItemObsModel> obsFinalizadas = [];
                //                   for (int i = 0; i < obs.length; i++) {
                //                     final o = obs[i];
                //                     if (o.tipo == 'texto') {
                //                       final txt =
                //                           textControllers[i]?.text.trim();
                //                       if (txt != null && txt.isNotEmpty) {
                //                         obsFinalizadas.add(o.copyWith(
                //                             modificador: 'COM',
                //                             pluAdd: 0,
                //                             titulo: txt));
                //                       }
                //                     } else if (o.tipo == 'escolha' &&
                //                         o.modificador == 'C') {
                //                       obsFinalizadas.add(o.copyWith(pluAdd: 0));
                //                     }
                //                   }
                //                   for (int i = 0; i < quantidade; i++) {
                //                     _adicionarAoCarrinho(
                //                         produto.copyWith(obs: obsFinalizadas));
                //                   }
                //                   Navigator.pop(context);
                //                 },
                //                 style: ElevatedButton.styleFrom(
                //                   backgroundColor: Colors.orange.shade800,
                //                   foregroundColor: Colors.white,
                //                   minimumSize: const Size(0, 50),
                //                   elevation: 0,
                //                   shape: RoundedRectangleBorder(
                //                       borderRadius: BorderRadius.circular(12)),
                //                 ),
                //                 child: Row(
                //                   mainAxisAlignment: MainAxisAlignment.center,
                //                   children: [
                //                     const Icon(
                //                       Icons.add,
                //                       size: 18,
                //                       color: Colors.white,
                //                     ),
                //                     const SizedBox(width: 6),
                //                     Text(
                //                       'Adicionar · R\$ ${total.toStringAsFixed(2)}',
                //                       style: const TextStyle(
                //                           fontSize: 15,
                //                           fontWeight: FontWeight.w600),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // );
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // HEADER COM IMAGEM
                      Stack(
                        children: [
                          // IMAGEM
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: Image.network(
                                produto.imageUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: Colors.orange.shade100,
                                    child: Icon(
                                      Icons.fastfood_rounded,
                                      size: 72,
                                      color: Colors.orange.shade300,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // OVERLAY ESCURO
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.08),
                                    Colors.black.withOpacity(0.20),
                                    Colors.black.withOpacity(0.85),
                                  ],
                                  stops: const [0.0, 0.45, 1],
                                ),
                              ),
                            ),
                          ),

                          // DRAG HANDLE
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 42,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),

                          // BOTÃO FECHAR
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Material(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => Navigator.pop(context),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // TEXOS
                          // Positioned(
                          //   left: 20,
                          //   right: 20,
                          //   bottom: 22,
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Text(
                          //         produto.desProduto ?? '',
                          //         maxLines: 2,
                          //         overflow: TextOverflow.ellipsis,
                          //         style: const TextStyle(
                          //           color: Colors.white,
                          //           fontSize: 28,
                          //           fontWeight: FontWeight.w800,
                          //           height: 1.05,
                          //           letterSpacing: -0.7,
                          //         ),
                          //       ),
                          //       const SizedBox(height: 12),
                          //       Container(
                          //         padding: const EdgeInsets.symmetric(
                          //           horizontal: 14,
                          //           vertical: 8,
                          //         ),
                          //         decoration: BoxDecoration(
                          //           color: Colors.white.withOpacity(0.14),
                          //           borderRadius: BorderRadius.circular(99),
                          //           border: Border.all(
                          //             color: Colors.white.withOpacity(0.12),
                          //           ),
                          //         ),
                          //         child: Text(
                          //           'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                          //           style: const TextStyle(
                          //             color: Colors.white,
                          //             fontSize: 16,
                          //             fontWeight: FontWeight.w700,
                          //           ),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          // TEXOS
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 22,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produto.desProduto ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.05,
                                    letterSpacing: -0.7,
                                  ),
                                ),

                                // DESCRIÇÃO BONITA
                                if ((produto.descricaoProduto ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    produto.descricaoProduto!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.82),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                ],

                                // PREÇO SÓ QUANDO NÃO TIVER DESCRIÇÃO
                                if ((produto.descricaoProduto ?? '')
                                    .trim()
                                    .isEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Text(
                                      'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      // CONTEÚDO
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          children: [
                            // QUANTIDADE
                            const Text(
                              'Quantidade',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Row(
                            //   children: [
                            //     _QtyButton(
                            //       icon: Icons.remove,
                            //       onTap: () => setStateSB(() {
                            //         if (quantidade > 1) quantidade--;
                            //       }),
                            //     ),
                            //     SizedBox(
                            //       width: 50,
                            //       child: Text(
                            //         '$quantidade',
                            //         textAlign: TextAlign.center,
                            //         style: const TextStyle(
                            //           fontSize: 18,
                            //           fontWeight: FontWeight.w700,
                            //         ),
                            //       ),
                            //     ),
                            //     _QtyButton(
                            //       icon: Icons.add,
                            //       onTap: () => setStateSB(() => quantidade++),
                            //     ),
                            //   ],
                            // ),
                            Row(
                              children: [
                                _QtyButton(
                                  icon: Icons.remove,
                                  onTap: () => setStateSB(() {
                                    if (quantidade > 1) quantidade--;
                                  }),
                                ),

                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    '$quantidade',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                                _QtyButton(
                                  icon: Icons.add,
                                  onTap: () => setStateSB(() => quantidade++),
                                ),

                                // PREÇO NO FIM DA LINHA QUANDO EXISTIR DESCRIÇÃO
                                if ((produto.descricaoProduto ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.orange.shade100,
                                      ),
                                    ),
                                    child: Text(
                                      'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // PERSONALIZAÇÃO
                            if (obs.any((o) => o.tipo == 'escolha')) ...[
                              const SizedBox(height: 30),
                              const Text(
                                'PERSONALIZE SEU PEDIDO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: obs.mapIndexed((i, o) {
                                  if (o.tipo != 'escolha') {
                                    return const SizedBox.shrink();
                                  }

                                  final selected = o.modificador == 'C';

                                  return GestureDetector(
                                    onTap: () => setStateSB(() {
                                      obs[i] = o.copyWith(
                                        modificador: selected ? null : 'C',
                                        clearModificador: selected,
                                      );
                                    }),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.orange.shade50
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: selected
                                              ? Colors.orange.shade700
                                              : Colors.grey.shade300,
                                          width: selected ? 1.5 : 1,
                                        ),
                                        boxShadow: [
                                          if (selected)
                                            BoxShadow(
                                              color: Colors.orange
                                                  .withOpacity(0.12),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (selected) ...[
                                            // Container(
                                            //   width: 18,
                                            //   height: 18,
                                            //   decoration: BoxDecoration(
                                            //     color: Colors.orange.shade700,
                                            //     shape: BoxShape.circle,
                                            //   ),
                                            //   child: const Icon(
                                            //     Icons.check,
                                            //     size: 12,
                                            //     color: Colors.white,
                                            //   ),
                                            // ),
                                            // const SizedBox(width: 8),
                                          ],
                                          Text(
                                            o.titulo ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: selected
                                                  ? Colors.orange.shade800
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],

                            // OBSERVAÇÃO
                            const SizedBox(height: 30),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alguma observação?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...obs.mapIndexed((i, o) {
                                    if (o.tipo != 'texto') {
                                      return const SizedBox.shrink();
                                    }

                                    return TextField(
                                      controller: textControllers[i],
                                      maxLines: 3,
                                      minLines: 1,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Ex: sem cebola, bem passado…',
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // FOOTER
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          12,
                          20,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        child: Row(
                          children: [
                            // CANCELAR
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 54),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // ADICIONAR
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  final List<ItemObsModel> obsFinalizadas = [];

                                  for (int i = 0; i < obs.length; i++) {
                                    final o = obs[i];

                                    if (o.tipo == 'texto') {
                                      final txt =
                                          textControllers[i]?.text.trim();

                                      if (txt != null && txt.isNotEmpty) {
                                        obsFinalizadas.add(
                                          o.copyWith(
                                            modificador: 'COM',
                                            pluAdd: 0,
                                            titulo: txt,
                                          ),
                                        );
                                      }
                                    } else if (o.tipo == 'escolha' &&
                                        o.modificador == 'C') {
                                      obsFinalizadas.add(
                                        o.copyWith(pluAdd: 0),
                                      );
                                    }
                                  }

                                  for (int i = 0; i < quantidade; i++) {
                                    _adicionarAoCarrinho(
                                      produto.copyWith(obs: obsFinalizadas),
                                    );
                                  }

                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 54),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // const Icon(
                                    //   Icons.add_rounded,
                                    //   size: 18,
                                    //   color: Colors.white,
                                    // ),
                                    // const SizedBox(width: 8),
                                    Text(
                                      'Adicionar · R\$ ${total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'images/sad.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum produto encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tente novamente mais tarde.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarAoCarrinho(ItemModel produto) {
    Provider.of<CarrinhoModel>(context, listen: false).adicionar(produto);
  }

  @override
  Widget build(BuildContext context) {
    final produtosProvider = Provider.of<ProdutosCacheProvider>(context);
    final produtos = produtosProvider.obterProdutos(widget.idCategoria);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.nomeCategoria,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: () {
          //     _carregarProdutos(forceRefresh: true);
          //   },
          // ),
          Consumer<CarrinhoModel>(
            builder: (context, carrinho, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CarrinhoPage(),
                      ),
                    );
                  },
                ),
                if (carrinho.totalItens > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        carrinho.totalItens.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // body: Stack(
      //   children: [
      //     // CONTEÚDO PRINCIPAL
      //     Positioned.fill(
      //       child: isLoading
      //           ? const Center(
      //               child: PulsingLogo(
      //                 assetPath: 'images/logodd_clean.png',
      //                 width: 150,
      //                 duration: Duration(seconds: 1),
      //               ),
      //             )
      //           : produtos.isEmpty
      //               ? Center(
      //                   child: Padding(
      //                     padding: const EdgeInsets.all(32),
      //                     child: Column(
      //                       mainAxisAlignment: MainAxisAlignment.center,
      //                       children: [
      //                         Container(
      //                           padding: const EdgeInsets.all(22),
      //                           decoration: BoxDecoration(
      //                             color: Colors.orangeAccent.withOpacity(0.08),
      //                             shape: BoxShape.circle,
      //                           ),
      //                           child: Image.asset(
      //                             'images/sad.png',
      //                             width: 120,
      //                             height: 120,
      //                             fit: BoxFit.contain,
      //                           ),
      //                         ),
      //                         const SizedBox(height: 24),
      //                         const Text(
      //                           'Nenhum produto encontrado',
      //                           textAlign: TextAlign.center,
      //                           style: TextStyle(
      //                             fontSize: 20,
      //                             fontWeight: FontWeight.w600,
      //                             color: Colors.black87,
      //                           ),
      //                         ),
      //                         const SizedBox(height: 12),
      //                         const Text(
      //                           'Tente novamente mais tarde.',
      //                           textAlign: TextAlign.center,
      //                           style: TextStyle(
      //                             fontSize: 15,
      //                             color: Colors.black54,
      //                             height: 1.4,
      //                           ),
      //                         ),
      //                       ],
      //                     ),
      //                   ),
      //                 )
      //               : GridView.builder(
      //                   padding: const EdgeInsets.fromLTRB(
      //                     16,
      //                     16,
      //                     16,
      //                     120, // espaço pro botão flutuante
      //                   ),
      //                   gridDelegate:
      //                       const SliverGridDelegateWithFixedCrossAxisCount(
      //                     crossAxisCount: 2,
      //                     mainAxisSpacing: 16,
      //                     crossAxisSpacing: 16,
      //                     childAspectRatio: 0.96,
      //                   ),
      //                   itemCount: produtos.length,
      //                   itemBuilder: (context, index) {
      //                     final produto = produtos[index];

      //                     return GestureDetector(
      //                       onTap: () => _mostrarPopupObs(produto),
      //                       child: ClipRRect(
      //                         borderRadius: BorderRadius.circular(18),
      //                         child: Stack(
      //                           children: [
      //                             Positioned.fill(
      //                               child: produto.imageUrl != null &&
      //                                       produto.imageUrl!.isNotEmpty
      //                                   ? Image.network(
      //                                       produto.imageUrl!,
      //                                       fit: BoxFit.cover,
      //                                     )
      //                                   : Image.asset(
      //                                       'images/default.png',
      //                                       fit: BoxFit.cover,
      //                                     ),
      //                             ),
      //                             Positioned.fill(
      //                               child: Container(
      //                                 decoration: BoxDecoration(
      //                                   gradient: LinearGradient(
      //                                     begin: Alignment.bottomCenter,
      //                                     end: Alignment.topCenter,
      //                                     colors: [
      //                                       Colors.black.withOpacity(0.60),
      //                                       Colors.black.withOpacity(0.15),
      //                                       Colors.transparent,
      //                                     ],
      //                                   ),
      //                                 ),
      //                               ),
      //                             ),
      //                             Padding(
      //                               padding: const EdgeInsets.all(14),
      //                               child: Column(
      //                                 crossAxisAlignment:
      //                                     CrossAxisAlignment.start,
      //                                 children: [
      //                                   const Spacer(),
      //                                   Text(
      //                                     produto.desProduto ?? '',
      //                                     maxLines: 2,
      //                                     overflow: TextOverflow.ellipsis,
      //                                     style: const TextStyle(
      //                                       color: Colors.white,
      //                                       fontSize: 16,
      //                                       fontWeight: FontWeight.w700,
      //                                     ),
      //                                   ),
      //                                   const SizedBox(height: 6),
      //                                   Text(
      //                                     'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
      //                                     style: TextStyle(
      //                                       color: Colors.orange.shade200,
      //                                       fontSize: 16,
      //                                       fontWeight: FontWeight.w700,
      //                                     ),
      //                                   ),
      //                                 ],
      //                               ),
      //                             ),
      //                           ],
      //                         ),
      //                       ),
      //                     );
      //                   },
      //                 ),
      //     ),

      //     // BOTÃO FLUTUANTE
      //     // Consumer<CarrinhoModel>(
      //     //   builder: (context, carrinho, _) {
      //     //     if (carrinho.totalItens == 0) {
      //     //       return const SizedBox.shrink();
      //     //     }

      //     //     return Positioned(
      //     //       left: 16,
      //     //       right: 16,
      //     //       bottom: 18,
      //     //       child: SafeArea(
      //     //         child: Material(
      //     //           color: Colors.transparent,
      //     //           child: InkWell(
      //     //             borderRadius: BorderRadius.circular(22),
      //     //             onTap: () {
      //     //               Navigator.push(
      //     //                 context,
      //     //                 MaterialPageRoute(
      //     //                   builder: (_) => const CarrinhoPage(),
      //     //                 ),
      //     //               );
      //     //             },
      //     //             child: Ink(
      //     //               decoration: BoxDecoration(
      //     //                 borderRadius: BorderRadius.circular(22),
      //     //                 gradient: LinearGradient(
      //     //                   colors: [
      //     //                     Colors.orange.shade600,
      //     //                     Colors.orange.shade800,
      //     //                   ],
      //     //                 ),
      //     //                 boxShadow: [
      //     //                   BoxShadow(
      //     //                     color: Colors.orange.withOpacity(0.25),
      //     //                     blurRadius: 18,
      //     //                     offset: const Offset(0, 8),
      //     //                   ),
      //     //                 ],
      //     //               ),
      //     //               child: Padding(
      //     //                 padding: const EdgeInsets.symmetric(
      //     //                   horizontal: 18,
      //     //                   vertical: 16,
      //     //                 ),
      //     //                 child: Row(
      //     //                   children: [
      //     //                     Container(
      //     //                       width: 46,
      //     //                       height: 46,
      //     //                       decoration: BoxDecoration(
      //     //                         color: Colors.white.withOpacity(0.14),
      //     //                         borderRadius: BorderRadius.circular(14),
      //     //                       ),
      //     //                       child: const Icon(
      //     //                         Icons.shopping_bag_rounded,
      //     //                         color: Colors.white,
      //     //                         size: 24,
      //     //                       ),
      //     //                     ),
      //     //                     const SizedBox(width: 14),
      //     //                     Expanded(
      //     //                       child: Column(
      //     //                         crossAxisAlignment: CrossAxisAlignment.start,
      //     //                         mainAxisSize: MainAxisSize.min,
      //     //                         children: [
      //     //                           const Text(
      //     //                             'Ver pedido',
      //     //                             style: TextStyle(
      //     //                               color: Colors.white,
      //     //                               fontSize: 16,
      //     //                               fontWeight: FontWeight.w700,
      //     //                             ),
      //     //                           ),
      //     //                           const SizedBox(height: 2),
      //     //                           Text(
      //     //                             '${carrinho.totalItens} itens adicionados',
      //     //                             style: TextStyle(
      //     //                               color: Colors.white.withOpacity(0.85),
      //     //                               fontSize: 12,
      //     //                             ),
      //     //                           ),
      //     //                         ],
      //     //                       ),
      //     //                     ),
      //     //                     Container(
      //     //                       padding: const EdgeInsets.symmetric(
      //     //                         horizontal: 14,
      //     //                         vertical: 10,
      //     //                       ),
      //     //                       decoration: BoxDecoration(
      //     //                         color: Colors.white.withOpacity(0.14),
      //     //                         borderRadius: BorderRadius.circular(999),
      //     //                       ),
      //     //                       child: Row(
      //     //                         children: const [
      //     //                           Text(
      //     //                             'Abrir',
      //     //                             style: TextStyle(
      //     //                               color: Colors.white,
      //     //                               fontWeight: FontWeight.w700,
      //     //                               fontSize: 13,
      //     //                             ),
      //     //                           ),
      //     //                           SizedBox(width: 6),
      //     //                           Icon(
      //     //                             Icons.arrow_forward_ios_rounded,
      //     //                             color: Colors.white,
      //     //                             size: 12,
      //     //                           ),
      //     //                         ],
      //     //                       ),
      //     //                     ),
      //     //                   ],
      //     //                 ),
      //     //               ),
      //     //             ),
      //     //           ),
      //     //         ),
      //     //       ),
      //     //     );
      //     //   },
      //     // ),
      //     BotaoPagamentoFlutuante(),
      //   ],
      // ),
      body: Stack(
        children: [
          Positioned.fill(
            child: produtos.isEmpty && isLoading
                ? const Center(
                    child: PulsingLogo(
                      assetPath: 'images/logodd_clean.png',
                      width: 150,
                      duration: Duration(seconds: 1),
                    ),
                  )
                : produtos.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          120,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.96,
                        ),
                        itemCount: produtos.length,
                        itemBuilder: (context, index) {
                          final produto = produtos[index];

                          return GestureDetector(
                            onTap: produto.preco == null
                                ? null
                                : () => _mostrarPopupObs(produto),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: produto.imageUrl != null &&
                                            produto.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            produto.imageUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'images/default.png',
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.60),
                                            Colors.black.withOpacity(0.15),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Spacer(),

                                        Text(
                                          produto.desProduto ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        // PREÇO CARREGANDO
                                        produto.preco == null
                                            ? Container(
                                                width: 70,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: Colors.white24,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                              )
                                            : Text(
                                                'R\$ ${produto.preco!.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.orange.shade200,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          BotaoPagamentoFlutuante(),
        ],
      ),
    );
  }
}

// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:webapp_pedido_mesa/core/constants.dart';
// import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
// import 'package:webapp_pedido_mesa/core/model/item.dart';
// import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';

// class ItensPage extends StatefulWidget {
//   final int idCategoria;

//   const ItensPage({super.key, required this.idCategoria});

//   @override
//   State<ItensPage> createState() => _ItensPageState();
// }

// class _ItensPageState extends State<ItensPage> {
//   List<ItemModel> produtos = [];
//   bool isLoading = false;
//   //List<Produto> carrinho = [];
//   //List<ItemCarrinho> carrinho = [];

//   @override
//   void initState() {
//     super.initState();
//     _carregarProdutos();
//   }

//   Future<void> _carregarProdutos() async {
//     setState(() {
//       isLoading = true;
//     });

//     final url =
//         '${Urls.urlApiAzure}/Categorias/categoria-produto-by-filial/${widget.idCategoria}?idFilial=${GlobalKeys.codFilial}';

//     try {
//       final response = await http.get(Uri.parse(url));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         List<ItemModel> lista = List<ItemModel>.from(
//           data.map((json) => ItemModel.fromJson(json)),
//         );

//         // Agora, para cada produto, buscar o preço
//         List<ItemModel> listaComPreco = [];
//         for (var p in lista) {
//           double? preco = await _buscarPrecoProduto(p.plu!);
//           listaComPreco.add(p.copyWith(preco: preco));
//         }

//         setState(() {
//           produtos = listaComPreco;
//         });

//         // });
//       } else {
//         print('Erro ao carregar produtos: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Erro: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<double?> _buscarPrecoProduto(String plu) async {
//     try {
//       var urlBratter = Urls.urlApiBratter;
//       final encodedUrl = Uri.encodeComponent(urlBratter);

//       final url =
//           '${Urls.urlApiAzure}Proxy/mercadoriafiscal?codigoproduto=$plu&imagens=false&urlBratter=${encodedUrl}&tokenBratter=${GlobalKeys.tokenBratter}';

//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return double.tryParse(data['preco'].toString());
//       } else {
//         print('Erro ao buscar preço do produto $plu: ${response.statusCode}');
//         return null;
//       }
//     } catch (e) {
//       print('Erro ao buscar preço: $e');
//       return null;
//     }
//   }

//   void _adicionarAoCarrinho(ItemModel produto) {
//     Provider.of<CarrinhoModel>(context, listen: false).adicionar(produto);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Itens'),
//         actions: [
//           Consumer<CarrinhoModel>(
//             builder:
//                 (context, carrinho, _) => Stack(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.shopping_cart),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const CarrinhoPage(),
//                           ),
//                         );
//                       },
//                     ),
//                     if (carrinho.totalItens > 0)
//                       Positioned(
//                         right: 4,
//                         top: 4,
//                         child: Container(
//                           padding: const EdgeInsets.all(4),
//                           decoration: const BoxDecoration(
//                             color: Colors.red,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Text(
//                             carrinho.totalItens.toString(),
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//           ),
//         ],
//       ),
//       body:
//           isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : ListView.builder(
//                 itemCount: produtos.length,
//                 itemBuilder: (context, index) {
//                   final produto = produtos[index];

//                   return ListTile(
//                     leading: Icon(Icons.fastfood),
//                     title: Text(produto.desProduto!),

//                     subtitle: Text(
//                       'PLU: ${produto.plu} - Preço: R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
//                     ),
//                     onTap: () {
//                       _adicionarAoCarrinho(produto);
//                     },
//                   );
//                 },
//               ),
//     );
//   }
// }

// Widget auxiliar para os botões de quantidade
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}
