import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/orderRoom/screens/widgets/bottom_carrinho.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';
import 'package:webapp_pedido_mesa/widgets/logo_pulsando.dart';

class ProdutosCategoriaPage extends StatefulWidget {
  final String titulo;
  final List<ItemModel> produtos;

  const ProdutosCategoriaPage({
    super.key,
    required this.titulo,
    required this.produtos,
  });

  @override
  State<ProdutosCategoriaPage> createState() => _ProdutosCategoriaPageState();
}

// class _ProdutosCategoriaPageState extends State<ProdutosCategoriaPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.titulo),
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       body: GridView.builder(
//         padding: const EdgeInsets.all(16),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 16,
//           crossAxisSpacing: 16,
//           childAspectRatio: 0.96,
//         ),
//         itemCount: widget.produtos.length,
//         itemBuilder: (context, index) {
//           final item = widget.produtos[index];
//           final indisponivel = (item.quantidadeDisponivel ?? 0) <= 0;

//           return Opacity(
//             opacity: indisponivel ? 0.5 : 1,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(18),
//               child: Stack(
//                 children: [
//                   /// Imagem de fundo padrão
//                   Positioned.fill(
//                     child: Image.asset(
//                       'images/default.png',
//                       fit: BoxFit.cover,
//                     ),
//                   ),

//                   /// Overlay clean
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.bottomCenter,
//                           end: Alignment.topCenter,
//                           colors: [
//                             Colors.black.withOpacity(0.55),
//                             Colors.transparent,
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   /// Conteúdo
//                   Padding(
//                     padding: const EdgeInsets.all(14),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Spacer(),

//                         /// Nome do produto
//                         Text(
//                           item.desProduto ?? '',
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),

//                         const SizedBox(height: 6),
//                         Text(
//                           'R\$ 16,00',
//                           style: TextStyle(
//                               color: indisponivel
//                                   ? Colors.white12
//                                   : Colors.white60,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600),
//                         ),

//                         /// Disponibilidade
//                         // Text(
//                         //   indisponivel
//                         //       ? 'Indisponível'
//                         //       : 'Disponível: ${item.quantidadeDisponivel}',
//                         //   style: TextStyle(
//                         //     color: indisponivel
//                         //         ? Colors.redAccent.shade100
//                         //         : Colors.white70,
//                         //     fontSize: 12,
//                         //   ),
//                         // ),
//                       ],
//                     ),
//                   ),

//                   /// Botão +
//                   Positioned(
//                     bottom: 12,
//                     right: 12,
//                     child: GestureDetector(
//                       onTap: indisponivel ? null : () {},
//                       child: Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: indisponivel
//                               ? Colors.grey.shade400
//                               : Colors.white
//                                   .withOpacity(0.4), // suaviza o branco
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.15),
//                               blurRadius: 6,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Icon(
//                           Icons.add_outlined,
//                           size: 20,
//                           color: indisponivel ? Colors.white : Colors.black54,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
class _ProdutosCategoriaPageState extends State<ProdutosCategoriaPage> {
  late List<ItemModel> _produtos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _produtos = widget.produtos
        .where((p) => (p.quantidadeDisponivel ?? 0) > 0)
        .toList();
    _carregarPrecos();
  }

  /// Chama o seu método para cada produto
  Future<void> _carregarPrecos() async {
    List<ItemModel> atualizados = [];
    for (var p in _produtos) {
      try {
        final info = await _buscarPrecoProduto(p.plu!);
        atualizados.add(p.copyWith(preco: info.preco, obs: info.obs));
      } catch (e) {
        print('Erro ao buscar preço/obs do produto ${p.plu}: $e');
        atualizados.add(p);
      }
    }
    if (mounted) {
      setState(() {
        _produtos = atualizados;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.titulo,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            // // Carrinho com badge
            Consumer<CarrinhoModel>(
              builder: (context, carrinho, _) => Stack(
                alignment: Alignment.center,
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
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(
              child: PulsingLogo(
                assetPath: 'images/logodd_clean.png',
                width: 150,
                duration: Duration(seconds: 1),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.96,
              ),
              itemCount: _produtos.length,
              itemBuilder: (context, index) {
                final item = _produtos[index];
                final indisponivel = (item.quantidadeDisponivel ?? 0) <= 0;

                return GestureDetector(
                  onTap: () => _mostrarPopupProduto(item),
                  child: Opacity(
                    opacity: indisponivel ? 0.5 : 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          /// Imagem de fundo padrão
                          Positioned.fill(
                            child: Image.asset(
                              'images/default.png',
                              fit: BoxFit.cover,
                            ),
                          ),

                          /// Overlay clean
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.55),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          /// Conteúdo
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Spacer(),

                                /// Nome do produto
                                Text(
                                  item.desProduto ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 6),
                                Text(
                                  'R\$ ${item.preco?.toStringAsFixed(2) ?? '--'}',
                                  style: TextStyle(
                                      color: indisponivel
                                          ? Colors.white12
                                          : Colors.white60,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),

                          /// Botão +
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: indisponivel
                                  ? null
                                  : () {
                                      _adicionarAoCarrinho(item);
                                    },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: indisponivel
                                      ? Colors.grey.shade400
                                      : Colors.white.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.add_outlined,
                                  size: 20,
                                  color: indisponivel
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: const BottomCarrinhoBar(),
    );
  }

  /// Seu método original
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

  void _mostrarPopupProduto(ItemModel produto) {
    // final List<ItemObsModel> obs = List.from(produto.obs ?? []);
    final List<ItemObsModel> obs = (produto.obs ?? [])
        .map((o) => o.copyWith()) // cria cópia de cada item
        .toList();

    final Map<int, TextEditingController> textControllers = {};

    // cria controllers para obs do tipo texto
    for (int i = 0; i < obs.length; i++) {
      if (obs[i].tipo == 'texto') {
        textControllers[i] = TextEditingController();
      }
    }
    String _modoObs = 'ADICIONAR'; // valor inicial
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Imagem + nome + preço (ALTERADO)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Stack(
                      children: [
                        Image.asset(
                          'images/default_logo.png',
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),

                        // Gradient
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(
                                      0.25), // topo já levemente escuro
                                  Colors.black.withOpacity(0.55), // meio
                                  Colors.black
                                      .withOpacity(0.8), // mais escuro embaixo
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop(); // sai da tela
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),

                        // Nome e preço sobre a imagem
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                produto.desProduto ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Conteúdo (INALTERADO)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        // Observações interativas
                        if (obs.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // const Text(
                              //   'Adicionar:',
                              //   style: TextStyle(
                              //     fontSize: 16,
                              //     fontWeight: FontWeight.w600,
                              //   ),
                              // ),
                              // const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Expanded(
                                  //   child: InkWell(
                                  //     onTap: () {
                                  //       setStateSB(() {
                                  //         _modoObs = 'ADICIONAR';
                                  //       });
                                  //     },
                                  //     borderRadius: BorderRadius.circular(8),
                                  //     child: Container(
                                  //       padding: const EdgeInsets.symmetric(
                                  //           vertical: 10),
                                  //       decoration: BoxDecoration(
                                  //         color: _modoObs == 'ADICIONAR'
                                  //             ? Colors.green.shade600
                                  //             : Colors.grey.shade200,
                                  //         borderRadius:
                                  //             BorderRadius.circular(8),
                                  //         boxShadow: _modoObs == 'ADICIONAR'
                                  //             ? [
                                  //                 BoxShadow(
                                  //                   color: Colors.green.shade200
                                  //                       .withOpacity(0.5),
                                  //                   blurRadius: 8,
                                  //                   offset: const Offset(0, 4),
                                  //                 )
                                  //               ]
                                  //             : [],
                                  //       ),
                                  //       child: Center(
                                  //         child: Text(
                                  //           'Adicionar',
                                  //           style: TextStyle(
                                  //             color: _modoObs == 'ADICIONAR'
                                  //                 ? Colors.white
                                  //                 : Colors.grey.shade800,
                                  //             fontWeight: FontWeight.w600,
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                  // const SizedBox(width: 12),
                                  // Expanded(
                                  //   child: InkWell(
                                  //     onTap: () {
                                  //       setStateSB(() {
                                  //         _modoObs = 'REMOVER';
                                  //       });
                                  //     },
                                  //     borderRadius: BorderRadius.circular(8),
                                  //     child: Container(
                                  //       padding: const EdgeInsets.symmetric(
                                  //           vertical: 10),
                                  //       decoration: BoxDecoration(
                                  //         color: _modoObs == 'REMOVER'
                                  //             ? Colors.red.shade600
                                  //             : Colors.grey.shade200,
                                  //         borderRadius:
                                  //             BorderRadius.circular(8),
                                  //         boxShadow: _modoObs == 'REMOVER'
                                  //             ? [
                                  //                 BoxShadow(
                                  //                   color: Colors.red.shade200
                                  //                       .withOpacity(0.5),
                                  //                   blurRadius: 8,
                                  //                   offset: const Offset(0, 4),
                                  //                 )
                                  //               ]
                                  //             : [],
                                  //       ),
                                  //       child: Center(
                                  //         child: Text(
                                  //           'Remover',
                                  //           style: TextStyle(
                                  //             color: _modoObs == 'REMOVER'
                                  //                 ? Colors.white
                                  //                 : Colors.grey.shade800,
                                  //             fontWeight: FontWeight.w600,
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 220),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: // Container limitado com scroll e cards 2x por linha
                                    LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cardWidth =
                                        (constraints.maxWidth - 12) /
                                            2; // 2 cards + spacing
                                    return SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children:
                                            obs.asMap().entries.map((entry) {
                                          final i = entry.key;
                                          final o = entry.value;

                                          if (o.tipo == 'escolha') {
                                            final atual = obs[
                                                i]; // pega o item atualizado
                                            Color borderColor;
                                            if (atual.modificador == 'C') {
                                              borderColor = Colors.green;
                                            } else if (atual.modificador ==
                                                'S') {
                                              borderColor = Colors.red;
                                            } else {
                                              borderColor =
                                                  Colors.grey.shade300;
                                            }

                                            return GestureDetector(
                                              onTap: () {
                                                setStateSB(() {
                                                  final atual = obs[i];
                                                  if (_modoObs == 'ADICIONAR') {
                                                    obs[i] = atual
                                                                .modificador ==
                                                            'C'
                                                        ? atual.copyWith(
                                                            modificador: null)
                                                        : atual.copyWith(
                                                            modificador: 'C');
                                                  } else if (_modoObs ==
                                                      'REMOVER') {
                                                    obs[i] = atual
                                                                .modificador ==
                                                            'S'
                                                        ? atual.copyWith(
                                                            modificador: null)
                                                        : atual.copyWith(
                                                            modificador: 'S');
                                                  }
                                                });
                                              },
                                              child: Container(
                                                width: cardWidth,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: borderColor,
                                                      width: 2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    child: Text(
                                                      atual.titulo ??
                                                          '', // <- aqui também muda de 'o.titulo' para 'atual.titulo'
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: borderColor ==
                                                                Colors.grey
                                                                    .shade300
                                                            ? Colors.black87
                                                            : borderColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else if (o.tipo == 'texto') {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: TextField(
                                                controller: textControllers[i],
                                                decoration:
                                                    const InputDecoration(
                                                  labelText:
                                                      'Digite uma observação',
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            );
                                          }

                                          return const SizedBox.shrink();
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Botão adicionar (INALTERADO)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.orange.shade600,
                        ),
                        onPressed: () {
                          // aplica as observações selecionadas no produto
                          final produtoComObs = produto.copyWith(
                            obs: _montarObsFinal(obs, textControllers),
                          );

                          _adicionarAoCarrinho(produtoComObs);
                          Navigator.pop(context);
                        },
                        // onPressed: () {
                        //   _adicionarAoCarrinho(produto);
                        //   // seu código aqui
                        //   Navigator.pop(context);
                        // },
                        child: const Text(
                          'Adicionar ao Carrinho',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<ItemObsModel> _montarObsFinal(
    List<ItemObsModel> obs,
    Map<int, TextEditingController> textControllers,
  ) {
    final List<ItemObsModel> resultado = [];

    for (int i = 0; i < obs.length; i++) {
      final o = obs[i];

      // ESCOLHA (Com / Sem)
      if (o.tipo == 'escolha' && o.modificador != null) {
        resultado.add(o);
      }

      // TEXTO
      if (o.tipo == 'texto') {
        final texto = textControllers[i]?.text.trim();
        if (texto != null && texto.isNotEmpty) {
          resultado.add(
            o.copyWith(
              titulo: texto,
              modificador: 'COM',
            ),
          );
        }
      }
    }

    return resultado;
  }

  void _adicionarAoCarrinho(ItemModel produto) {
    Provider.of<CarrinhoModel>(context, listen: false).adicionar(produto);
  }
}
