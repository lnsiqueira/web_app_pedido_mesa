import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/screens/pagamento/pagamento_page.dart';
import 'package:webapp_pedido_mesa/screens/pagamento/pagamento_pix_page.dart';

class CarrinhoPage extends StatelessWidget {
  const CarrinhoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final carrinho = Provider.of<CarrinhoModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Carrinho')),
      body:
          carrinho.itens.isEmpty
              ? const Center(child: Text('Carrinho vazio'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: carrinho.itens.length,
                      itemBuilder: (context, index) {
                        final item = carrinho.itens[index];
                        final totalItem = item.quantidade * item.produto.preco!;
                        return ListTile(
                          title: Text(item.produto.desProduto!),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Qtd: ${item.quantidade}'),
                              Text(
                                'Total: R\$ ${totalItem.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  // carrinho.remover(item.produto);
                                  if (item.quantidade > 1) {
                                    item.quantidade--;
                                  } else {
                                    carrinho.remover(item.produto);
                                  }
                                  carrinho
                                      .notifyListeners(); // para atualizar a UI
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  carrinho.adicionar(item.produto);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total Geral: R\$ ${carrinho.totalGeral.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment),
                        label: const Text('Pagar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        onPressed: () {
                          //LER Mesas e Comandas
                          // final mesa = context.watch<MesaComandaModel>().mesa;
                          // final comanda =
                          //     context.watch<MesaComandaModel>().comanda;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PagamentoPixPage(),
                              //  PagamentoPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );

    // return Scaffold(
    //   appBar: AppBar(title: const Text('Carrinho')),
    //   body:
    //       carrinho.itens.isEmpty
    //           ? const Center(child: Text('Carrinho vazio'))
    //           : ListView.builder(
    //             itemCount: carrinho.itens.length,
    //             itemBuilder: (context, index) {
    //               final item = carrinho.itens[index];
    //               return ListTile(
    //                 title: Text(item.produto.desProduto),
    //                 subtitle: Text('Qtd: ${item.quantidade}'),
    //                 trailing: IconButton(
    //                   icon: const Icon(Icons.delete),
    //                   onPressed: () {
    //                     carrinho.remover(item.produto);
    //                   },
    //                 ),
    //               );
    //             },
    //           ),
    // );
  }
}
