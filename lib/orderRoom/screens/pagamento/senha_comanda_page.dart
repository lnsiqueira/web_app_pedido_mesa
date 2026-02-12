import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/home/order_home_page.dart';
import 'package:webapp_pedido_mesa/services/storage/carrinho_storage.dart';

class SenhaComandaPage extends StatefulWidget {
  final int senha;
  bool? isPagamento;
  double totalPedido;

  SenhaComandaPage({
    super.key,
    required this.senha,
    this.isPagamento,
    this.totalPedido = 0.0,
  });

  @override
  State<SenhaComandaPage> createState() => _SenhaComandaPageState();
}

class _SenhaComandaPageState extends State<SenhaComandaPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _mostrarPixDialog(double valor) {
    // Simulação de payload PIX (não é real bancário)
    final pixPayload = '''
00020126360014BR.GOV.BCB.PIX0114+55119999999990214Pagamento Mesa 1235204000053039865405${widget.totalPedido.toStringAsFixed(2)}5802BR5920Restaurante Dona Deola Sao Paulo62070503***6304ABCD
''';

    Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Pagamento via PIX",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          /// QR CODE
          QrImageView(
            data: pixPayload,
            version: QrVersions.auto,
            size: 220,
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.2,
                      end: 1.0,
                    ).animate(_scale),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 90,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Pedido realizado!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// TEMPO MÉDIO
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tempo médio de preparo: 15 minutos\n'
                            'Aguarde a chamada da sua senha no painel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// CARD DA SENHA
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SUA SENHA',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1.2,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.senha.toString().padLeft(3, '0'),
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3C72),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Essa é a senha para retirar o pedido.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tire um print desta tela para retirar seu pedido.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Pagamento via PIX",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        /// QR CODE
                        QrImageView(
                          data: 'pixPayload',
                          version: QrVersions.auto,
                          size: 120,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// AÇÕES
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        if (widget.isPagamento == true) ...[
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Ver nota fiscal'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blueGrey[800],
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          // const SizedBox(height: 12),
                          // ElevatedButton.icon(
                          //   onPressed: () {
                          //     // TODO: enviar email
                          //   },
                          //   icon: const Icon(Icons.email_outlined),
                          //   label: const Text('Enviar nota por e-mail'),
                          //   style: ElevatedButton.styleFrom(
                          //     minimumSize: const Size.fromHeight(52),
                          //     backgroundColor: Colors.white,
                          //     foregroundColor: Colors.blueGrey[800],
                          //     elevation: 3,
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(14),
                          //     ),
                          //   ),
                          // ),
                        ],
                        //const SizedBox(height: 24),

                        /// SEMPRE VISÍVEL
                        TextButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrderHomePage(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text(
                            'Voltar ao início',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
