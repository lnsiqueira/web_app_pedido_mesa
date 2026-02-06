import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/controllers/language_controller.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/categorias.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';
import 'package:webapp_pedido_mesa/screens/item/item_page.dart';
import 'package:webapp_pedido_mesa/services/storage/carrinho_storage.dart';
import 'package:webapp_pedido_mesa/widgets/conexao_wrapper.dart';
import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/widgets/logo_pulsando.dart';
import 'package:webapp_pedido_mesa/widgets/popup_mesa_comanda.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _mesa;
  String? _comanda;
  List<Categoria> categorias = [];
  bool isLoading = false;
  Future<void> _pedirMesaEComanda() async {
    final mesaController = TextEditingController();
    final comandaController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => PopupMesaComanda(
          formKey: _formKey,
          mesaController: mesaController,
          comandaController: comandaController),
    );

    if (result != null) {
      setState(() {
        _mesa = result['mesa'];
        _comanda = result['comanda'];
      });

      final mesaComanda = Provider.of<MesaComandaModel>(
        context,
        listen: false,
      );

      mesaComanda.setMesa(_mesa!);
      mesaComanda.setComanda(_comanda!);
      _carregarCategorias();
    }
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      isLoading = true;
    });

    const url =
        '${Urls.urlApiAzure}/Categorias/categoria-by-filial/${GlobalKeys.codFilial}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          categorias = data.map((e) => Categoria.fromJson(e)).toList();
        });
      } else {
        print('Erro ao carregar categorias: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 3 - 24;
    final mesa = context.watch<MesaComandaModel>().mesa;
    final comanda = context.watch<MesaComandaModel>().comanda;

    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: AppBar(
            automaticallyImplyLeading: false, // Oculta botão "voltar"
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LOGO
                Image.asset('images/logodd_clean.png', height: 40),

                // FLAGS + CARRINHO
                Row(
                  children: [
                    _buildFlag('images/br.png', 'pt', languageController),
                    const SizedBox(width: 6),
                    _buildFlag('images/en.png', 'en', languageController),
                    const SizedBox(width: 6),
                    _buildFlag('images/es.png', 'es', languageController),
                    const SizedBox(width: 8),
                    MeusPedidosWidget(),

                    // const SizedBox(width: 4),
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
              ],
            ),
          ),
        ),
        body: ConexaoWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      isLoading
                          ? Expanded(
                              child: isLoading
                                  ? Center(
                                      child: PulsingLogo(
                                        assetPath: 'images/logodd_clean.png',
                                        duration: const Duration(seconds: 1),
                                      ),
                                    )
                                  : SizedBox(),
                            )
                          : const SizedBox(height: 20),
                      if (mesa != null && comanda != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0.0,
                          ),
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 16,
                                children: categorias.map((categoria) {
                                  return SizedBox(
                                    height: 160,
                                    width: itemWidth.clamp(100, 180),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 3,
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ItensPage(
                                                nomeCategoria:
                                                    categoria.desCategoria,
                                                idCategoria: categoria.id,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                                child: Image.network(
                                                  categoria.imagem,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: SizedBox(
                                                height:
                                                    38, // altura equivalente a 2 linhas
                                                child: Center(
                                                  child: Text(
                                                    categoria.desCategoria,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                      height: 1.2,
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
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      Consumer<MesaComandaModel>(
                          builder: (context, comanda, _) {
                        if (comanda.comanda == '') {
                          return SizedBox(
                            height: constraints.maxHeight / 1.2,
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: _pedirMesaEComanda,
                                icon: const Icon(Icons.restaurant_menu,
                                    size: 20, color: Colors.white),
                                label: Text(
                                  AppLocalizations.of(context)!
                                      .placeYourOrder
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                  elevation: 6,
                                  shadowColor: Colors.orange.withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox();
                      }),
                      const Spacer(),
                      const Divider(height: 1, thickness: 1),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          '© 2025 BakeryFood. Todos os direitos reservados. Version: 1.2.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
      ),
    );
  }

  Widget _buildFlag(String path, String lang, LanguageController controller) {
    return InkWell(
      onTap: () {
        controller.changeLanguage(lang);
      },
      child: Image.asset(path, width: 24),
    );
  }
}

// class MeusPedidosWidget extends StatelessWidget {
//   const MeusPedidosWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final carrinho = Provider.of<CarrinhoModel>(context);

//     return GestureDetector(
//       onTap: () {
//         if (carrinho.itens.isEmpty) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text('Carrinho vazio')));
//           return;
//         }
//         showDialog(
//           context: context,
//           builder: (context) {
//             return AlertDialog(
//               title: const Text('Meus Pedidos'),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Expanded(
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: carrinho.itens.length,
//                         itemBuilder: (context, index) {
//                           final item = carrinho.itens[index];
//                           final totalItem =
//                               item.quantidade * item.produto.preco!;
//                           return ListTile(
//                             title: Text(item.produto.desProduto!),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text('Qtd: ${item.quantidade}'),
//                                 Text(
//                                   'Total: R\$ ${totalItem.toStringAsFixed(2)}',
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           'Status do Pagamento:',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         // Text(
//                         //   carrinho.statusPagamento,
//                         //   style: TextStyle(
//                         //     color: carrinho.statusPagamento == 'Pago'
//                         //         ? Colors.green
//                         //         : Colors.red,
//                         //     fontWeight: FontWeight.bold,
//                         //   ),
//                         // ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () async {
//                     // Salvar os itens no SharedPreferences
//                     await CarrinhoStorage.salvarCarrinho(carrinho.itens);
//                     Navigator.of(context).pop();
//                   },
//                   child: const Text('Fechar e Salvar'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//       child: Text(
//         'Meus pedidos',
//         style: TextStyle(
//           fontSize: 14,
//           color: Colors.blue,
//           decoration: TextDecoration.underline, // efeito de hyperlink
//         ),
//       ),
//     );
//   }
// }

// class MeusPedidosWidget extends StatelessWidget {
//   MeusPedidosWidget({super.key});

//   Future<List<ItemCarrinho>> _buscarPedidosSalvos() async {
//     return await CarrinhoStorage.recuperarCarrinho();
//   }

//   String _statusPagamento = 'Pendente';

//   consultaPagamento(int idInvoice) async {
//     final url = Uri.parse('${Urls.urlApiPagtoAzure}Pix/consultar');

//     try {
//       final body = jsonEncode({
//         "idFilial": GlobalKeys.codFilial,
//         "idInvoicePix": idInvoice.toString(),
//       });

//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: body,
//       );

//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         if (jsonResponse['statusPagamento'] == 'credited' ||
//             jsonResponse['statusPagamento'] == 'paid') {
//           _statusPagamento = 'Pago';
//         } else {
//           _statusPagamento = 'Pendente';
//         }
//       } else {
//         print('Erro ao consultar pagamento: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Erro ao consultar pagamento: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () async {
//         final pedidos = await _buscarPedidosSalvos();
//         await consultaPagamento(GlobalKeys.idInvoice);

//         if (pedidos.isEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Nenhum pedido encontrado')),
//           );
//           return;
//         }

//         showDialog(
//           context: context,
//           builder: (context) {
//             return AlertDialog(
//               title: const Text('Meus Pedidos'),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Expanded(
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: pedidos.length,
//                         itemBuilder: (context, index) {
//                           final item = pedidos[index];
//                           final totalItem =
//                               item.quantidade * item.produto.preco!;
//                           return ListTile(
//                             title: Text(item.produto.desProduto!),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text('Qtd: ${item.quantidade}'),
//                                 Text(
//                                   'Total: R\$ ${totalItem.toStringAsFixed(2)}',
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           'Status do Pagamento:',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         Text(
//                           _statusPagamento,
//                           style: TextStyle(
//                             color:
//                                 _statusPagamento == 'Pago'
//                                     ? Colors.green
//                                     : Colors.red,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('Fechar'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//       child: const Text(
//         'Meus pedidos',
//         style: TextStyle(
//           fontSize: 14,
//           color: Colors.blue,
//           decoration: TextDecoration.underline,
//         ),
//       ),
//     );
//   }
// }

class MeusPedidosWidget extends StatefulWidget {
  const MeusPedidosWidget({super.key});

  @override
  State<MeusPedidosWidget> createState() => _MeusPedidosWidgetState();
}

class _MeusPedidosWidgetState extends State<MeusPedidosWidget> {
  String _statusPagamento = 'Pendente';

  Future<List<ItemCarrinho>> _buscarPedidosSalvos() async {
    return await CarrinhoStorage.recuperarCarrinho();
  }

  Future<void> _consultaPagamento(int idInvoice) async {
    final url = Uri.parse('${Urls.urlApiPagtoAzure}Pix/consultar');

    try {
      final body = jsonEncode({
        "idFilial": GlobalKeys.codFilial,
        "idInvoicePix": idInvoice.toString(),
        "ambiente": GlobalKeys.ambienteNfe,
      });

      final response = await http
          .post(url, headers: {"Content-Type": "application/json"}, body: body)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['statusPagamento'] == 'credited' ||
            jsonResponse['statusPagamento'] == 'paid') {
          _statusPagamento = 'Pago';
        } else {
          _statusPagamento = 'Pendente';
        }
      } else {
        debugPrint('Erro ao consultar pagamento: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao consultar pagamento: $e');
    }
  }

  Future<void> _mostrarPedidos(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: PulsingLogo(
            assetPath: 'images/logodd_clean.png',
            width: 150,
            duration: const Duration(seconds: 1),
          ),
        ),
      ),
    );

    final pedidos = await _buscarPedidosSalvos();
    await _consultaPagamento(GlobalKeys.idInvoice);

    if (!mounted) return;

    Navigator.of(context).pop(); // Fecha o loading

    if (pedidos.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nenhum pedido encontrado')));
      return;
    }

    // // Calcula o valor total dos pedidos
    double totalPedido = pedidos.fold(
      0.0,
      (soma, item) => soma + (item.quantidade * item.produto.preco!),
    );

    // Mostra o dialog com os pedidos
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Meus Pedidos\n'
            'Total: R\$ ${totalPedido.toStringAsFixed(2)}\n'
            'ID Invoice: ${GlobalKeys.idInvoice}',
            style: const TextStyle(fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      final item = pedidos[index];
                      final totalItem = item.quantidade * item.produto.preco!;
                      return ListTile(
                        title: Text(item.produto.desProduto!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Qtd: ${item.quantidade}'),
                            Text('Total: R\$ ${totalItem.toStringAsFixed(2)}'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status do Pagamento:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _statusPagamento,
                      style: TextStyle(
                        color: _statusPagamento == 'Pago'
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // _statusPagamento == 'Pendente'
                    //     ? GlobalKeys.pagtoPIX
                    //         ? ElevatedButton.icon(
                    //           icon: const Icon(Icons.copy),
                    //           label: const Text('COPIA E COLA PIX'),
                    //           onPressed: () {
                    //             Clipboard.setData(
                    //               ClipboardData(text: GlobalKeys.brCode),
                    //             );
                    //             ScaffoldMessenger.of(context).showSnackBar(
                    //               const SnackBar(
                    //                 content: Text('Código PIX copiado!'),
                    //               ),
                    //             );
                    //           },
                    //           style: ElevatedButton.styleFrom(
                    //             padding: const EdgeInsets.symmetric(
                    //               horizontal: 24,
                    //               vertical: 12,
                    //             ),
                    //           ),
                    //         )
                    //         : SizedBox()
                    //     : SizedBox(),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _mostrarPedidos(context),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: Colors.black38,
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 88,
                  child: Text(
                    textAlign: TextAlign.center,
                    AppLocalizations.of(context)!.myOrders,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      // color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
