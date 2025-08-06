import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';

class ItensPage extends StatefulWidget {
  final int idCategoria;

  const ItensPage({super.key, required this.idCategoria});

  @override
  State<ItensPage> createState() => _ItensPageState();
}

class _ItensPageState extends State<ItensPage> {
  List<Produto> produtos = [];

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    final url =
        '${Urls.urlApiAzure}/Categorias/categoria-produto-by-filial/${widget.idCategoria}?idFilial=${GlobalKeys.codFilial}';

    try {
      final response = await http.get(Uri.parse(url));
      //http://dd-einsteinfaculdade.ddns.com.br:19974/deolaapi/api/mercadoriafiscal?codigoproduto=249&imagens=false

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          produtos = List<Produto>.from(
            data.map((json) => Produto.fromJson(json)),
          );
        });
      } else {
        print('Erro ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itens')),
      body: ListView.builder(
        itemCount: produtos.length,
        itemBuilder: (context, index) {
          final produto = produtos[index];
          return ListTile(
            leading: Icon(Icons.fastfood),
            title: Text(produto.desProduto),
            subtitle: Text('PLU: ${produto.plu}'),
          );
        },
      ),
    );
  }
}
