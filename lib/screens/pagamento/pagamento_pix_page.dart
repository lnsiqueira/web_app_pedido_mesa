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
import 'dart:html' as html;

import 'package:webapp_pedido_mesa/widgets/logo_pulsando.dart'; // para abrir no browser

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
  int _tempoRestante = 600; // 10 minutos
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
    valorEmCentavos =
        carrinho.totalGeral.toStringAsFixed(2).replaceAll('.', '');

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
        // "cliente": {
        //   "nome": "Maria Eduarda",
        //   "tipo_documento": "cpf",
        //   "numero_documento": "255.539.850-30",
        //   "e-mail": "maria.eduarda@email.com.br",
        // },
        "split": [],
      };

  Future<void> _pagarCaixa() async {
    GlobalKeys.pagtoPIX = false;
    bool addPedido = false;
    try {
      try {
        var idPedido = await uploadPedido();

        final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
        final mesaComanda =
            Provider.of<MesaComandaModel>(context, listen: false);

        List<Map<String, dynamic>> itemsJson = carrinho.itens.map((item) {
          List<Map<String, dynamic>> observacoesJson = [];

          if (item.produto.obs != null && item.produto.obs!.isNotEmpty) {
            for (var obsItem in item.produto.obs!) {
              if (obsItem.tipo == "texto" && obsItem.titulo.trim().isNotEmpty) {
                observacoesJson.add({
                  "Obs": obsItem.titulo,
                  "Preco": 0.0,
                  "PluAdd": obsItem.pluAdd ?? 0,
                  "Modificador": 'COM',
                });
              } else if (obsItem.modificador != null &&
                  (obsItem.modificador == 'C' || obsItem.modificador == 'S')) {
                observacoesJson.add({
                  "Obs": obsItem.titulo,
                  "Preco": obsItem.preco ?? 0.0,
                  "PluAdd": obsItem.pluAdd ?? 0,
                  "Modificador": obsItem.modificador,
                });
              }
            }
          }

          final qtd = item.quantidade > 0 ? item.quantidade : 1;

          return {
            "IdProduto": item.produto.plu,
            "Preco": item.produto.preco,
            "Qtde": item.quantidade,
            "Observacoes": observacoesJson,
          };
        }).toList();

        var urlBratter = Urls.urlApiBratter;
        final encodedUrl = Uri.encodeComponent(urlBratter);

        final url =
            '${Urls.urlApiAzure}Proxy/AddComanda?urlBratter=$encodedUrl&tokenBratter=${GlobalKeys.tokenBratter}';

        var request = http.Request('POST', Uri.parse(url));
        request.headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });

        request.body = json.encode({
          "IdComanda": int.parse(mesaComanda.comanda),
          "IdMesa": int.parse(mesaComanda.mesa),
          "usuario": '',
          "Itens": itemsJson,
          "Uuid": idPedido,
          "Terminal": 301,
        });
        var bodyJson = {
          "IdComanda": int.parse(mesaComanda.comanda),
          "IdMesa": int.parse(mesaComanda.mesa),
          "usuario": '',
          "Itens": itemsJson,
          "Uuid": idPedido,
          "Terminal": 301,
        };

        print("➡️ JSON enviado:");
        print(const JsonEncoder.withIndent('  ').convert(bodyJson));
        final response = await request.send();
        if (response.statusCode == 200) {
          addPedido = true;
          print('Pedido enviado com sucesso!');
        } else {
          print('Erro ao enviar pedido: ${response.statusCode}');
          _showErro(
              'Erro ao enviar pedidoX: ${response.statusCode}. \nContate um funcionário!');
        }
      } catch (e) {
        print('Erro no upload do pedido: $e');
        _showErro(
            'Erro ao enviar pedidoX: ${e.toString()}. \nContate um funcionário!');
      }

      if (addPedido) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Pedido solicitado!'),
            content: Text('Aguarde, seu pedido será entregue na mesa'),
            actions: [
              TextButton(
                onPressed: () {
                  // 1- ENVIAR API BRATTER

                  // 2- GRAVAR NO FIREBASE, tabela: pedidos add obs:  pedido_mesa

                  Navigator.of(context).pop(); // fecha o dialog

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
    } catch (e) {
      _showErro('Erro ao chamar API: $e');
    }
  }

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

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(_pixRequestBody()),
          )
          .timeout(const Duration(seconds: 5));

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

  // Future<void> _gerarPix() async {
  //   if (!mounted) return;

  //   setState(() {
  //     _processandoPagamento = true;
  //     _pagamentoRealizado = false;
  //     _tempoRestante = 600;
  //   });

  //   GlobalKeys.pagtoPIX = true;
  //   final url = Uri.parse('${Urls.urlApiPagtoAzure}Pix/gerar');

  //   try {
  //     final response = await http
  //         .post(
  //           url,
  //           headers: {"Content-Type": "application/json"},
  //           body: jsonEncode(_pixRequestBody()),
  //         )
  //         .timeout(const Duration(seconds: 30));

  //     if (response.statusCode == 200) {
  //       final jsonResponse = jsonDecode(response.body);
  //       if (jsonResponse['success'] == true) {
  //         final data = jsonResponse['data']['data'];
  //         setState(() {
  //           _qrCodeBase64 = data['qrcode'];
  //           _idInvoice = data['id_invoice_pix'];
  //           GlobalKeys.idInvoice = _idInvoice!;
  //           _brCode = data['brcode'];
  //           GlobalKeys.brCode = _brCode ?? '';
  //         });

  //         // Inicia contador regressivo
  //         _iniciarContador();

  //         // Espera 10s e começa o polling a cada 3s
  //         //10
  //         Future.delayed(const Duration(seconds: 10), () {
  //           if (!mounted) return;
  //           _iniciarPolling();
  //         });
  //       } else {
  //         _showErro('Falha ao gerar PIX: ${jsonResponse['mensagem']}');
  //       }
  //     } else {
  //       _showErro('Erro na API: ${response.statusCode} - ${response.body}');
  //     }
  //   } catch (e) {
  //     if (e is TimeoutException) {
  //       _showErro('Tempo limite excedido. Tente novamente.');
  //     } else {
  //       _showErro('Erro ao chamar API: $e');
  //     }
  //   } finally {
  //     setState(() {
  //       _processandoPagamento = false;
  //     });
  //   }
  // }
  Future<void> _gerarPix() async {
    if (!mounted) return;

    setState(() {
      _processandoPagamento = true;
      _pagamentoRealizado = false;
      _tempoRestante = 600;
    });

    GlobalKeys.pagtoPIX = true;
    final url = Uri.parse('${Urls.urlApiPagtoAzure}Pix/gerar');
    const maxTentativas = 3;

    try {
      for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
        try {
          final response = await http
              .post(
                url,
                headers: {"Content-Type": "application/json"},
                body: jsonEncode(_pixRequestBody()),
              )
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse['success'] == true) {
              final data = jsonResponse['data']['data'];
              setState(() {
                _qrCodeBase64 = data['qrcode'];
                _idInvoice = data['id_invoice_pix'];
                GlobalKeys.idInvoice = _idInvoice!;
                _brCode = data['brcode'];
                GlobalKeys.brCode = _brCode ?? '';
              });

              // Inicia contador regressivo
              _iniciarContador();

              // Espera 10s e começa o polling a cada 3s
              Future.delayed(const Duration(seconds: 10), () {
                if (!mounted) return;
                _iniciarPolling();
              });

              return; // ✅ Sai do loop porque deu certo
            } else {
              _showErro('Falha ao gerar PIX: ${jsonResponse['mensagem']}');
              break; // Não faz sentido tentar de novo se a API respondeu falha lógica
            }
          } else {
            if (tentativa == maxTentativas) {
              _showErro(
                  'Erro na API: ${response.statusCode} - ${response.body}');
            } else {
              await Future.delayed(const Duration(
                  seconds: 2)); // espera antes da próxima tentativa
            }
          }
        } catch (e) {
          if (tentativa == maxTentativas) {
            if (e is TimeoutException) {
              _showErro('Tempo limite excedido. Tente novamente.');
            } else {
              _showErro('Erro ao chamar API: $e');
            }
          } else {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
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

  Future<void> _subirComandaEdeletar() async {
    bool addPedido = false;

    try {
      var idPedido = await uploadPedido();

      final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
      final mesaComanda = Provider.of<MesaComandaModel>(context, listen: false);

      List<Map<String, dynamic>> itemsJson = carrinho.itens.map((item) {
        List<Map<String, dynamic>> observacoesJson = [];

        if (item.produto.obs != null && item.produto.obs!.isNotEmpty) {
          for (var obsItem in item.produto.obs!) {
            if (obsItem.tipo == "texto" && obsItem.titulo.trim().isNotEmpty) {
              observacoesJson.add({
                "Obs": obsItem.titulo,
                "Preco": 0.0,
                "PluAdd": obsItem.pluAdd ?? 0,
                "Modificador": 'COM',
              });
            } else if (obsItem.modificador != null &&
                (obsItem.modificador == 'C' || obsItem.modificador == 'S')) {
              observacoesJson.add({
                "Obs": obsItem.titulo,
                "Preco": obsItem.preco ?? 0.0,
                "PluAdd": obsItem.pluAdd ?? 0,
                "Modificador": obsItem.modificador,
              });
            }
          }
        }

        return {
          "IdProduto": item.produto.plu,
          "Preco": item.produto.preco,
          "Qtde": item.quantidade,
          "Observacoes": observacoesJson,
        };
      }).toList();

      var urlBratter = Urls.urlApiBratter;
      final encodedUrl = Uri.encodeComponent(urlBratter);

      final url =
          '${Urls.urlApiAzure}Proxy/AddComanda?urlBratter=$encodedUrl&tokenBratter=${GlobalKeys.tokenBratter}';

      var request = http.Request('POST', Uri.parse(url));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      request.body = json.encode({
        "IdComanda": int.parse(mesaComanda.comanda),
        "IdMesa": int.parse(mesaComanda.mesa),
        "usuario": '',
        "Itens": itemsJson,
        "Uuid": idPedido,
        "Terminal": 301,
      });

      final response = await request.send();
      if (response.statusCode == 200) {
        addPedido = true;

        // 🔹 Se deu sucesso, chama CancelarComanda
        final urlCancel =
            '${Urls.urlApiAzure}Proxy/CancelarComanda?urlBratter=$encodedUrl&tokenBratter=${GlobalKeys.tokenBratter}&idComanda=${mesaComanda.comanda}&usuario=conexao&motivoCancelamento=compra';
        await Future.delayed(const Duration(milliseconds: 1500));

        var limparComanda = http.Request('POST', Uri.parse(urlCancel));
        limparComanda.headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });

        await limparComanda.send();
      } else {
        _showErro(
            'Erro ao enviar pedidoX: ${response.statusCode}. \nContate um funcionário!');
      }
    } catch (e) {
      _showErro(
          'Erro ao enviar pedidoX: ${e.toString()}. \nContate um funcionário!');
    }
  }

  Future<void> _consultarPagamento(int idInvoice) async {
    final url = Uri.parse('${Urls.urlApiPagtoAzure}Pix/consultar');

    try {
      final body = jsonEncode({
        "idFilial": GlobalKeys.codFilial,
        "idInvoicePix": idInvoice.toString(), // ou pode deixar como int
        "ambiente": GlobalKeys.ambienteNfe,
      });

      final response = await http
          .post(url, headers: {"Content-Type": "application/json"}, body: body)
          .timeout(const Duration(seconds: 30));
//sucesso no pagamento
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['statusPagamento'] == 'credited' ||
            jsonResponse['statusPagamento'] == 'paid') {
          _timer?.cancel();
          _pollingTimer?.cancel();
          setState(() {
            _pagamentoRealizado = true;
          });
          _subirComandaEdeletar();
          var idPedido = await uploadPedido();
          final nfceService = NfceService();

          final carrinho = Provider.of<CarrinhoModel>(context, listen: false);

          bool resultado = true;
          // resultado = await nfceService.getInformacoesFiscaisDosProdutos(
          //   carrinho.itens,
          //   context,
          // );
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
      builder: (_) => AlertDialog(
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
      builder: (_) => AlertDialog(
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
            preco: item.produto.preco! *
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
        pedidoPagoMesa: _pagamentoRealizado,
        comanda: mesaComanda.comanda,
        serieNfe: GlobalKeys.serieNfe,
        ambiente: GlobalKeys.ambienteNfe,
        vlrDescontoEmbalagem: 0,
        pedidoMesa: true,
        mesa: mesaComanda.mesa,
        idInvoicePix: GlobalKeys.idInvoice,
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

    final anchor = html.AnchorElement(href: url)
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
    String _formatarTempo(int segundos) {
      if (segundos >= 60) {
        int minutos = segundos ~/ 60;
        int segundosRestantes = segundos % 60;
        if (segundosRestantes == 0) {
          return '$minutos min';
        } else {
          return '$minutos min ${segundosRestantes}s';
        }
      } else {
        return '$segundos s';
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: _processandoPagamento
              ? SizedBox(
                  height: MediaQuery.of(context).size.height * 1,
                  child: const Center(
                    child: PulsingLogo(
                      assetPath: 'images/logodd_clean.png',
                      width: 150,
                      duration: Duration(seconds: 1),
                    ),
                  ),
                )
              : _pagamentoRealizado
                  ? SingleChildScrollView(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Center(
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            margin: const EdgeInsets.all(20),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Ícone de sucesso com animação leve
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.8, end: 1.0),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.elasticOut,
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.green[600],
                                          size: 90,
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // Título
                                  Text(
                                    "Pedido Confirmado!",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 10),

                                  // Subtítulo
                                  Text(
                                    "Aguarde que seu pedido será entregue na mesa.\n\nPedido ID: $_idInvoice",
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 30),

                                  // Se nota gerada
                                  if (_notaGerada == true)
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 12,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.visibility),
                                          label: const Text("Visualizar PDF"),
                                          onPressed: () {
                                            String base64Pdf =
                                                GlobalKeys.base64Nfe;
                                            openPdfInBrowser(base64Pdf);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.download),
                                          label:
                                              const Text("Baixar/Compartilhar"),
                                          onPressed: () => downloadPdf(
                                            GlobalKeys.base64Nfe,
                                            "documento.pdf",
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.home),
                                          label: const Text("Voltar"),
                                          onPressed: () {
                                            final carrinho =
                                                Provider.of<CarrinhoModel>(
                                              context,
                                              listen: false,
                                            );
                                            carrinho.limpar();
                                            Provider.of<MesaComandaModel>(
                                              context,
                                              listen: false,
                                            ).limpar();

                                            Navigator.of(context).popUntil(
                                                (route) => route.isFirst);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (_ErroGeracaoNF)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.home),
                                      label: const Text("Voltar"),
                                      onPressed: () {
                                        final carrinho =
                                            Provider.of<CarrinhoModel>(
                                          context,
                                          listen: false,
                                        );
                                        carrinho.limpar();
                                        Provider.of<MesaComandaModel>(
                                          context,
                                          listen: false,
                                        ).limpar();

                                        Navigator.of(context)
                                            .popUntil((route) => route.isFirst);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_qrCodeBase64 != null) ...[
                          SingleChildScrollView(
                            child: Center(
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                margin: const EdgeInsets.all(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 12),
                                      Image.asset('images/LogoPix.png',
                                          width: 180),
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                              color: Colors.black12,
                                            ),
                                          ],
                                        ),
                                        child: Image.memory(
                                          base64Decode(
                                              _qrCodeBase64!.split(',').last),
                                          width: 220,
                                          height: 220,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.copy, size: 22),
                                        label: const Text(
                                          'COPIAR CÓDIGO PIX',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: _brCode ?? ''));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Código PIX copiado!'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[700],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 28, vertical: 14),
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween<double>(
                                              begin: 1.0, end: 0.0),
                                          duration:
                                              const Duration(seconds: 600),
                                          builder: (context, value, child) {
                                            return LinearProgressIndicator(
                                              value: value,
                                              backgroundColor: Colors.grey[200],
                                              color: value > 0.5
                                                  ? Colors.green
                                                  : value > 0.2
                                                      ? Colors.orange
                                                      : Colors.red,
                                              minHeight: 10,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      AnimatedDefaultTextStyle(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        style: TextStyle(
                                          fontSize:
                                              _tempoRestante <= 60 ? 26 : 22,
                                          color: _tempoRestante <= 30
                                              ? Colors.red[700]
                                              : _tempoRestante <= 60
                                                  ? Colors.orange[700]
                                                  : Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                          shadows: _tempoRestante <= 30
                                              ? [
                                                  Shadow(
                                                    blurRadius: 8,
                                                    color: Colors.red
                                                        .withOpacity(0.4),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          'Expira em ${_formatarTempo(_tempoRestante)}',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (_mensagemStatus != null)
                                        Text(
                                          _mensagemStatus!,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black26,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (_qrCodeBase64 == null)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: Stack(
                              children: [
                                // Conteúdo centralizado
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Opções de Pagamento',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 40),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.pix, size: 26),
                                          onPressed: _gerarPix,
                                          label: const Text(
                                            'Pagar com PIX',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            foregroundColor: Colors.white,
                                            minimumSize:
                                                const Size.fromHeight(55),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: const [
                                            Expanded(
                                                child: Divider(thickness: 1)),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              child: Text("OU"),
                                            ),
                                            Expanded(
                                                child: Divider(thickness: 1)),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          icon:
                                              const Icon(Icons.store, size: 26),
                                          onPressed: _pagarCaixa,
                                          label: const Text(
                                            'Pagar no Caixa',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blueGrey[700],
                                            foregroundColor: Colors.white,
                                            minimumSize:
                                                const Size.fromHeight(55),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Botão de voltar
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: SafeArea(
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_back,
                                          size: 28),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_qrCodeBase64 != null &&
                            GlobalKeys.ambienteNfe == "H")
                          ElevatedButton(
                            onPressed: _simularPagamentoPix,
                            child: const Text('Simular pagamento'),
                          ),
                        const SizedBox(height: 20),
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
