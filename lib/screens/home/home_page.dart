import 'dart:convert';
import 'package:flutter/material.dart';
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

    // Dialog da mesa
    final mesaResult = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.enterTableNumber),
            content: TextField(
              controller: mesaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.table,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, mesaController.text),
                child: Text(AppLocalizations.of(context)!.continueText),
              ),
            ],
          ),
    );

    if (mesaResult != null && mesaResult.isNotEmpty) {
      final comandaResult = await showDialog<String>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.enterOrderNumber),
              content: TextField(
                controller: comandaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.order,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.pop(context, comandaController.text),
                  child: Text(AppLocalizations.of(context)!.continueText),
                ),
              ],
            ),
      );

      if (comandaResult != null && comandaResult.isNotEmpty) {
        setState(() {
          _mesa = mesaResult;
          _comanda = comandaResult;
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
                Image.asset('images/logodd.png', height: 40),

                // TÍTULO
                // const Expanded(
                //   child: Center(
                //     child: Text(
                //       'Escolha seus produtos',
                //       style: TextStyle(fontSize: 18),
                //     ),
                //   ),
                // ),

                // FLAGS + CARRINHO
                Row(
                  children: [
                    _buildFlag('images/br.png', 'pt', languageController),
                    const SizedBox(width: 6),
                    _buildFlag('images/en.png', 'en', languageController),
                    const SizedBox(width: 6),
                    _buildFlag('images/es.png', 'es', languageController),
                    const SizedBox(width: 12),
                    MeusPedidosWidget(),
                    // Text(
                    //   'Meus pedidos',
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     color: const Color.fromARGB(255, 93, 71, 41),
                    //   ),
                    // ),
                    const SizedBox(width: 12),
                    // Carrinho com badge
                    Consumer<CarrinhoModel>(
                      builder:
                          (context, carrinho, _) => Stack(
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
            builder:
                (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Escolha seus produtos',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: ElevatedButton(
                              onPressed: _pedirMesaEComanda,
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.placeYourOrder.toUpperCase(),
                              ),
                            ),
                          ),
                          isLoading
                              ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: const CircularProgressIndicator(),
                              )
                              : SizedBox(),

                          const SizedBox(height: 40),
                          if (mesa != null && comanda != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context)!.table}: $mesa',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    '${AppLocalizations.of(context)!.order}: $comanda',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children:
                                        categorias.map((categoria) {
                                          return SizedBox(
                                            width: itemWidth.clamp(100, 200),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) => ItensPage(
                                                          idCategoria:
                                                              categoria.id,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      categoria.imagem,
                                                      height: 80,
                                                      width: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.broken_image,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: Text(
                                                      categoria.desCategoria,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          const Divider(height: 1, thickness: 1),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              '© 2025 BakeryFood. Todos os direitos reservados.',
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
      ),
    );
  }

  Widget _buildFlag(String path, String lang, LanguageController controller) {
    return InkWell(
      onTap: () {
        controller.changeLanguage(lang);
      },
      child: Image.asset(path, width: 34),
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
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

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
    // Mostra loading enquanto carrega
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
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

    // Calcula o valor total dos pedidos
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
                        color:
                            _statusPagamento == 'Pago'
                                ? Colors.green
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    return GestureDetector(
      onTap: () => _mostrarPedidos(context),
      child: const Text(
        'Meus pedidos',
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
