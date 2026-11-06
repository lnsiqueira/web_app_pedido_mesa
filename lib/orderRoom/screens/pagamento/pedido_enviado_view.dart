import 'package:flutter/material.dart';

/// Tela "Pedido enviado!": confirma que foi para a comanda e mostra o que o
/// cliente pediu, antes da avaliação.
class PedidoEnviadoView extends StatelessWidget {
  const PedidoEnviadoView(
      {super.key, required this.pedido, required this.onContinuar});

  final PedidoEnviado pedido;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    final p = pedido;
    String reais(double v) =>
        'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
    const laranja = Color(0xFFE8710A);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 60, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pedido enviado!',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Já vai sair para a sua mesa.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 20),
                    // mesa e comanda em destaque
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        if (p.mesa.isNotEmpty) _etiqueta('Mesa', p.mesa),
                        _etiqueta('Comanda', p.comanda),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7EF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFE0C2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'O que você pediu',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          for (final i in p.itens)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${i.qtd}x',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: laranja)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(i.nome,
                                        style: const TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(reais(i.total),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Total',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                              ),
                              Text(reais(p.total),
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'O valor fica na sua comanda e é pago no caixa.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onContinuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Continuar',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etiqueta(String rotulo, String valor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: '$rotulo '),
            TextSpan(
                text: valor,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
          style: const TextStyle(fontSize: 18),
        ),
      );
}

/// Resumo do que foi para a comanda (a tela fica certa mesmo depois de
/// limpar o carrinho)
class PedidoEnviado {
  const PedidoEnviado({
    required this.mesa,
    required this.comanda,
    required this.itens,
    required this.total,
  });
  final String mesa;
  final String comanda;
  final List<({int qtd, String nome, double total})> itens;
  final double total;
}
