import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/atualizacao/atualizacao_automatica.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/screens/item/sugestoes.dart';
import 'package:webapp_pedido_mesa/services/cardapio_service.dart';
import 'package:webapp_pedido_mesa/widgets/sobre_bakeryfood.dart';
import 'package:webapp_pedido_mesa/screens/item/produto_popup.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/categorias.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';
import 'package:webapp_pedido_mesa/screens/home/categorias_grid.dart';
import 'package:webapp_pedido_mesa/screens/home/grid_buscar_itens.dart';
import 'package:webapp_pedido_mesa/screens/home/search_bar_widget.dart';
import 'package:webapp_pedido_mesa/screens/item/item_page.dart';
import 'package:webapp_pedido_mesa/screens/item/popup_produto.dart';
import 'package:webapp_pedido_mesa/widgets/botao_chamar_garcom.dart';
import 'package:webapp_pedido_mesa/widgets/meus_pedidos.dart';
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
    // a comanda é pedida só no fim, ao enviar o pedido (carrinho)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarCategorias();
      // já busca os grupos de produtos (ficam em cache): ao abrir a
      // categoria, os produtos aparecem agrupados sem esperar
      GrupoProdutos.todos();
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
  /// Minúsculas e sem acento ("Pão" -> "pao")
  static String _normalizar(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = de.indexOf(ch);
      b.write(i >= 0 ? para[i] : ch);
    }
    return b.toString();
  }

  static bool _casa(List<String> palavras, String nome) {
    final doNome = nome.split(RegExp(r'[^a-z0-9]+'));
    return palavras.every((b) => doNome.any((w) => w.startsWith(b)));
  }

  /// Busca no cardápio que está aparecendo (mesmas categorias e filial),
  /// sem ligar para acentos: "pao de quei" acha "Pão de Queijo"
  Future<void> _buscarProduto(String query) async {
    final termo = _normalizar(query.trim());
    if (termo.isEmpty) {
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
    try {
      final listas = await Future.wait(
          categorias.map((c) => CardapioService.produtosDe(c.id)));
      final palavras = termo.split(RegExp(r'\s+'));
      final vistos = <String>{};
      final achados = [
        for (final p in listas.expand((l) => l))
          // cada palavra buscada é o começo de uma palavra do nome
          if (_casa(palavras, _normalizar(p.desProduto ?? '')) &&
              vistos.add(p.plu ?? ''))
            p,
      ];
      final completos =
          await Future.wait(achados.take(30).map(Complementos.completar));
      if (!mounted || _searchController.text.trim() != query.trim()) return;
      setState(() {
        resultadosBusca = completos.where((p) => p.preco != null).toList();
      });
    } catch (e) {
      debugPrint('Erro busca: $e');
    } finally {
      if (mounted) setState(() => isSearching = false);
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

    try {
      final lista = await CardapioService.categorias();
      if (!mounted) return;
      setState(() {
        categorias = lista;
      });
      // sugestões (bebida / sobremesa) já carregam em segundo plano
      preCarregarSugestoes();
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
    // final screenWidth = MediaQuery.of(context).size.width;
    // // final itemWidth = screenWidth / 3 - 24;
    // final mesa = context.watch<MesaComandaModel>().mesa;
    final comanda = context.watch<MesaComandaModel>().comanda;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            ConexaoWrapper(
              // a barra de cima some ao rolar para baixo e volta ao subir
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 60,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // LOGO
                        Image.asset('images/logodd_clean.png', height: 40),

                        const SizedBox(width: 8),
                        // CHAMAR GARÇOM + MEUS PEDIDOS + CARRINHO (encolhe em
                        // tela estreita em vez de estourar)
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              children: [
                                const BotaoChamarGarcom(),
                                const SizedBox(width: 6),
                                const MeusPedidosWidget(),

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
                                              builder: (_) =>
                                                  const CarrinhoPage(),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverToBoxAdapter(
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
                                    onTap: (produto) =>
                                        abrirProdutoPopup(context, produto),
                                  )
                                : GridCategoriasWidget(
                                    categorias: categorias,
                                  ),
                          ),
                          if (!modoBusca && categorias.isNotEmpty)
                            // toque: "Sobre a BakeryFood"
                            Center(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => mostrarSobreBakeryFood(context),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                  child: Text.rich(
                                    TextSpan(children: [
                                      const TextSpan(text: 'Desenvolvido por '),
                                      TextSpan(
                                        text: 'BakeryFood',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      // versão publicada, discreta (confere
                                      // se o celular já está na nova)
                                      if (versaoDoApp.isNotEmpty)
                                        TextSpan(
                                          text: ' · versão $numeroDaVersao',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.grey.shade400,
                                          ),
                                        )
                                      else
                                        const TextSpan(text: ' · 2026'),
                                    ]),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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
}
