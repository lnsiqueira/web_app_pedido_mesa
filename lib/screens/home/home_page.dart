import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/controllers/language_controller.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/categorias.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/l10n/app_localizations.dart';
import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';
import 'package:webapp_pedido_mesa/screens/home/categorias_grid.dart';
import 'package:webapp_pedido_mesa/screens/home/grid_buscar_itens.dart';
import 'package:webapp_pedido_mesa/screens/home/search_bar_widget.dart';
import 'package:webapp_pedido_mesa/screens/item/item_page.dart';
import 'package:webapp_pedido_mesa/screens/item/popup_produto.dart';
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
  final TextEditingController _searchController = TextEditingController();

  List<ItemModel> resultadosBusca = [];

  bool modoBusca = false;
  bool isSearching = false;

  Timer? _debounce;
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

  void _adicionarAoCarrinho(ItemModel produto) {
    Provider.of<CarrinhoModel>(context, listen: false).adicionar(produto);
  }

  // Future<void> _buscarProduto(String query) async {
  //   if (query.isEmpty) {
  //     setState(() {
  //       modoBusca = false;
  //       resultadosBusca.clear();
  //     });
  //     return;
  //   }

  //   setState(() {
  //     modoBusca = true;
  //     isSearching = true;
  //   });

  //   final url = Uri.parse(
  //     '${Urls.urlApiAzure}Categorias/produto-by-categoria-filial'
  //     '?idFilial=$codFilial'
  //     '&nomeProduto=$query',
  //   );

  //   try {
  //     final response = await http.get(url);

  //     if (response.statusCode == 200) {
  //       final list = json.decode(response.body) as List;

  //       setState(() {
  //         resultadosBusca = list.map((e) => ItemModel.fromJson(e)).toList();
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Erro busca: $e');
  //   } finally {
  //     setState(() => isSearching = false);
  //   }
  // }
  Future<void> _buscarProduto(String query) async {
    if (query.isEmpty) {
      setState(() {
        modoBusca = false;
        resultadosBusca.clear();
      });
      return;
    }

    setState(() {
      modoBusca = true;
      isSearching = true;
    });

    final url = Uri.parse(
      '${Urls.urlApiAzure}Categorias/produto-by-categoria-filial'
      '?idFilial=$codFilial'
      '&nomeProduto=$query',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;

        // 🔥 base
        final produtos = list.map((e) => ItemModel.fromJson(e)).toList();

        // 🔥 busca preço + obs em paralelo
        final produtosCompletos = await Future.wait(
          produtos.map((p) async {
            final info = await _buscarPrecoProduto(p.plu ?? '');

            return p.copyWith(
              preco: info.preco ?? p.preco,
              obs: info.obs ?? [],
            );
          }),
        );

        if (!mounted) return;

        setState(() {
          resultadosBusca = produtosCompletos;
        });
      }
    } catch (e) {
      debugPrint('Erro busca: $e');
    } finally {
      if (mounted) {
        setState(() => isSearching = false);
      }
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

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _buscarProduto(value);
    });
  }

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
    // final screenWidth = MediaQuery.of(context).size.width;
    // // final itemWidth = screenWidth / 3 - 24;
    // final mesa = context.watch<MesaComandaModel>().mesa;
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
                        if (comanda != null)
                          SearchBarWidget(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            onClear: () {
                              _searchController.clear();
                              _buscarProduto('');
                            },
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: modoBusca
                              ? GridBuscaWidget(
                                  produtos: resultadosBusca,
                                  isLoading: isSearching,
                                  onTap: (produto) {
                                    ProdutoPopup.show(
                                      context,
                                      produto: produto,
                                      onAdd: _adicionarAoCarrinho,
                                    );
                                  },
                                )
                              : GridCategoriasWidget(
                                  categorias: categorias,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const BotaoPagamentoFlutuante(),

            /// 🔴 LOADING OVERLAY (SEMPRE POR CIMA)
            if (isLoading || isSearching)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Container(
                    color: Colors.white.withOpacity(0.6), // leve blur visual
                    child: const Center(
                      child: PulsingLogo(
                        assetPath: 'images/logodd_clean.png',
                        width: 150,
                        duration: const Duration(seconds: 1),
                      ), // seu logo animado
                    ),
                  ),
                ),
              ),
          ],
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
