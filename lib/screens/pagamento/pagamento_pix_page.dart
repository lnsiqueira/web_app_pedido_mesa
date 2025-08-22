import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/core/model/pedido_model.dart';
import 'package:webapp_pedido_mesa/services/nfce/nfce_service.dart';

// ignore: deprecated_member_use
import 'dart:html' as html; // para abrir no browser

class PagamentoPixPage extends StatefulWidget {
  const PagamentoPixPage({super.key});

  @override
  State<PagamentoPixPage> createState() => _PagamentoPixPageState();
}

class _PagamentoPixPageState extends State<PagamentoPixPage> {
  bool _processandoPagamento = false;
  bool _pagamentoRealizado = false;
  bool _notaGerada = false;
  bool _ErroGeracaoNF = false;
  String? _qrCodeBase64;
  int? _idInvoice;
  String? _brCode;
  int _tempoRestante = 180; // 60 segundos para expirar
  Timer? _timer;
  Timer? _pollingTimer;
  String? formatted;
  String valorEmCentavos = '';
  bool _consultandoPagamento = false;
  String? _mensagemStatus;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid uuid = const Uuid();

  @override
  void initState() {
    final now = DateTime.now(); // Data e hora atuais
    final future = now.add(Duration(minutes: 40)); // Soma 40 minutos

    formatted = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(future);
    print(formatted);
    final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
    print(carrinho.totalGeral.toStringAsFixed(2));
    valorEmCentavos = carrinho.totalGeral
        .toStringAsFixed(2)
        .replaceAll('.', '');

    print(valorEmCentavos);
    super.initState();
  }

  Map<String, dynamic> _pixRequestBody() => {
    "descricaoFilial": GlobalKeys.descricaoFilial,
    "idFilial": GlobalKeys.codFilial,
    "idEmpresa": GlobalKeys.codEmpresa,
    "descricaoEmpresa": GlobalKeys.descricaoEmpresa,
    "ambiente": GlobalKeys.ambienteNfe,
    "valor": valorEmCentavos,
    "tipo_transacao": "pixCashin",
    "vencimento": formatted, // "2025-08-18T22:50:00",
    "descricao": "Descrição da cobrança...",
    "texto_instrucao": "Instruções da cobrança...",
    "identificador_externo": null,
    "identificador_movimento": " ",
    "enviar_qr_code": true,
    "cliente": {
      "nome": "Maria Eduarda",
      "tipo_documento": "cpf",
      "numero_documento": "255.539.850-30",
      "e-mail": "maria.eduarda@email.com.br",
    },
    "split": [
      {
        "tipo": "percentual",
        "valor": "0.70",
        "conta": "89392367-30d4-11f0-a96f-42010a400013",
      },
      {
        "tipo": "valor",
        "valor": "0.40",
        "conta": "89392367-30d4-11f0-a96f-42010a400013",
      },
    ],
  };
  Future<void> _simularPagamentoPix() async {
    final url = Uri.parse('${Urls.urlApiPagtoAzure}Pix/simular_baixa');

    try {
      Map<String, dynamic> _pixRequestBody() => {
        "id": _idInvoice,
        "idFilial": GlobalKeys.codFilial,
        "tipoTransacao": "pixCashin",

        "pix": {
          "pagamento": {
            "valor": "string",
            "pagador": {"id": "string", "nome": "string"},
          },
        },
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(_pixRequestBody()),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data']['data'];
        } else {
          _showErro(
            'Falha ao simular baixa do PIX: ${jsonResponse['mensagem']}',
          );
        }
      } else {
        _showErro('Erro na API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErro('Erro ao chamar API: $e');
    } finally {}
  }

  Future<void> _gerarPix() async {
    setState(() {
      _processandoPagamento = true;
      _pagamentoRealizado = false;
      _tempoRestante = 180;
    });

    final url = Uri.parse('${Urls.urlApiPagtoAzure}Pix/gerar');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(_pixRequestBody()),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data']['data'];
          setState(() {
            _qrCodeBase64 = data['qrcode'];
            _idInvoice = data['id_invoice_pix'];
            GlobalKeys.idInvoice = _idInvoice!;
            _brCode = data['brcode'];
          });

          // Inicia contador regressivo
          _iniciarContador();

          // Espera 10s e começa o polling a cada 3s
          //10
          Future.delayed(const Duration(seconds: 10), () {
            if (!mounted) return;
            _iniciarPolling();
          });
        } else {
          _showErro('Falha ao gerar PIX: ${jsonResponse['mensagem']}');
        }
      } else {
        _showErro('Erro na API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErro('Erro ao chamar API: $e');
    } finally {
      setState(() {
        _processandoPagamento = false;
      });
    }
  }

  void _iniciarContador() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      //  _timer = Timer.periodic(const Duration(seconds: 1), (timer)   {
      if (_tempoRestante > 0) {
        setState(() {
          _tempoRestante--;
        });
      } else {
        timer.cancel();
        _pollingTimer?.cancel();
        _showErro('Pagamento não concluído no tempo limite.');

        // Espera 15 segundos antes da checagem final
        if (!mounted) return;
        await Future.delayed(const Duration(seconds: 15));

        // Checa pagamento novamente
        await _consultarPagamento(_idInvoice!);

        if (!_pagamentoRealizado) {
          // Pagamento não realizado -> limpa e volta para home
          final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
          carrinho.limpar();
          Provider.of<MesaComandaModel>(context, listen: false).limpar();

          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Pagamento foi realizado nesse meio tempo
          setState(() {
            _mensagemStatus = "Pagamento confirmado após expiração!";
          });
        }

        // // Limpa o carrinho via Provider
        // final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
        // carrinho.limpar();
        // Provider.of<MesaComandaModel>(context, listen: false).limpar();

        // Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  void _iniciarPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_idInvoice != null && !_consultandoPagamento) {
        _consultandoPagamento = true; // bloqueia novas chamadas
        try {
          await _consultarPagamento(_idInvoice!);
        } finally {
          _consultandoPagamento = false; // libera para próxima chamada
        }
      }
    });
  }

  Future<void> _consultarPagamento(int idInvoice) async {
    final url = Uri.parse('${Urls.urlApiPagtoAzure}Pix/consultar');

    try {
      final body = jsonEncode({
        "idFilial": GlobalKeys.codFilial,
        "idInvoicePix": idInvoice.toString(), // ou pode deixar como int
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['statusPagamento'] == 'credited' ||
            jsonResponse['statusPagamento'] == 'paid') {
          _timer?.cancel();
          _pollingTimer?.cancel();
          setState(() {
            _pagamentoRealizado = true;
          });
          var idPedido = await uploadPedido();
          final nfceService = NfceService();

          final carrinho = Provider.of<CarrinhoModel>(context, listen: false);

          bool resultado = await nfceService.getInformacoesFiscaisDosProdutos(
            carrinho.itens,
            context,
          );
          if (!mounted) return;

          if (resultado) {
            setState(() {
              _notaGerada = true;
            });
          } else {
            _ErroGeracaoNF = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erro ao obter informações fiscais dos produtos. ${GlobalKeys.errroResponse} - ${GlobalKeys.errroResponseStatusCode}',
                ),
              ),
            );
          }

          // _showSucesso('Pagamento aprovado! ID Invoice: $idInvoice');
        } else {
          //_showErro('Pagamento pendente...');
          if (!mounted) return;

          setState(() {
            _mensagemStatus = 'Pagamento pendente...';
          });
        }
      } else {
        _showErro('Erro na API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao consultar pagamento: $e');
    }
  }

  void _showErro(String mensagem) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Erro'),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSucesso(String mensagem) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Sucesso'),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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

      await _firestore
          .collection('teste_pedido_mesa')
          .doc(pedidoId)
          .set(pedido.toMap());

      return pedidoId;
    } catch (e) {
      print("Erro ao fazer upload do pedido: $e");
      return "";
    }
  }

  void openPdfInBrowser(String base64Pdf) {
    final decodedBytes = base64Decode(
      base64Pdf.replaceAll('\n', '').replaceAll('\r', ''),
    );

    // Decodifica o Base64 para bytes
    final pdfBytes = base64Decode(base64Pdf);

    // Cria um Blob (arquivo temporário na memória do navegador)
    final blob = html.Blob([pdfBytes], 'application/pdf');

    // Gera uma URL temporária para esse Blob
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Abre em uma nova aba do navegador
    html.window.open(url, "_blank");

    // Libera a URL depois (boa prática)
    html.Url.revokeObjectUrl(url);
  }

  // Faz download do PDF
  void downloadPdf(String base64Pdf, String fileName) {
    final pdfBytes = base64Decode(base64Pdf);
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor =
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollingTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Pagamento PIX'),
      //   automaticallyImplyLeading: false,
      // ),
      body: SingleChildScrollView(
        child: Center(
          child:
              _processandoPagamento
                  ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const CircularProgressIndicator(),
                  )
                  : _pagamentoRealizado
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 80),
                      Text(
                        'Aguarde que seu pedido será entregue na mesa.\nPedido ID: ${_idInvoice}\nObrigado!!',
                      ),

                      // ElevatedButton(
                      //   onPressed: () async {
                      //     // 1- ENVIAR API BRATTER
                      //     // Aqui você pode chamar a API para registrar o pagamento
                      //     // e enviar os dados necessários, como mesa, comanda, etc.
                      //     // 2- DAR BAIXA NA COMANDA BRATTER
                      //     // 3- GRAVAR NO FIREBASE, tabela: pedidos add obs:  pedido_mesa
                      //     var idPedido = await uploadPedido();
                      //     // 4- CHAMAR API XML
                      //     // final nfceService = NfceService();

                      //     // final carrinho = Provider.of<CarrinhoModel>(
                      //     //   context,
                      //     //   listen: false,
                      //     // );
                      //     // bool resultado = await nfceService
                      //     //     .getInformacoesFiscaisDosProdutos(
                      //     //       carrinho.itens,
                      //     //       context,
                      //     //     );

                      //     // if (resultado) {
                      //     // String base64Pdf =
                      //     //     GlobalKeys.base64Nfe; // seu PDF em Base64
                      //     // openPdfInBrowser(base64Pdf);

                      //     // carrinho.limpar();
                      //     // Provider.of<MesaComandaModel>(
                      //     //   context,
                      //     //   listen: false,
                      //     // ).limpar();

                      //     // Navigator.of(
                      //     //   context,
                      //     // ).popUntil((route) => route.isFirst);
                      //     // } else {
                      //     //   ScaffoldMessenger.of(context).showSnackBar(
                      //     //     SnackBar(
                      //     //       content: Text(
                      //     //         'Erro ao obter informações fiscais dos produtos. ${GlobalKeys.errroResponse} - ${GlobalKeys.errroResponseStatusCode}',
                      //     //       ),
                      //     //     ),
                      //     //   );
                      //     // }
                      //   },
                      //   child: const Text('Ok'),
                      // ),
                      const SizedBox(height: 20),
                      _notaGerada == true
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.visibility),
                                label: const Text("Visualizar PDF"),
                                onPressed: () {
                                  String base64Pdf =
                                      GlobalKeys.base64Nfe; // seu PDF em Base64
                                  openPdfInBrowser(base64Pdf);
                                },
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.download),
                                label: const Text("Baixar/Compartilhar"),
                                onPressed:
                                    () => downloadPdf(
                                      GlobalKeys.base64Nfe,
                                      "documento.pdf",
                                    ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.home),
                                label: const Text("Voltar"),
                                onPressed: () {
                                  final carrinho = Provider.of<CarrinhoModel>(
                                    context,
                                    listen: false,
                                  );
                                  carrinho.limpar();
                                  Provider.of<MesaComandaModel>(
                                    context,
                                    listen: false,
                                  ).limpar();

                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                },
                              ),
                            ],
                          )
                          : _ErroGeracaoNF
                          ? ElevatedButton.icon(
                            icon: const Icon(Icons.home),
                            label: const Text("Voltar"),
                            onPressed: () {
                              final carrinho = Provider.of<CarrinhoModel>(
                                context,
                                listen: false,
                              );
                              carrinho.limpar();
                              Provider.of<MesaComandaModel>(
                                context,
                                listen: false,
                              ).limpar();

                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
                          )
                          : SizedBox(),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_qrCodeBase64 != null) ...[
                        const SizedBox(height: 10),
                        Image.asset('images/LogoPix.png', width: 220),
                        const SizedBox(height: 10),
                        Image.memory(
                          base64Decode(_qrCodeBase64!.split(',').last),
                          width: 250,
                          height: 250,
                        ),
                        const SizedBox(height: 10),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('COPIA E COLA PIX'),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _brCode ?? ''),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Código PIX copiado!'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 1.0, end: 0.0),
                          duration: const Duration(seconds: 180),
                          builder: (context, value, child) {
                            return LinearProgressIndicator(value: value);
                          },
                        ),

                        const SizedBox(height: 10),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 500),
                          style: TextStyle(
                            fontSize: 24,
                            color:
                                _tempoRestante < 10 ? Colors.red : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          child: Text('Expira em $_tempoRestante s'),
                        ),
                        const SizedBox(height: 10),
                        if (_mensagemStatus != null)
                          Text(
                            _mensagemStatus!,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                      const SizedBox(height: 20),
                      if (_qrCodeBase64 == null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.pix),
                          onPressed: _gerarPix,
                          label: const Text('Gerar PIX'),
                        ),
                      if (_qrCodeBase64 != null &&
                          GlobalKeys.ambienteNfe == "H")
                        ElevatedButton(
                          onPressed: _simularPagamentoPix,
                          child: const Text('Simular pagamento'),
                        ),
                      const SizedBox(height: 20),
                      if (_qrCodeBase64 != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.paid),
                          label: const Text("Pagamento Realizado"),
                          onPressed: () {
                            final carrinho = Provider.of<CarrinhoModel>(
                              context,
                              listen: false,
                            );
                            carrinho.limpar();
                            Provider.of<MesaComandaModel>(
                              context,
                              listen: false,
                            ).limpar();

                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class PagamentoPixPage extends StatefulWidget {
//   const PagamentoPixPage({super.key});

//   @override
//   State<PagamentoPixPage> createState() => _PagamentoPixPageState();
// }

// class _PagamentoPixPageState extends State<PagamentoPixPage> {
//   bool _processandoPagamento = false;
//   bool _pagamentoRealizado = false;
//   String? _qrCodeBase64;
//   int? _idInvoice;

//   // Fake request body
//   Map<String, dynamic> _pixRequestBody() => {
//     "descricaoFilial": "Lapa",
//     "idFilial": "8urs76lF1QwjcNpi3CwD",
//     "idEmpresa": "1",
//     "descricaoEmpresa": "Dona Deola",
//     "ambiente": "H",
//     "valor": "1450",
//     "tipo_transacao": "pixCashin",
//     "vencimento": "2025-08-18T22:50:00",
//     "descricao": "Descrição da cobrança...",
//     "texto_instrucao": "Instruções da cobrança...",
//     "identificador_externo": null,
//     "identificador_movimento": " ",
//     "enviar_qr_code": true,
//     "cliente": {
//       "nome": "Maria Eduarda",
//       "tipo_documento": "cpf",
//       "numero_documento": "255.539.850-30",
//       "e-mail": "maria.eduarda@email.com.br",
//     },
//     "split": [
//       {
//         "tipo": "percentual",
//         "valor": "0.70",
//         "conta": "89392367-30d4-11f0-a96f-42010a400013",
//       },
//       {
//         "tipo": "valor",
//         "valor": "0.40",
//         "conta": "89392367-30d4-11f0-a96f-42010a400013",
//       },
//     ],
//   };

//   Future<void> _gerarPix() async {
//     setState(() {
//       _processandoPagamento = true;
//     });

//     final url = Uri.parse(
//       'https://webapi-sispagamento-hnabgfa6h9h7hrg3.brazilsouth-01.azurewebsites.net/api/Pix/gerar',
//     );

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(_pixRequestBody()),
//       );

//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         if (jsonResponse['success'] == true) {
//           final data = jsonResponse['data']['data'];
//           setState(() {
//             _qrCodeBase64 = data['qrcode'];
//             _idInvoice = data['id_invoice_pix'];
//           });

//           // Espera 3s e consulta pagamento
//           await Future.delayed(const Duration(seconds: 3));
//           await _consultarPagamento(_idInvoice!);
//         } else {
//           _showErro('Falha ao gerar PIX: ${jsonResponse['mensagem']}');
//         }
//       } else {
//         _showErro('Erro na API: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       _showErro('Erro ao chamar API: $e');
//     } finally {
//       setState(() {
//         _processandoPagamento = false;
//       });
//     }
//   }

//   Future<void> _consultarPagamento(int idInvoice) async {
//     final url = Uri.parse(
//       'https://webapi-sispagamento-hnabgfa6h9h7hrg3.brazilsouth-01.azurewebsites.net/api/Pix/consultaPagPix',
//     );

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"id_invoice_pix": idInvoice}),
//       );

//       if (response.statusCode == 200) {
//         // Aqui você pode processar o retorno do pagamento
//         setState(() {
//           _pagamentoRealizado = true;
//         });
//         _showSucesso('Pagamento aprovado! ID Invoice: $idInvoice');
//       } else {
//         _showErro(
//           'Erro na consulta do pagamento: ${response.statusCode} - ${response.reasonPhrase}',
//         );
//       }
//     } catch (e) {
//       _showErro('Erro ao consultar pagamento: $e');
//     }
//   }

//   void _showErro(String mensagem) {
//     showDialog(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             title: const Text('Erro'),
//             content: Text(mensagem),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//     );
//   }

//   void _showSucesso(String mensagem) {
//     showDialog(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             title: const Text('Sucesso'),
//             content: Text(mensagem),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Pagamento PIX')),
//       body: Center(
//         child:
//             _processandoPagamento
//                 ? const CircularProgressIndicator()
//                 : _pagamentoRealizado
//                 ? const Text('Pagamento concluído com sucesso!')
//                 : Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     if (_qrCodeBase64 != null)
//                       Image.memory(
//                         base64Decode(
//                           _qrCodeBase64!.split(',').last,
//                         ), // remove data:image/png;base64,
//                         width: 250,
//                         height: 250,
//                       ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: _gerarPix,
//                       child: const Text('Gerar PIX'),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }
