import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/pagamento/pagamento_order_page.dart';
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
        appBar: AppBar(title: const Text('')),
        body: carrinho.itens.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: 0.8,
                      child: Image.asset(
                        'images/empty_cart.png',
                        width: 160,
                        height: 160,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.cartEmpty,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)!.addItem,
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
                  /// Lista de itens
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: carrinho.itens.length,
                      itemBuilder: (context, index) {
                        final item = carrinho.itens[index];
                        final totalItem = item.quantidade * item.produto.preco!;
                        final observacoesSelecionadas =
                            item.produto.obs?.where((obs) {
                          if (obs.tipo == 'escolha') {
                            return obs.modificador == 'C' ||
                                obs.modificador == 'S';
                          } else if (obs.tipo == 'texto') {
                            return obs.modificador == 'COM';
                          }
                          return false;
                        }).toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Nome + total do item
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.produto.desProduto!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'R\$ ${totalItem.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                /// Observações
                                if (observacoesSelecionadas != null &&
                                    observacoesSelecionadas.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        observacoesSelecionadas.map((obs) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          obs.tipo == 'escolha'
                                              ? '• ${obs.titulo} (${obs.modificador == 'C' ? 'Com' : 'Sem'})'
                                              : '• ${obs.titulo}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                const SizedBox(height: 12),
                                Text(
                                    'qtd disponivel: ${item.produto.quantidadeDisponivel.toString()}'),
                                Text('id : ${item.produto.id.toString()}'),

                                /// Quantidade
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Qtd: ${item.quantidade}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove,
                                                size: 18),
                                            onPressed: () {
                                              if (item.quantidade > 1) {
                                                item.quantidade--;
                                              } else {
                                                carrinho.remover(item.produto);
                                              }
                                              carrinho.notifyListeners();
                                            },
                                          ),
                                          Text(
                                            item.quantidade.toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.add, size: 18),
                                            onPressed: () {
                                              carrinho.adicionar(item.produto);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  /// Bottom fixo: total + pagar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22), // 🔥 padrão iFood/Uber
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -8), // sombra só pra cima
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          /// Total geral
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'R\$ ${carrinho.totalGeral.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// Botão pagar
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () async {
                                if (isQuartoENome) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PagamentoOrderPage(),
                                    ),
                                  );
                                  return;
                                }

                                final mesaComanda =
                                    Provider.of<MesaComandaModel>(context,
                                        listen: false);

                                if (mesaComanda.mesa.isEmpty ||
                                    mesaComanda.comanda.isEmpty) {
                                  await _pedirMesaEComanda();
                                  if (mesaComanda.mesa.isEmpty ||
                                      mesaComanda.comanda.isEmpty) return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PagamentoPixPage(),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withOpacity(0.9),
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 36,
                                  vertical: 16,
                                ),
                                child: const Text(
                                  'Pagar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
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
              ));
  }
}
