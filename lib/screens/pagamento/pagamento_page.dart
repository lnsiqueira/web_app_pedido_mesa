import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webapp_pedido_mesa/core/model/pedido_model.dart';

class PagamentoPage extends StatefulWidget {
  const PagamentoPage({Key? key}) : super(key: key);

  @override
  State<PagamentoPage> createState() => _PagamentoPageState();
}

class _PagamentoPageState extends State<PagamentoPage> {
  bool _processandoPagamento = false;
  bool _pagamentoRealizado = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid uuid = const Uuid();

  void _confirmarPagamento() async {
    setState(() {
      _processandoPagamento = true;
    });

    // Simulando tempo de processamento
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _processandoPagamento = false;
      _pagamentoRealizado = true;
    });

    var idPedido = await uploadPedido();

    // Mostra alerta de sucesso
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Pagamento aprovado'),
            content: Text(
              'Aguarde que seu pedido será entregue na mesa.\nPedido ID: $idPedido',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 1- ENVIAR API BRATTER
                  // Aqui você pode chamar a API para registrar o pagamento
                  // e enviar os dados necessários, como mesa, comanda, etc.
                  // 2- DAR BAIXA NA COMANDA BRATTER
                  // 3- GRAVAR NO FIREBASE, tabela: pedidos add obs:  pedido_mesa
                  // 4- CHAMAR API XML

                  Navigator.of(context).pop(); // fecha o dialog
                  // Navigator.of(context).pop(); // volta para tela anterior

                  // Limpa o carrinho via Provider
                  final carrinho = Provider.of<CarrinhoModel>(
                    context,
                    listen: false,
                  );
                  carrinho.limpar();
                  Provider.of<MesaComandaModel>(
                    context,
                    listen: false,
                  ).limpar();

                  // Fecha o diálogo e volta para a tela inicial
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _confirmarPagamentoOld() async {
    setState(() {
      _processandoPagamento = true;
    });

    // Simulando tempo de processamento
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _processandoPagamento = false;
      _pagamentoRealizado = true;
    });

    var idPedido = await uploadPedido();

    // Mostra alerta de sucesso
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Pagamento aprovado'),
            content: Text(
              'Aguarde que seu pedido será entregue na mesa.\nPedido ID: $idPedido',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // 1- ENVIAR API BRATTER
                  // Aqui você pode chamar a API para registrar o pagamento
                  // e enviar os dados necessários, como mesa, comanda, etc.
                  // 2- DAR BAIXA NA COMANDA BRATTER
                  // 3- GRAVAR NO FIREBASE, tabela: pedidos add obs:  pedido_mesa
                  // 4- CHAMAR API XML

                  Navigator.of(context).pop(); // fecha o dialog
                  // Navigator.of(context).pop(); // volta para tela anterior

                  // Limpa o carrinho via Provider
                  final carrinho = Provider.of<CarrinhoModel>(
                    context,
                    listen: false,
                  );
                  carrinho.limpar();
                  Provider.of<MesaComandaModel>(
                    context,
                    listen: false,
                  ).limpar();

                  // Fecha o diálogo e volta para a tela inicial
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<String> uploadPedido() async {
    final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
    final mesaComanda = Provider.of<MesaComandaModel>(context, listen: false);

    try {
      List<ItemModel> itensFinais = [];

      Map<String, ItemModel> consolidados = {};

      for (var item in carrinho.itens) {
        final nome = item.produto.desProduto!.trim().toLowerCase();
        final qtd = item.quantidade;

        if (consolidados.containsKey(nome)) {
          consolidados[nome]!.quantidade =
              (consolidados[nome]!.quantidade ?? 0) +
              (item.quantidade > 0 ? item.quantidade : 1);
        } else {
          consolidados[nome] = ItemModel(
            desProduto: nome,
            preco:
                item.produto.preco! *
                (item.quantidade > 0 ? item.quantidade : 1),
            detalhes: null,
            tipoProduto: item.produto.desCategoria ?? "",
            peso: null,
            produtoId: item.produto.plu,
            quantidade: item.quantidade > 0 ? item.quantidade : 1,
            imageUrl: null,
            discountpreco: null,
            codigoBarras: null,
            categoria: item.produto.desCategoria ?? "",
            pesavel: false,
          );
        }
        itensFinais = consolidados.values.toList();
      }

      String pedidoId = uuid.v4();
      PedidoModel pedido = PedidoModel(
        pedidoId: pedidoId,
        codEmpresa: '1',
        codFilial: GlobalKeys.codFilial,
        dataHoraPedido: Timestamp.now(),
        deviceToken: "",
        itens: itensFinais,
        total: carrinho.totalGeral,
        pedidoPago: true,
        comanda: mesaComanda.comanda,
        serieNfe: GlobalKeys.serieNfe,
        ambiente: GlobalKeys.ambienteNfe,
        vlrDescontoEmbalagem: 0,
        pedidoMesa: true,
        mesa: mesaComanda.mesa,
      );

      await _firestore.collection('teste').doc(pedidoId).set(pedido.toMap());

      return pedidoId;
    } catch (e) {
      print("Erro ao fazer upload do pedido: $e");
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento via PIX')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child:
              _processandoPagamento
                  ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processando pagamento...'),
                    ],
                  )
                  : _pagamentoRealizado
                  ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total a pagar via PIX:',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'R\$ ${carrinho.totalGeral.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.pix),
                        label: const Text('Confirmar Pagamento'),
                        onPressed: _confirmarPagamento,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
