import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/controllers/language_controller.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/categorias.dart';
import 'package:webapp_pedido_mesa/l10n/app_localizations.dart';
import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';
import 'package:webapp_pedido_mesa/screens/item/item_page.dart';
import 'package:webapp_pedido_mesa/services/storage/carrinho_storage.dart';
import 'package:webapp_pedido_mesa/widgets/botao_pagamento_flutuante.dart';
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
  String? _comanda;

  List<Categoria> categorias = [];

  bool isLoading = false;

  // 🔥 controla se popup já está aberto
  bool _popupAberto = false;

  @override
  void initState() {
    super.initState();

    // 🔥 abre só depois da tela carregar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pedirMesaEComanda();
    });
  }

  Future<void> _pedirMesaEComanda() async {
    // 🔥 impede empilhar popup
    if (_popupAberto) return;

    _popupAberto = true;

    final mesaController = TextEditingController();

    final comandaController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopupMesaComanda(
        formKey: formKey,
        mesaController: mesaController,
        comandaController: comandaController,
      ),
    );

    // 🔥 libera novamente
    _popupAberto = false;

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _comanda = result['comanda'];
      });

      final mesaComanda = Provider.of<MesaComandaModel>(
        context,
        listen: false,
      );

      mesaComanda.setComanda(_comanda!);

      _carregarCategorias();
    }
  }

  // Future<void> _carregarCategorias() async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   const url =
  //       '${Urls.urlApiAzure}/Categorias/categoria-by-filial/${GlobalKeys.codFilial}';
  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = json.decode(response.body);
  //       setState(() {
  //         categorias = data.map((e) => Categoria.fromJson(e)).toList();
  //       });
  //     } else {
  //       print('Erro ao carregar categorias: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Erro: $e');
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  Future<void> _carregarCategorias() async {
    setState(() {
      isLoading = true;
    });

    var url = '${Urls.urlApiAzure}/Categorias/categoria-by-filial/$codFilial';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final agora = TimeOfDay.now();

        final categoriasFiltradas =
            data.map((e) => Categoria.fromJson(e)).where((categoria) {
          final inicio = categoria.horaInicio;
          final fim = categoria.horaFim;

          // Sem horário = sempre disponível
          if (inicio == null || fim == null) {
            return true;
          }

          final horaInicio = _parseHorario(inicio);
          final horaFim = _parseHorario(fim);

          final agoraMin = agora.hour * 60 + agora.minute;

          final inicioMin = horaInicio.hour * 60 + horaInicio.minute;

          final fimMin = horaFim.hour * 60 + horaFim.minute;

          // Horário normal (08h -> 18h)
          if (inicioMin <= fimMin) {
            return agoraMin >= inicioMin && agoraMin <= fimMin;
          }

          // Horário virando madrugada
          // Ex: 18h -> 02h
          return agoraMin >= inicioMin || agoraMin <= fimMin;
        }).toList();

        setState(() {
          categorias = categoriasFiltradas;
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

  TimeOfDay _parseHorario(String hora) {
    final partes = hora.split(':');

    return TimeOfDay(
      hour: int.parse(partes[0]),
      minute: int.parse(partes[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // final itemWidth = screenWidth / 3 - 24;
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
        body: Stack(
          children: [
            ConexaoWrapper(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        isLoading
                            ? SizedBox(
                                height: constraints.maxHeight * 0.7,
                                child: Center(
                                  child: PulsingLogo(
                                    assetPath: 'images/logodd_clean.png',
                                    duration: const Duration(seconds: 1),
                                  ),
                                ),
                              )
                            : const SizedBox(height: 20),

                        /// GRID DE CATEGORIAS
                        if (comanda != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.92,
                              ),
                              itemCount: categorias.length,
                              itemBuilder: (context, index) {
                                final categoria = categorias[index];

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ItensPage(
                                          nomeCategoria: categoria.desCategoria,
                                          idCategoria: categoria.id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Hero(
                                    tag: categoria.id,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.12),
                                            blurRadius: 14,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            /// IMAGEM
                                            Image.network(
                                              categoria.imagem,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) {
                                                return Container(
                                                  color: Colors.grey.shade300,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.fastfood_rounded,
                                                      size: 46,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),

                                            /// OVERLAY
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin:
                                                        Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    colors: [
                                                      Colors.black
                                                          .withOpacity(0.82),
                                                      Colors.black
                                                          .withOpacity(0.18),
                                                      Colors.transparent,
                                                    ],
                                                    stops: const [0.0, 0.55, 1],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            /// BRILHO
                                            Positioned(
                                              top: -20,
                                              right: -20,
                                              child: Container(
                                                width: 90,
                                                height: 90,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white
                                                      .withOpacity(0.10),
                                                ),
                                              ),
                                            ),

                                            /// TEXTO
                                            Positioned(
                                              left: 16,
                                              right: 16,
                                              bottom: 16,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    categoria.desCategoria,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 19,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      height: 1.15,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.18),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30),
                                                      border: Border.all(
                                                        color: Colors.white
                                                            .withOpacity(0.18),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: const [
                                                        Text(
                                                          'Ver itens',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        SizedBox(width: 6),
                                                        Icon(
                                                          Icons
                                                              .arrow_forward_ios_rounded,
                                                          color: Colors.white,
                                                          size: 12,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        /// POPUP COMANDA
                        Consumer<MesaComandaModel>(
                          builder: (context, comanda, _) {
                            if (comanda.comanda == '') {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _pedirMesaEComanda();
                              });

                              return SizedBox(
                                height: constraints.maxHeight / 1.2,
                                child: const Center(
                                  child: PulsingLogo(
                                    assetPath: 'images/logodd_clean.png',
                                    width: 150,
                                    duration: Duration(seconds: 1),
                                  ),
                                ),
                              );
                            }

                            return const SizedBox();
                          },
                        ),

                        // const SizedBox(height: 24),

                        // /// FOOTER
                        // const Divider(height: 1, thickness: 1),

                        // Padding(
                        //   padding: const EdgeInsets.symmetric(vertical: 12.0),
                        //   child: Text(
                        //     '© ${DateTime.now().year} BakeryFood. Todos os direitos reservados. Version: 1.2.0',
                        //     style: const TextStyle(
                        //       fontSize: 12,
                        //       color: Colors.grey,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// BOTÃO FLUTUANTE
            const BotaoPagamentoFlutuante(),
          ],
        ),
        // bottomNavigationBar: Consumer<CarrinhoModel>(
        //   builder: (context, carrinho, _) {
        //     if (carrinho.totalItens == 0) return const SizedBox.shrink();

        //     return Padding(
        //       padding: const EdgeInsets.all(12.0),
        //       child: ElevatedButton(
        //         style: ElevatedButton.styleFrom(
        //           padding: const EdgeInsets.symmetric(vertical: 16),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(12),
        //           ),
        //         ),
        //         onPressed: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (_) => const CarrinhoPage(),
        //             ),
        //           );
        //         },
        //         child: Text(
        //           "Prosseguir (${carrinho.totalItens} itens)",
        //           style: const TextStyle(fontSize: 18),
        //         ),
        //       ),
        //     );
        //   },
        // ),
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
        "idFilial": codFilial,
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.shade100,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 15,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.myOrders,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
