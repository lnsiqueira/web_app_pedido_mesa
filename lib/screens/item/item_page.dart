import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/carrinho_page.dart';

class ItensPage extends StatefulWidget {
  final int idCategoria;

  const ItensPage({super.key, required this.idCategoria});

  @override
  State<ItensPage> createState() => _ItensPageState();
}

class _ItensPageState extends State<ItensPage> {
  List<ItemModel> produtos = [];
  bool isLoading = false;
  //List<Produto> carrinho = [];
  //List<ItemCarrinho> carrinho = [];

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() {
      isLoading = true;
    });

    final url =
        '${Urls.urlApiAzure}/Categorias/categoria-produto-by-filial/${widget.idCategoria}?idFilial=${GlobalKeys.codFilial}';

    try {
      final response = await http.get(Uri.parse(url));
      //http://dd-einsteinfaculdade.ddns.com.br:19974/deolaapi/api/mercadoriafiscal?codigoproduto=249&imagens=false

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // setState(() {
        //   produtos = List<Produto>.from(
        //     data.map((json) => Produto.fromJson(json)),
        //   );

        List<ItemModel> lista = List<ItemModel>.from(
          data.map((json) => ItemModel.fromJson(json)),
        );

        // Agora, para cada produto, buscar o preço
        List<ItemModel> listaComPreco = [];
        for (var p in lista) {
          double? preco = await _buscarPrecoProduto(p.plu!);
          listaComPreco.add(p.copyWith(preco: preco));
        }

        setState(() {
          produtos = listaComPreco;
        });

        // });
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

  Future<double?> _buscarPrecoProduto(String plu) async {
    try {
      var urlBratter = Urls.urlApiBratter;
      final encodedUrl = Uri.encodeComponent(urlBratter);

      final url =
          '${Urls.urlApiAzure}Proxy/mercadoriafiscal?codigoproduto=$plu&imagens=false&urlBratter=${encodedUrl}&tokenBratter=${GlobalKeys.tokenBratter}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return double.tryParse(data['preco'].toString());
      } else {
        print('Erro ao buscar preço do produto $plu: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar preço: $e');
      return null;
    }
  }

  void _adicionarAoCarrinho(ItemModel produto) {
    Provider.of<CarrinhoModel>(context, listen: false).adicionar(produto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itens'),
        actions: [
          Consumer<CarrinhoModel>(
            builder:
                (context, carrinho, _) => Stack(
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: produtos.length,
                itemBuilder: (context, index) {
                  final produto = produtos[index];

                  return ListTile(
                    leading: Icon(Icons.fastfood),
                    title: Text(produto.desProduto!),

                    subtitle: Text(
                      'PLU: ${produto.plu} - Preço: R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                    ),
                    onTap: () {
                      _adicionarAoCarrinho(produto);
                    },
                  );
                },
              ),
    );
  }
}
