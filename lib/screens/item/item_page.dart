import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/screens/item/produto_popup.dart';
import 'package:webapp_pedido_mesa/services/cardapio_service.dart';
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

  /// Grupos da Dashboard: produtos agrupados aparecem num card só
  List<GrupoProdutos> _grupos = [];

  /// Selos vegano/vegetariano (Dashboard), por id do produto
  Map<int, ({bool vegetariano, bool vegano})> _selos = {};

  List<String> _selosDe(Iterable<ItemModel> produtos) {
    final s = [for (final p in produtos) _selos[p.id]];
    if (s.isEmpty || s.any((x) => x == null)) return const [];
    return [
      if (s.every((x) => x!.vegano)) 'Vegano',
      if (s.every((x) => x!.vegetariano)) 'Vegetariano',
    ];
  }

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
    GrupoProdutos.todos().then((g) {
      if (mounted) setState(() => _grupos = g);
    });
    Complementos.selos().then((v) {
      if (mounted) setState(() => _selos = v);
    });
  }

  /// Produtos como aparecem na grade: os de um grupo viram um card só
  List<Object> _exibicao(List<ItemModel> produtos) =>
      agruparProdutos(produtos, _grupos);

  static String _reais(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  /// Card da grade (produto ou grupo)
  Widget _card({
    required String imagem,
    required String nome,
    required double? preco,
    String? selo,
    List<String> selosVeg = const [],
    bool iconeVeg = false,
    bool aPartirDe = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: imagem.isNotEmpty
                  ? Image.network(
                      imagem,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                          'images/default_logo.png',
                          fit: BoxFit.cover),
                    )
                  : Image.asset('images/default_logo.png', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.70),
                      Colors.black.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (selo != null)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(selo,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE8710A))),
                ),
              ),
            // grupo com alguma opção vegana/vegetariana: só o ícone, no canto
            // oposto ao "N opções" (como no tablet)
            if (iconeVeg)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded,
                      size: 16, color: Color(0xFF2E7D32)),
                ),
              ),
            if (selosVeg.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final v in selosVeg)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.eco_rounded,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(v,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // preço em branco (carregando = traço discreto)
                  SizedBox(
                    height: 20,
                    child: preco == null
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 60,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text.rich(
                              TextSpan(children: [
                                if (aPartirDe)
                                  const TextSpan(
                                    text: 'a partir de ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                TextSpan(text: 'R\$ ${_reais(preco)}'),
                              ]),
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        '${Urls.urlApiAzure}Categorias/categoria-produto-by-filial/${widget.idCategoria}?idFilial=$codFilialCardapio';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<ItemModel> lista = List<ItemModel>.from(
          data.map((json) => ItemModel.fromJson(json)),
        )..removeWhere((p) => p.ativo == false || (p.plu ?? '').isEmpty);

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

  @override
  Widget build(BuildContext context) {
    final produtosProvider = Provider.of<ProdutosCacheProvider>(context);
    final produtos = produtosProvider.obterProdutos(widget.idCategoria);
    final exibicao = _exibicao(produtos);

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
                        // margens e espaço entre os cards menores
                        padding: const EdgeInsets.fromLTRB(
                          10,
                          10,
                          10,
                          120,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.96,
                        ),
                        itemCount: exibicao.length,
                        itemBuilder: (context, index) {
                          final item = exibicao[index];
                          if (item is (
                            GrupoProdutos,
                            List<MapEntry<ItemModel, String>>
                          )) {
                            final (grupo, opcoes) = item;
                            final precos = opcoes
                                .map((o) => o.key.preco)
                                .whereType<double>()
                                .toList();
                            final imagem = grupo.imagem.isNotEmpty
                                ? grupo.imagem
                                : (opcoes.first.key.imageUrl ?? '');
                            return _card(
                              imagem: imagem,
                              nome: grupo.nome.isNotEmpty
                                  ? grupo.nome
                                  : (opcoes.first.key.desProduto ?? '').trim(),
                              // meio a meio: a partir das 2 metades mais
                              // baratas somadas
                              preco: precos.isEmpty
                                  ? null
                                  : grupo.meioAMeio && precos.length >= 2
                                      ? ((List.of(precos)..sort())[0] +
                                          (List.of(precos)..sort())[1])
                                      : precos.reduce((a, b) => a < b ? a : b),
                              selo: grupo.meioAMeio
                                  ? '${opcoes.length} sabores'
                                  : '${opcoes.length} opções',
                              iconeVeg: opcoes
                                  .any((o) => _selosDe([o.key]).isNotEmpty),
                              aPartirDe: precos.toSet().length > 1,
                              onTap: () =>
                                  escolherOpcaoGrupo(context, grupo, opcoes),
                            );
                          }
                          final produto = item as ItemModel;
                          return _card(
                            imagem: produto.imageUrl ?? '',
                            nome: (produto.desProduto ?? '').trim(),
                            preco: produto.preco,
                            selosVeg: _selosDe([produto]),
                            onTap: produto.preco == null
                                ? null
                                : () => abrirProdutoPopup(context, produto),
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
class QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const QtyButton({required this.icon, required this.onTap});

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
