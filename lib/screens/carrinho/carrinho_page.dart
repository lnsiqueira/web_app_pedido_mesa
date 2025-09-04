import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/screens/pagamento/pagamento_pix_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

class CarrinhoPage extends StatefulWidget {
  const CarrinhoPage({super.key});

  @override
  State<CarrinhoPage> createState() => _CarrinhoPageState();
}

class _CarrinhoPageState extends State<CarrinhoPage> {
  Future<void> _pedirMesaEComanda() async {
    final mesaController = TextEditingController();
    final comandaController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String? _mesa;
    String? _comanda;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Text(
                      'Mesa e Comanda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Campo Mesa
                Text(
                  AppLocalizations.of(context)!.table,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: mesaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Apenas números
                  ],
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterTableNumber,
                    prefixIcon:
                        Icon(Icons.numbers, color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.enterTableNumber;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Campo Comanda
                Text(
                  AppLocalizations.of(context)!.order,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: comandaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Apenas números
                  ],
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterOrderNumber,
                    prefixIcon:
                        Icon(Icons.receipt_long, color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!
                          .pleaseEnterOrderNumber;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final comanda = comandaController.text;

                          var urlBratter = Urls.urlApiBratter;
                          final encodedUrl = Uri.encodeComponent(urlBratter);
                          final url =
                              '${Urls.urlApiAzure}Proxy/ConsultaComanda/?urlBratter=$encodedUrl&tokenBratter=${GlobalKeys.tokenBratter}&idComanda=$comanda';

                          try {
                            final response = await http.get(
                              Uri.parse(url),
                              headers: {
                                'Content-Type': 'application/json',
                                'Accept': 'application/json',
                              },
                            );

                            if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);

                              // verifica se a comanda existe
                              if (data['Id'] != 0 && data['Status'] != null) {
                                // ✅ existe, pode prosseguir
                                Navigator.pop(context, {
                                  'mesa': mesaController.text,
                                  'comanda': comanda,
                                });
                              } else {
                                // ❌ não existe
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Comanda não encontrada."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              // erro de comunicação
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Erro ao consultar comanda: ${response.statusCode}"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Erro: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.confirm),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _mesa = result['mesa'];
        _comanda = result['comanda'];
      });

      final mesaComanda = Provider.of<MesaComandaModel>(
        context,
        listen: false,
      );

      mesaComanda.setMesa(_mesa!);
      mesaComanda.setComanda(_comanda!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = Provider.of<CarrinhoModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Carrinho')),
      body: carrinho.itens.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Seu carrinho está vazio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Adicione itens para continuar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: carrinho.itens.length,
                    itemBuilder: (context, index) {
                      final item = carrinho.itens[index];
                      final totalItem = item.quantidade * item.produto.preco!;
                      final observacoesSelecionadas =
                          item.produto.obs?.where((obs) {
                        // Para observações do tipo 'escolha': modificador 'C' ou 'S'
                        if (obs.tipo == 'escolha') {
                          return obs.modificador == 'C' ||
                              obs.modificador == 'S';
                        }
                        // Para observações do tipo 'texto': modificador 'COM'
                        else if (obs.tipo == 'texto') {
                          return obs.modificador == 'COM';
                        }
                        return false;
                      }).toList();
                      return ListTile(
                        title: Text(item.produto.desProduto!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Qtd: ${item.quantidade}'),
                            Text(
                              'Total: R\$ ${totalItem.toStringAsFixed(2)}',
                            ),
                            if (observacoesSelecionadas != null &&
                                observacoesSelecionadas.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: observacoesSelecionadas.map((obs) {
                                  // Diferencia a exibição baseada no tipo da observação
                                  if (obs.tipo == 'escolha') {
                                    return Text(
                                      "Obs: ${obs.titulo} (${obs.modificador == 'C' ? 'Com' : 'Sem'})",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    );
                                  } else if (obs.tipo == 'texto') {
                                    return Text(
                                      "Obs: ${obs.titulo}",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }).toList(),
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
                      // icon: const Icon(Icons.skip_next),
                      label: const Text('Pagar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: () async {
                        final mesaComanda = Provider.of<MesaComandaModel>(
                            context,
                            listen: false);

                        // 🔹 Verifica se mesa ou comanda estão vazias
                        if (mesaComanda.mesa.isEmpty ||
                            mesaComanda.comanda.isEmpty) {
                          await _pedirMesaEComanda();

                          // Se ainda estiver vazio, sai sem navegar
                          if (mesaComanda.mesa.isEmpty ||
                              mesaComanda.comanda.isEmpty) {
                            return;
                          }
                        }

                        // 🔹 Campos preenchidos → navega para pagamento
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PagamentoPixPage(),
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
