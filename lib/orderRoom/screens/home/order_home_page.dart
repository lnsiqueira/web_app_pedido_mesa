import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/admin/services/cardapio_admin_service.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/controllers/language_controller.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/categorias.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/model/quarto_nome_model.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/home/produtos_order_page.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/pagamento/senha_comanda_page.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/widgets/bottom_carrinho.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/widgets/popup_quarto_nome.dart';
import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/orderRoom/screens/widgets/ultimos_pedidos_widget.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';
import 'package:webapp_pedido_mesa/screens/home/home_page.dart';
import 'package:webapp_pedido_mesa/widgets/app_footer.dart';
import 'package:webapp_pedido_mesa/widgets/logo_pulsando.dart';

class OrderHomePage extends StatefulWidget {
  const OrderHomePage({super.key});

  @override
  State<OrderHomePage> createState() => _OrderHomePageState();
}

class _OrderHomePageState extends State<OrderHomePage> {
  String? _quarto;
  String? _nome;
  bool isLoading = false;

  /// agora guardamos categoria + produtos
  List<Map<String, dynamic>> categorias = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => SenhaComandaPage(
      //       senha: 42,
      //       isPagamento: true,
      //     ),
      //   ),
      // );
      _pedirQuartoENome();
      _carregarProdutos();
    });
  }

  Future<void> _pedirQuartoENome() async {
    final quartoController = TextEditingController();
    final nomeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopupQuartoNome(
        formKey: formKey,
        quartoController: quartoController,
        nomeController: nomeController,
      ),
    );

    if (result != null) {
      final quartoNome = Provider.of<QuartoNomeModel>(
        context,
        listen: false,
      );

      quartoNome.setMesa(result['quarto']!);
      quartoNome.setComanda(result['nome']!);

      // _carregarProdutos();
    }
  }

  Future<void> _carregarProdutos({
    // String filialId = '1768831340259',
    String? data,
  }) async {
    setState(() => isLoading = true);

    final dataFormatada = data ?? dataHojeFormatada();

    final url = Uri.parse(
      '${Urls.urlApiAzureCardapioDiario}/CardapioHospital/cardapio-diario'
      // '?filialId=$filialId'
      '?filialId=$codFilial'
      '&data=$dataFormatada',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        setState(() {
          categorias = List<Map<String, dynamic>>.from(
            jsonBody['cardapio'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar categorias: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);

    return Scaffold(
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
                  UltimosPedidosOrderWidget(),

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
      body: isLoading
          ? const Center(
              child: PulsingLogo(
                assetPath: 'images/logodd_clean.png',
                duration: Duration(seconds: 1),
              ),
              //  CircularProgressIndicator()
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180, // controla tamanho do card
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1, // deixa mais compacto
              ),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];

                return GestureDetector(
                  onTap: () {
                    final produtosJson = categoria['produtos'] as List<dynamic>;

                    final produtos = produtosJson
                        .map((e) => ItemModel.fromJson(e))
                        .where((p) => p.ativo == true)
                        .toList();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProdutosCategoriaPage(
                          titulo: categoria['desCategoria'],
                          produtos: produtos,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            categoria['imagemCategoria'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade300),
                          ),

                          // Overlay mais suave estilo iFood
                          Container(
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

                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                categoria['desCategoria'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14, // menor que antes
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
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
      // cards menores
      // : GridView.builder(
      //     padding: const EdgeInsets.all(16),
      //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      //       crossAxisCount: 2,
      //       crossAxisSpacing: 16,
      //       mainAxisSpacing: 16,
      //       childAspectRatio: 0.9,
      //     ),
      //     itemCount: categorias.length,
      //     itemBuilder: (context, index) {
      //       final categoria = categorias[index];

      //       return GestureDetector(
      //         onTap: () {
      //           final produtosJson = categoria['produtos'] as List<dynamic>;

      //           final produtos = produtosJson
      //               .map((e) => ItemModel.fromJson(e))
      //               .where((p) => p.ativo == true)
      //               .toList();

      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //               builder: (_) => ProdutosCategoriaPage(
      //                 titulo: categoria['desCategoria'],
      //                 produtos: produtos,
      //               ),
      //             ),
      //           );
      //         },
      //         child: ClipRRect(
      //           borderRadius: BorderRadius.circular(16),
      //           child: Stack(
      //             fit: StackFit.expand,
      //             children: [
      //               Image.network(
      //                 categoria['imagemCategoria'] ?? '',
      //                 fit: BoxFit.cover,
      //                 errorBuilder: (_, __, ___) =>
      //                     Container(color: Colors.grey.shade300),
      //               ),
      //               Container(
      //                 decoration: BoxDecoration(
      //                   gradient: LinearGradient(
      //                     begin: Alignment.bottomCenter,
      //                     end: Alignment.topCenter,
      //                     colors: [
      //                       Colors.black.withOpacity(0.65),
      //                       Colors.transparent,
      //                     ],
      //                   ),
      //                 ),
      //               ),
      //               Align(
      //                 alignment: Alignment.bottomLeft,
      //                 child: Padding(
      //                   padding: const EdgeInsets.all(12),
      //                   child: Text(
      //                     categoria['desCategoria'],
      //                     style: const TextStyle(
      //                       color: Colors.white,
      //                       fontSize: 18,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                   ),
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //       );
      //     },
      //   ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          BottomCarrinhoBar(),
          Divider(),
          AppFooter(),
        ],
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
