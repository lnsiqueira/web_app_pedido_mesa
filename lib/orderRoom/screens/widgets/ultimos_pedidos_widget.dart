import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';
import 'package:webapp_pedido_mesa/core/model/quarto_nome_model.dart';
import 'package:webapp_pedido_mesa/l10n/app_localizations.dart';
import 'package:webapp_pedido_mesa/orderRoom/oder_service.dart';
import 'package:webapp_pedido_mesa/services/storage/carrinho_storage.dart';
import 'package:webapp_pedido_mesa/widgets/logo_pulsando.dart';

class UltimosPedidosOrderWidget extends StatefulWidget {
  const UltimosPedidosOrderWidget({super.key});

  @override
  State<UltimosPedidosOrderWidget> createState() =>
      _UltimosPedidosOrderWidgetState();
}

class _UltimosPedidosOrderWidgetState extends State<UltimosPedidosOrderWidget> {
  String _statusPagamento = 'Pendente';

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

    final pedidosDocs = await buscarPedidosFirebase(context);

    if (pedidosDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum pedido encontrado hoje')),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pop(); // Fecha o loading

    if (pedidosDocs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nenhum pedido encontrado')));
      return;
    }
    final quartoNome = Provider.of<QuartoNomeModel>(context, listen: false);

    final String quarto = quartoNome.mesa.trim();
    // // Calcula o valor total dos pedidos
    double totalPedido = pedidosDocs.fold(0.0, (soma, doc) {
      return soma + (doc['vlr_json'] as num).toDouble();
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pedidos quarto $quarto\n',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: pedidosDocs.length,
                itemBuilder: (context, index) {
                  final doc = pedidosDocs[index];
                  final itens = List<Map<String, dynamic>>.from(doc['itens']);
                  final bool pago = doc['IND_PAGO'] == 'FECHADO';

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      title: Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 20,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Comanda ${doc['comanda']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: R\$ ${(doc['vlr_json'] as num).toDouble().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pagamento',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  pago ? 'Pago' : 'Pendente',
                                  style: TextStyle(
                                    color: pago ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      children: itens.map((item) {
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          title: Text(
                            item['nome'],
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            'Qtd: ${item['quantidade']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            'R\$ ${(item['total'] as num).toDouble().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
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
