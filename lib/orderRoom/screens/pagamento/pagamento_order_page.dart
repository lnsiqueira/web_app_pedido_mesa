import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:webapp_pedido_mesa/admin/services/cardapio_admin_service.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/core/model/pedido_model.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/home/order_home_page.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/pagamento/senha_comanda_page.dart';
import 'package:webapp_pedido_mesa/services/nfce/nfce_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:webapp_pedido_mesa/services/storage/carrinho_storage.dart';
// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:webapp_pedido_mesa/widgets/logo_pulsando.dart';

import '../../oder_service.dart'; // para abrir no browser

class PagamentoOrderPage extends StatefulWidget {
  const PagamentoOrderPage({super.key});

  @override
  State<PagamentoOrderPage> createState() => _PagamentoOrderPageState();
}

class _PagamentoOrderPageState extends State<PagamentoOrderPage> {
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
        "descricaoFilial": '',
        "idFilial": codFilial,
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
  Future<void> _salvarPedidoFirebase({
    required int nota,
    required List<String> tags,
    required String observacao,
  }) async {
    final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
    final mesaComanda = Provider.of<MesaComandaModel>(context, listen: false);

    final itens = carrinho.itens.map((item) {
      return {
        "produto": item.produto.desProduto,
        "plu": item.produto.plu,
        "preco": item.produto.preco,
        "quantidade": item.quantidade,
      };
    }).toList();

    await _firestore.collection('Pedidos_Web').add({
      "codFilial": codFilial,
      // "descricaoFilial": GlobalKeys.descricaoFilial,
      "mesa": numeroMesa,
      "comanda": mesaComanda.comanda,
      "itens": itens,
      "avaliacao": {
        "nota": nota,
        "tags": tags,
        "observacao": observacao,
      },
      "total": carrinho.totalGeral,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _pagarCaixa() async {
    if (_pagando) return;

    setState(() => _pagando = true);

    try {
      final carrinho = Provider.of<CarrinhoModel>(context, listen: false);

      final mesaComanda = Provider.of<MesaComandaModel>(context, listen: false);

      debugPrint('MESA: ${mesaComanda.mesa}');
      debugPrint('COMANDA: ${mesaComanda.comanda}');

      // final idMesa = int.tryParse(
      //   mesaComanda.mesa.toString(),
      // );
      final idMesa = int.tryParse(
        numeroMesa.toString(),
      );
      // final idMesa = 2;

      final idComanda = int.tryParse(
        mesaComanda.comanda.toString(),
      );

      if (idMesa == null || idComanda == null) {
        throw Exception(
          'Mesa ou comanda inválida',
        );
      }

      List<Map<String, dynamic>> itemsJson = carrinho.itens.map((item) {
        List<Map<String, dynamic>> observacoesJson = [];

// flag para saber se já adicionou
        bool adicionouPedidoSite = false;

        if (item.produto.obs != null && item.produto.obs!.isNotEmpty) {
          for (var obsItem in item.produto.obs!) {
            if (obsItem.tipo == "texto" && obsItem.titulo.trim().isNotEmpty) {
              // texto original
              observacoesJson.add({
                "Obs": obsItem.titulo,
                "Preco": 0.0,
                "PluAdd": obsItem.pluAdd ?? 0,
                "Modificador": 'COM',
              });

              // adiciona apenas uma vez
              if (!adicionouPedidoSite) {
                observacoesJson.add({
                  "Obs": 'Pedido feito pelo site',
                  "Preco": 0.0,
                  "PluAdd": 0,
                  "Modificador": 'COM',
                });

                adicionouPedidoSite = true;
              }
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

        // adiciona mesmo assim
        if (!adicionouPedidoSite) {
          observacoesJson.add({
            "Obs": 'Pedido feito pelo site',
            "Preco": 0.0,
            "PluAdd": 0,
            "Modificador": 'COM',
          });
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

      final body = {
        "IdComanda": idComanda,
        "IdMesa": idMesa,
        "usuario": '',
        "Itens": itemsJson,
        "Uuid": const Uuid().v4(),
        "Terminal": 301,
      };

      debugPrint('BODY ENVIO: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        await _mostrarAvaliacaoDialog();
        if (!mounted) return;

        final carrinho = Provider.of<CarrinhoModel>(context, listen: false);

        carrinho.limpar();

        Provider.of<MesaComandaModel>(
          context,
          listen: false,
        ).limpar();

        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );
        debugPrint('Pedido enviado com sucesso');
      } else {
        throw Exception(
          'Erro API: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      debugPrint('Erro ao pagar no caixa: $e');
      debugPrintStack(stackTrace: stack);
    } finally {
      if (mounted) {
        setState(() => _pagando = false);
      }
    }
  }
  // Future<void> _pagarCaixa() async {
  //   if (_pagando) return;
  //   setState(() => _pagando = true);

  //   // ... sua lógica de pagamento aqui ...

  //   // Após pagamento bem-sucedido, abre o dialog de avaliação
  //   await _mostrarAvaliacaoDialog();
  // }

  Future<void> _mostrarAvaliacaoDialog() async {
    int notaSelecionada = 0;
    final List<String> tagsSelecionadas = [];
    final TextEditingController obsController = TextEditingController();
    bool enviado = false;

    final tags = [
      'Atendimento',
      'Comida ótima',
      'Rápido',
      'Embalagem',
      'Preço justo'
    ];
    final labels = ['', 'Ruim', 'Regular', 'Bom', 'Muito bom', 'Excelente!'];
    final labelColors = [
      Colors.transparent,
      Colors.red.shade600,
      Colors.orange.shade600,
      Colors.yellow.shade700,
      Colors.lightGreen.shade600,
      Colors.green.shade600,
    ];

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          if (enviado) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          color: Colors.green.shade700, size: 32),
                    ),
                    const SizedBox(height: 20),
                    const Text('Obrigado pela avaliação!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Seu feedback é muito importante\npara continuarmos melhorando.',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Topo com fundo suave
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade200, width: 0.8),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.orange.shade200, width: 0.8),
                        ),
                        child: Icon(Icons.storefront_rounded,
                            color: Colors.orange.shade700, size: 30),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Como foi sua experiência?',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sua avaliação ajuda outros clientes\ne melhora nosso serviço.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Corpo
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      // Estrelas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = i < notaSelecionada;
                          return GestureDetector(
                            onTap: () =>
                                setStateSB(() => notaSelecionada = i + 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              child: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_rounded,
                                size: 44,
                                color: filled
                                    ? Colors.amber.shade400
                                    : Colors.grey.shade500,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),

                      // Label da nota
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          notaSelecionada > 0
                              ? labels[notaSelecionada]
                              : 'Toque para avaliar',
                          key: ValueKey(notaSelecionada),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: notaSelecionada > 0
                                ? labelColors[notaSelecionada]
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),

                      // Tags (aparecem após seleção)
                      if (notaSelecionada > 0) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: tags.map((tag) {
                            final ativo = tagsSelecionadas.contains(tag);
                            return GestureDetector(
                              onTap: () => setStateSB(() {
                                ativo
                                    ? tagsSelecionadas.remove(tag)
                                    : tagsSelecionadas.add(tag);
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: ativo
                                      ? Colors.orange.shade50
                                      : Colors.white,
                                  border: Border.all(
                                    color: ativo
                                        ? Colors.orange.shade700
                                        : Colors.grey.shade300,
                                    width: ativo ? 1.5 : 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: ativo
                                        ? Colors.orange.shade800
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Campo de texto
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade300, width: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: obsController,
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'Quer comentar algo? (opcional)',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Botões
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            side: BorderSide(
                                color: Colors.grey.shade300, width: 0.8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Não',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: AnimatedOpacity(
                          opacity: notaSelecionada > 0 ? 1.0 : 0.45,
                          duration: const Duration(milliseconds: 200),
                          child: ElevatedButton(
                            onPressed: notaSelecionada == 0
                                ? null
                                : () async {
                                    await _salvarPedidoFirebase(
                                      nota: notaSelecionada,
                                      tags: tagsSelecionadas,
                                      observacao: obsController.text,
                                    );

                                    setStateSB(() => enviado = true);

                                    Future.delayed(const Duration(seconds: 2),
                                        () {
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade800,
                              disabledBackgroundColor: Colors.orange.shade800,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Enviar avaliação',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    obsController.dispose();
  }
  // Future<void> _pagarCaixa() async {
  //   if (_pagando) return;

  //   setState(() => _pagando = true);
  // }
  // Future<void> _pagarCaixa() async {
  //   if (_pagando) return;

  //   setState(() => _pagando = true);

  //   // try {
  //   //   GlobalKeys.pagtoPIX = false;

  //   //   final carrinho = Provider.of<CarrinhoModel>(
  //   //     context,
  //   //     listen: false,
  //   //   );

  //   //   /// 🔥 1. GERA COMANDA
  //   //   final String comanda = await gerarComandaLivreWebApp();

  //   //   /// 🧾 2. SALVA PEDIDO NO FIREBASE
  //   //   await enviarPedidoFireBase(
  //   //     comanda: comanda,
  //   //     carrinho: carrinho,
  //   //     context: context,
  //   //   );
  //   //   final produtos = carrinho.itens.map((itemCarrinho) {
  //   //     final produto = itemCarrinho.produto;
  //   //     produto.quantidade = itemCarrinho.quantidade;
  //   //     return produto;
  //   //   }).toList();

  //   //   final sucesso = await baixarQuantidadeProdutos(
  //   //     produtos: produtos,
  //   //   );

  //   //   if (!sucesso) {
  //   //     throw Exception('Erro ao baixar quantidade dos produtos');
  //   //   }

  //   //   carrinho.limpar();

  //   //   Navigator.pushReplacement(
  //   //     context,
  //   //     MaterialPageRoute(
  //   //       builder: (_) => SenhaComandaPage(
  //   //         senha: int.parse(comanda),
  //   //       ),
  //   //     ),
  //   //   );
  //   // } catch (e) {
  //   //   debugPrint('Erro ao pagar no caixa: $e');
  //   // } finally {
  //   //   if (mounted) {
  //   //     setState(() => _pagando = false);
  //   //   }
  //   // }
  // }

  // Future<void> _pagarCaixa() async {
  //   if (_pagando) return;

  //   setState(() => _pagando = true);

  //   try {
  //     GlobalKeys.pagtoPIX = false;

  //     final carrinho = Provider.of<CarrinhoModel>(
  //       context,
  //       listen: false,
  //     );

  //     final produtos = carrinho.itens.map((itemCarrinho) {
  //       final produto = itemCarrinho.produto;
  //       produto.quantidade = itemCarrinho.quantidade;
  //       return produto;
  //     }).toList();

  //     final sucesso = await baixarQuantidadeProdutos(
  //       produtos: produtos,
  //     );

  //     if (!sucesso) {
  //       throw Exception('Erro ao baixar quantidade dos produtos');
  //     }

  //     carrinho.limpar();
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => SenhaComandaPage(senha: 42),
  //       ),
  //     );

  //   } catch (e) {
  //     debugPrint('Erro ao pagar no caixa: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() => _pagando = false);
  //     }
  //   }
  // }

  Future<void> _simularPagamentoPix() async {
    final url = Uri.parse('${Urls.urlApiPagtoAzure}Pix/simular_baixa');

    try {
      Map<String, dynamic> _pixRequestBody() => {
            "id": _idInvoice,
            "idFilial": codFilial,
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
          setState(() {
            _mensagemStatus = "Pagamento confirmado após expiração!";
          });
        }
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
        "idFilial": codFilial,
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

          //*var idPedido = await uploadPedido();
          final nfceService = NfceService();

          final carrinho = Provider.of<CarrinhoModel>(context, listen: false);

          bool resultado = true;
          resultado =
              await nfceService.getInformacoesFiscaisDosProdutosNaoGeraNFe(
            carrinho.itens,
            context,
          );

          if (!resultado) {
            _ErroGeracaoNF = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erro ao obter informações fiscais dos produtos. ${GlobalKeys.errroResponse} - ${GlobalKeys.errroResponseStatusCode}',
                ),
              ),
            );
            return;
          }

          _subirComandaEdeletar();

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
          codFilial: codFilial,
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
          json: GlobalKeys.nfe.toString());

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

  Future<void> mostrarReciboPopup(
    BuildContext context,
    double totalPedido,
    String idInvoice,
    String statusPagamento,
    List pedidos,
  ) async {
    final GlobalKey repaintKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          content: RepaintBoundary(
            key: repaintKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // <-- evita ocupar tela toda
              children: [
                Text(
                  'Recibo do Pedido - ID $idInvoice',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dona Deola',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Status do Pagamento: $statusPagamento'),
                const SizedBox(height: 10),
                const Text(
                  'Itens do Pedido:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                ...pedidos.map((item) {
                  final totalItem =
                      item.quantidade * (item.produto.preco ?? 0.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((item.produto.desProduto ?? '').toUpperCase()),
                        Text('Qtd: ${item.quantidade}'),
                        Text('Total: R\$ ${totalItem.toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(),
                Text(
                  'Total do Pedido: R\$ ${totalPedido.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Baixar/Compartilhar"),
              onPressed: () async {
                try {
                  final boundary = repaintKey.currentContext!.findRenderObject()
                      as RenderRepaintBoundary;

                  final image = await boundary.toImage(pixelRatio: 3.0);
                  final byteData =
                      await image.toByteData(format: ui.ImageByteFormat.png);
                  final pngBytes = byteData!.buffer.asUint8List();

                  final recorder = ui.PictureRecorder();
                  final canvas = Canvas(
                    recorder,
                    Rect.fromLTWH(
                        0, 0, image.width.toDouble(), image.height.toDouble()),
                  );

                  final paint = Paint()..color = Colors.white;
                  canvas.drawRect(
                    Rect.fromLTWH(
                        0, 0, image.width.toDouble(), image.height.toDouble()),
                    paint,
                  );

                  canvas.drawImage(image, Offset.zero, Paint());

                  final finalImage = await recorder
                      .endRecording()
                      .toImage(image.width, image.height);

                  final finalByteData = await finalImage.toByteData(
                      format: ui.ImageByteFormat.png);
                  final finalPngBytes = finalByteData!.buffer.asUint8List();

                  final blob = html.Blob([finalPngBytes]);
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  final anchor = html.AnchorElement(href: url)
                    ..setAttribute("download", "recibo_$idInvoice.png")
                    ..click();
                  html.Url.revokeObjectUrl(url);
                } catch (e) {
                  debugPrint("Erro ao salvar recibo: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            // TextButton(
            //   onPressed: () async {
            //     try {
            //       final boundary = repaintKey.currentContext!.findRenderObject()
            //           as RenderRepaintBoundary;

            //       final image = await boundary.toImage(pixelRatio: 3.0);
            //       final byteData =
            //           await image.toByteData(format: ui.ImageByteFormat.png);
            //       final pngBytes = byteData!.buffer.asUint8List();

            //       final recorder = ui.PictureRecorder();
            //       final canvas = Canvas(
            //         recorder,
            //         Rect.fromLTWH(
            //             0, 0, image.width.toDouble(), image.height.toDouble()),
            //       );

            //       final paint = Paint()..color = Colors.white;
            //       canvas.drawRect(
            //         Rect.fromLTWH(
            //             0, 0, image.width.toDouble(), image.height.toDouble()),
            //         paint,
            //       );

            //       canvas.drawImage(image, Offset.zero, Paint());

            //       final finalImage = await recorder
            //           .endRecording()
            //           .toImage(image.width, image.height);

            //       final finalByteData = await finalImage.toByteData(
            //           format: ui.ImageByteFormat.png);
            //       final finalPngBytes = finalByteData!.buffer.asUint8List();

            //       final blob = html.Blob([finalPngBytes]);
            //       final url = html.Url.createObjectUrlFromBlob(blob);
            //       final anchor = html.AnchorElement(href: url)
            //         ..setAttribute("download", "recibo_$idInvoice.png")
            //         ..click();
            //       html.Url.revokeObjectUrl(url);
            //     } catch (e) {
            //       debugPrint("Erro ao salvar recibo: $e");
            //     }
            //   },
            //   child: const Text('Salvar recibo'),
            // ),
          ],
        );
      },
    );
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

  bool _pagando = false;

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
                                          label: const Text(
                                              "Visualizar comprovante"),

                                          // String base64Pdf =
                                          //     GlobalKeys.base64Nfe;
                                          // openPdfInBrowser(base64Pdf);
                                          onPressed: () async {
                                            // Recupera os pedidos já salvos
                                            final pedidos =
                                                await CarrinhoStorage
                                                    .recuperarCarrinho();

// Calcula o total
                                            double totalPedido = pedidos.fold(
                                              0.0,
                                              (soma, item) =>
                                                  soma +
                                                  (item.quantidade *
                                                      (item.produto.preco ??
                                                          0.0)),
                                            );
                                            mostrarReciboPopup(
                                                context,
                                                totalPedido,
                                                GlobalKeys.idInvoice.toString(),
                                                'Pago',
                                                pedidos);
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
                                        // ElevatedButton.icon(
                                        //   icon: const Icon(Icons.download),
                                        //   label:
                                        //       const Text("Baixar/Compartilhar"),
                                        //   onPressed: () => downloadPdf(
                                        //     GlobalKeys.base64Nfe,
                                        //     "documento.pdf",
                                        //   ),
                                        //   style: ElevatedButton.styleFrom(
                                        //     padding: const EdgeInsets.symmetric(
                                        //       horizontal: 20,
                                        //       vertical: 14,
                                        //     ),
                                        //     shape: RoundedRectangleBorder(
                                        //       borderRadius:
                                        //           BorderRadius.circular(14),
                                        //     ),
                                        //   ),
                                        // ),
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
                        const SizedBox(height: 8),
                        if (_qrCodeBase64 == null)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.82,
                            child: Stack(
                              children: [
                                // Background glow
                                Positioned(
                                  top: -120,
                                  right: -80,
                                  child: Container(
                                    width: 240,
                                    height: 240,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.orange.withOpacity(0.10),
                                    ),
                                  ),
                                ),

                                Positioned(
                                  bottom: -100,
                                  left: -80,
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.amber.withOpacity(0.08),
                                    ),
                                  ),
                                ),

                                // Conteúdo
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 26),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Ícone
                                        Container(
                                          width: 92,
                                          height: 92,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange.shade400,
                                                Colors.orange.shade200,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange
                                                    .withOpacity(0.25),
                                                blurRadius: 30,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.payments_rounded,
                                            size: 44,
                                            color: Colors.white,
                                          ),
                                        ),

                                        const SizedBox(height: 18),

                                        // Título
                                        const Text(
                                          'Finalizar compra',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.8,
                                            color: Color(0xFF1F1F1F),
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        Text(
                                          'Finalize seu pedido escolhendo\ncomo deseja realizar o pagamento',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.5,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        // Botão PIX (opcional)
                                        // _buildPaymentButton(...)

                                        // Botão Caixa
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 280),
                                          curve: Curves.easeOutCubic,
                                          width: double.infinity,
                                          height: 78,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(26),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF1F2937),
                                                Color(0xFF374151),
                                              ],
                                            ),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.08),
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.22),
                                                blurRadius: 28,
                                                offset: const Offset(0, 14),
                                              ),
                                              BoxShadow(
                                                color: Colors.white
                                                    .withOpacity(0.03),
                                                blurRadius: 8,
                                                offset: const Offset(0, -2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(26),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(26),
                                                splashColor: Colors.white
                                                    .withOpacity(0.05),
                                                highlightColor: Colors.white
                                                    .withOpacity(0.03),
                                                onTap: _pagando
                                                    ? null
                                                    : _pagarCaixa,
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      top: -20,
                                                      right: -10,
                                                      child: Container(
                                                        width: 90,
                                                        height: 90,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.04),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 18,
                                                        vertical: 14,
                                                      ),
                                                      child: Center(
                                                        child: _pagando
                                                            ? const SizedBox(
                                                                height: 28,
                                                                width: 28,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      3,
                                                                  valueColor: AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      Colors
                                                                          .white),
                                                                ),
                                                              )
                                                            : Row(
                                                                children: [
                                                                  Container(
                                                                    width: 48,
                                                                    height: 48,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              16),
                                                                      gradient:
                                                                          LinearGradient(
                                                                        colors: [
                                                                          Colors
                                                                              .white
                                                                              .withOpacity(0.16),
                                                                          Colors
                                                                              .white
                                                                              .withOpacity(0.08),
                                                                        ],
                                                                      ),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: Colors
                                                                            .white
                                                                            .withOpacity(0.10),
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        const Icon(
                                                                      Icons
                                                                          .storefront_rounded,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 24,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          16),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        const Text(
                                                                          'Pagar no caixa',
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                17,
                                                                            fontWeight:
                                                                                FontWeight.w800,
                                                                            letterSpacing:
                                                                                -0.4,
                                                                            height:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                6),
                                                                        Text(
                                                                          'Enviar pedido para a comanda',
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.white.withOpacity(0.68),
                                                                            fontSize:
                                                                                12.5,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            height:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          12),
                                                                  Container(
                                                                    width: 36,
                                                                    height: 36,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.08),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              14),
                                                                    ),
                                                                    child:
                                                                        const Icon(
                                                                      Icons
                                                                          .arrow_forward_ios_rounded,
                                                                      size: 16,
                                                                      color: Colors
                                                                          .white70,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // const SizedBox(height: 18),

                                        // Text(
                                        //   'Você poderá concluir o pagamento diretamente no atendimento.',
                                        //   textAlign: TextAlign.center,
                                        //   style: TextStyle(
                                        //     fontSize: 13,
                                        //     color: Colors.grey.shade500,
                                        //     fontWeight: FontWeight.w500,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Voltar
                                Positioned(
                                  top: 0,
                                  left: 4,
                                  child: SafeArea(
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.06),
                                            blurRadius: 14,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 22,
                                          color: Colors.black87,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
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

// class PagamentoOrderPage extends StatefulWidget {
//   const PagamentoOrderPage({super.key});

//   @override
//   State<PagamentoOrderPage> createState() => _PagamentoOrderPageState();
// }

// class _PagamentoOrderPageState extends State<PagamentoOrderPage> {
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
