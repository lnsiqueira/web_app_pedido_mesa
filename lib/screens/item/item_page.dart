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

    // Se já existe cache e não for atualização forçada, usa ele
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

        final listaComPrecoEObs = await Future.wait(
          lista.map((p) async {
            try {
              final info = await _buscarPrecoProduto(p.plu!);
              return p.copyWith(
                preco: info.preco,
                obs: info.obs,
              );
            } catch (e) {
              print('Erro ao processar produto ${p.plu}: $e');
              return p;
            }
          }),
        );

        // Atualiza no provider
        produtosProvider.atualizarProdutos(
            widget.idCategoria, listaComPrecoEObs);
      } else {
        print('Erro ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.fastfood_rounded,
                                  color: Colors.orange.shade700, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    produto.desProduto ?? '',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),

                      // Scrollable content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          children: [
                            // Quantidade
                            const Text('Quantidade',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: Colors.grey)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _QtyButton(
                                  icon: Icons.remove,
                                  onTap: () => setStateSB(() {
                                    if (quantidade > 1) quantidade--;
                                  }),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '$quantidade',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                _QtyButton(
                                  icon: Icons.add,
                                  onTap: () => setStateSB(() => quantidade++),
                                ),
                              ],
                            ),

                            // Obs de escolha (chips "com")
                            if (obs.any((o) => o.tipo == 'escolha')) ...[
                              const SizedBox(height: 24),
                              const Text('Personalize seu pedido',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                      color: Colors.grey)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: obs.mapIndexed((i, o) {
                                  if (o.tipo != 'escolha')
                                    return const SizedBox.shrink();
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
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.orange.shade50
                                            : Colors.white,
                                        border: Border.all(
                                          color: selected
                                              ? Colors.orange.shade700
                                              : Colors.grey.shade300,
                                          width: selected ? 1.5 : 0.8,
                                        ),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (selected) ...[
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade700,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check,
                                                  size: 11,
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            o.titulo ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
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

                            // Campo de texto livre
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 0.8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Alguma observação?',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500)),
                                  const SizedBox(height: 4),
                                  ...obs.mapIndexed((i, o) {
                                    if (o.tipo != 'texto')
                                      return const SizedBox.shrink();
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
                                      style: const TextStyle(fontSize: 14),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Footer
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20,
                            MediaQuery.of(context).padding.bottom + 16),
                        child: Row(
                          children: [
                            // Botão cancelar
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 50),
                                  side: BorderSide(
                                      color: Colors.grey.shade300, width: 0.8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Cancelar',
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 15)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Botão adicionar
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
                                        obsFinalizadas.add(o.copyWith(
                                            modificador: 'COM',
                                            pluAdd: 0,
                                            titulo: txt));
                                      }
                                    } else if (o.tipo == 'escolha' &&
                                        o.modificador == 'C') {
                                      obsFinalizadas.add(o.copyWith(pluAdd: 0));
                                    }
                                  }
                                  for (int i = 0; i < quantidade; i++) {
                                    _adicionarAoCarrinho(
                                        produto.copyWith(obs: obsFinalizadas));
                                  }
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 50),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Adicionar · R\$ ${total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
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

  void _adicionarAoCarrinho(ItemModel produto) {
    Provider.of<CarrinhoModel>(context, listen: false).adicionar(produto);
  }

  @override
  Widget build(BuildContext context) {
    final produtosProvider = Provider.of<ProdutosCacheProvider>(context);
    final produtos = produtosProvider.obterProdutos(widget.idCategoria);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nomeCategoria,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _carregarProdutos(forceRefresh: true);
            },
          ),
          Consumer<CarrinhoModel>(
            builder: (context, carrinho, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
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
      body: isLoading
          ? Center(
              child: PulsingLogo(
              assetPath: 'images/logodd_clean.png',
              width: 150,
              duration: const Duration(seconds: 1),
            ))
          : produtos.isEmpty
              ? const Center(child: Text('Nenhum produto encontrado.'))
              : ListView.builder(
                  itemCount: produtos.length,
                  // itemBuilder: (context, index) {
                  //   final produto = produtos[index];
                  //   return Padding(
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 12, vertical: 0),
                  //     child: Card(
                  //       elevation: 2,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(16),
                  //       ),
                  //       child: InkWell(
                  //         borderRadius: BorderRadius.circular(16),
                  //         onTap: () {
                  //           _mostrarPopupObs(produto);
                  //         },
                  //         child: Padding(
                  //           padding: const EdgeInsets.all(12),
                  //           child: Row(
                  //             children: [
                  //               // Ícone / Imagem
                  //               Container(
                  //                 height: 42,
                  //                 width: 42,
                  //                 decoration: BoxDecoration(
                  //                   color: Colors.orange.shade50,
                  //                   borderRadius: BorderRadius.circular(12),
                  //                   border: Border.all(
                  //                     color: Colors.orange.shade300,
                  //                     width: 1.5,
                  //                   ),
                  //                 ),
                  //                 child: Icon(
                  //                   Icons.fastfood,
                  //                   size: 24,
                  //                   color: Colors.orange.shade600,
                  //                 ),
                  //               ),
                  //               const SizedBox(width: 12),

                  //               // Nome + Preço
                  //               Expanded(
                  //                 child: Column(
                  //                   crossAxisAlignment:
                  //                       CrossAxisAlignment.start,
                  //                   children: [
                  //                     Text(
                  //                       produto.desProduto ?? '',
                  //                       style: const TextStyle(
                  //                         fontSize: 16,
                  //                         fontWeight: FontWeight.w600,
                  //                         color: Colors.black87,
                  //                       ),
                  //                       maxLines: 1,
                  //                       overflow: TextOverflow.ellipsis,
                  //                     ),
                  //                     const SizedBox(height: 4),
                  //                     Text(
                  //                       'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                  //                       style: TextStyle(
                  //                         fontSize: 14,
                  //                         fontWeight: FontWeight.w500,
                  //                         color: Colors.grey[700],
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),

                  //               const Icon(
                  //                 Icons.add,
                  //                 color: Colors.grey,
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   );
                  // },
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    final colors = [
                      Colors.orange,
                      // Colors.red,
                      // Colors.green,
                      // Colors.purple
                    ];
                    final bgColor = colors[index % colors.length].shade50;
                    final iconColor = colors[index % colors.length].shade600;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _mostrarPopupObs(produto),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 0.8,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  // Ícone com fundo colorido suave
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.fastfood_rounded,
                                      size: 26,
                                      color: iconColor,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Nome + descrição + preço
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          produto.desProduto ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (produto.desCategoria != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            produto.desCategoria!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Botão +
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 0.8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 18,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Consumer<CarrinhoModel>(
        builder: (context, carrinho, _) {
          if (carrinho.totalItens == 0) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CarrinhoPage(),
                  ),
                );
              },
              child: Text(
                "Prosseguir (${carrinho.totalItens} itens)",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          );
        },
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
