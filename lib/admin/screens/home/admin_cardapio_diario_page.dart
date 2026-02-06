import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webapp_pedido_mesa/admin/services/cardapio_admin_service.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/widgets/logo_pulsando.dart';
import 'package:http/http.dart' as http;

class AdminCardapioDiarioPage extends StatefulWidget {
  const AdminCardapioDiarioPage({super.key});

  @override
  State<AdminCardapioDiarioPage> createState() =>
      _AdminCardapioDiarioPageState();
}

class _AdminCardapioDiarioPageState extends State<AdminCardapioDiarioPage> {
  bool isLoading = true;
  Map<String, dynamic>? cardapioData;

  @override
  void initState() {
    super.initState();
    carregarCardapio();
  }

  Future<void> carregarCardapio() async {
    final now = DateTime.now();
    debugPrint(
      '&data=${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}-'
      '${now.year}',
    );

    final url = Uri.parse(
      '${Urls.urlApiAzureCardapioDiario}CardapioHospital/cardapio-diario'
      '?filialId=1768831340259'
      '&data=$now',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          cardapioData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar cardápio');
      }
    } catch (e) {
      debugPrint('Erro: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: PulsingLogo(
            assetPath: 'images/logodd_clean.png',
            width: 150,
            duration: Duration(seconds: 1),
          ),
        ),
      );
    }

    final categorias = cardapioData?['cardapio'] ?? [];

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Image.asset('images/logodd_clean.png', height: 40),
          ])),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Cardápio do site',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gerencie categorias e disponibilidade dos produtos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 🔹 Lista
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                final produtos = categoria['produtos'] as List;

                return _CategoriaSection(
                  titulo: categoria['categoria'],
                  produtos: produtos,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriaSection extends StatefulWidget {
  final String titulo;
  final List produtos;

  const _CategoriaSection({
    required this.titulo,
    required this.produtos,
  });

  @override
  State<_CategoriaSection> createState() => _CategoriaSectionState();
}

class _CategoriaSectionState extends State<_CategoriaSection> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          widget.titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int crossAxisCount = 2;
              if (width > 900)
                crossAxisCount = 4;
              else if (width > 600) crossAxisCount = 3;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.produtos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return _ProdutoGridCard(widget.produtos[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProdutoGridCard extends StatefulWidget {
  final Map<String, dynamic> produto;

  const _ProdutoGridCard(this.produto);

  @override
  State<_ProdutoGridCard> createState() => _ProdutoGridCardState();
}

class _ProdutoGridCardState extends State<_ProdutoGridCard> {
  late bool ativo;
  late int quantidade;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    ativo = widget.produto['ativo'] ?? true;
    quantidade = widget.produto['quantidadeDisponivel'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: salvando ? null : () => _abrirPopup(context),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: ativo ? 1 : 0.45,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// STATUS
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ativo
                              ? Colors.green.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min, // 🔑 NÃO quebrar alinhamento
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: ativo ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ativo ? 'Ativo' : 'Inativo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ativo ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      widget.produto['nome'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'PLU: ${widget.produto['plu']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estoque', style: TextStyle(fontSize: 12)),
                        Text(
                          '$quantidade',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (salvando)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirPopup(BuildContext context) {
    bool ativoLocal = ativo;
    int quantidadeLocal = quantidade;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(widget.produto['nome']),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// ATIVO / INATIVO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ativoLocal ? 'Ativo' : 'Inativo',
                        style: TextStyle(
                          color: ativoLocal ? Colors.green : Colors.red,
                        ),
                      ),
                      Switch(
                        value: ativoLocal,
                        activeColor: Colors.green,
                        onChanged: (value) {
                          setStateDialog(() => ativoLocal = value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// QUANTIDADE
                  /// QUANTIDADE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantidade'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantidadeLocal > 0
                                ? () => setStateDialog(() => quantidadeLocal--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              controller: TextEditingController(
                                text: quantidadeLocal.toString(),
                              ),
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null && parsed >= 0) {
                                  setStateDialog(
                                      () => quantidadeLocal = parsed);
                                }
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setStateDialog(() => quantidadeLocal++),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() => salvando = true);

                    bool ok = true;

                    /// ATIVA / DESATIVA
                    if (ativoLocal != ativo) {
                      ok = await ativarDesativarProduto(
                        idProduto: widget.produto['id'],
                        ativo: ativoLocal,
                      );
                    }

                    /// ATUALIZA QUANTIDADE
                    if (ok && quantidadeLocal != quantidade) {
                      ok = await atualizarQuantidadeProduto(
                        idProduto: widget.produto['id'],
                        novaQuantidade: quantidadeLocal,
                      );
                    }

                    if (ok) {
                      setState(() {
                        ativo = ativoLocal;
                        quantidade = quantidadeLocal;
                        widget.produto['ativo'] = ativoLocal;
                        widget.produto['quantidadeDisponivel'] =
                            quantidadeLocal;
                      });
                    }

                    setState(() => salvando = false);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

  // void _confirmarToggle(BuildContext context) {
  //   bool ativoLocal = ativo;
  //   int quantidadeLocal = quantidade;

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setStateDialog) {
  //           return AlertDialog(
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(16),
  //             ),
  //             title: Text(widget.produto['nome']),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 // SWITCH ATIVO
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       ativoLocal ? 'Ativo' : 'Inativo',
  //                       style: TextStyle(
  //                         color: ativoLocal ? Colors.green : Colors.red,
  //                       ),
  //                     ),
  //                     Switch(
  //                       value: ativoLocal,
  //                       onChanged: (value) {
  //                         setStateDialog(() => ativoLocal = value);
  //                       },
  //                     ),
  //                   ],
  //                 ),

  //                 const SizedBox(height: 16),

  //                 // CONTROLE DE ESTOQUE
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     const Text(
  //                       'Estoque',
  //                       style: TextStyle(fontWeight: FontWeight.w600),
  //                     ),
  //                     Row(
  //                       children: [
  //                         IconButton(
  //                           icon: const Icon(Icons.remove),
  //                           onPressed: quantidadeLocal > 0
  //                               ? () {
  //                                   setStateDialog(() => quantidadeLocal--);
  //                                 }
  //                               : null,
  //                         ),
  //                         Text(
  //                           '$quantidadeLocal',
  //                           style: const TextStyle(
  //                             fontSize: 18,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                         IconButton(
  //                           icon: const Icon(Icons.add),
  //                           onPressed: () {
  //                             setStateDialog(() => quantidadeLocal++);
  //                           },
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text('Cancelar'),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () async {
  //                   Navigator.pop(context);
  //                   setState(() => salvando = true);

  //                   bool okAtivo = await ativarDesativarProduto(
  //                     idProduto: widget.produto['id'].toString(),
  //                     ativo: ativoLocal,
  //                   );

  //                   bool okQuantidade = await atualizarQuantidadeProduto(
  //                     idProduto: widget.produto['id'],
  //                     novaQuantidade: quantidadeLocal,
  //                   );

  //                   if (okAtivo && okQuantidade) {
  //                     setState(() {
  //                       ativo = ativoLocal;
  //                       quantidade = quantidadeLocal;

  //                       widget.produto['ativo'] = ativoLocal;
  //                       widget.produto['quantidadeDisponivel'] =
  //                           quantidadeLocal;
  //                     });
  //                   }

  //                   setState(() => salvando = false);
  //                 },
  //                 child: const Text('Salvar'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // void _confirmarToggle(BuildContext context) {
  //   bool ativoLocal = ativo;

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setStateDialog) {
  //           return AlertDialog(
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(16),
  //             ),
  //             title: Text(widget.produto['nome']),
  //             content: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Text(
  //                   ativoLocal ? 'Ativo' : 'Inativo',
  //                   style: TextStyle(
  //                     color: ativoLocal ? Colors.green : Colors.red,
  //                   ),
  //                 ),
  //                 Switch(
  //                   value: ativoLocal,
  //                   activeColor: Colors.green,
  //                   onChanged: (value) {
  //                     setStateDialog(() => ativoLocal = value);
  //                   },
  //                 ),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text('Cancelar'),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () async {
  //                   Navigator.pop(context);

  //                   setState(() => salvando = true);

  //                   final sucesso = await ativarDesativarProduto(
  //                     idProduto: widget.produto['id'].toString(),
  //                     ativo: ativoLocal,
  //                   );

  //                   if (sucesso) {
  //                     setState(() {
  //                       ativo = ativoLocal;
  //                       widget.produto['ativo'] = ativoLocal;
  //                     });
  //                   }

  //                   setState(() => salvando = false);
  //                 },
  //                 child: const Text('Salvar'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }


// class _ProdutoGridCard extends StatelessWidget {
//   final Map<String, dynamic> produto;

//   const _ProdutoGridCard(this.produto);

//   bool get ativo => produto['ativo'] ?? true;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => _confirmarToggle(context),
//       child: AnimatedOpacity(
//         duration: const Duration(milliseconds: 200),
//         opacity: ativo ? 1 : 0.45,
//         child: Card(
//           elevation: 3,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 🔴🟢 STATUS
//                 Align(
//                   alignment: Alignment.topRight,
//                   child: Container(
//                     width: 10,
//                     height: 10,
//                     decoration: BoxDecoration(
//                       color: ativo ? Colors.green : Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 6),

//                 // NOME
//                 Text(
//                   produto['nome'],
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   ),
//                 ),

//                 const SizedBox(height: 4),

//                 // PLU
//                 Text(
//                   'PLU: ${produto['plu']}',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),

//                 const Spacer(),

//                 // ESTOQUE
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Estoque',
//                       style: TextStyle(fontSize: 12),
//                     ),
//                     Text(
//                       '${produto['quantidadeDisponivel']}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _confirmarToggle(BuildContext context) {
//     bool ativoLocal = ativo;

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               title: Text(
//                 produto['nome'],
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               content: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     ativoLocal ? 'Ativo' : 'Inativo',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w500,
//                       color: ativoLocal ? Colors.green : Colors.red,
//                     ),
//                   ),
//                   Switch(
//                     value: ativoLocal,
//                     activeColor: Colors.green,
//                     onChanged: (value) {
//                       setStateDialog(() {
//                         ativoLocal = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Fechar'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     // 🔜 aqui entra o PUT (ativar / desativar)
//                   },
//                   child: const Text('Salvar'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }
