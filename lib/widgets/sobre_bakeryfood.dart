import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _site = 'https://www.bakeryfood.com.br/?origem=adesivo-totem';
const _laranja = Color(0xFFE8710A);
const _texto = Color(0xFF2B2B2B);

/// Janela "Sobre a BakeryFood" (toque no rodapé "Desenvolvido por
/// BakeryFood"): logo, os produtos e o QR code para o site.
void mostrarSobreBakeryFood(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints:
        BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _Sobre(),
  );
}

class _Sobre extends StatelessWidget {
  const _Sobre();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Image.asset('images/bakeryfood/logo.webp', height: 44),
            const SizedBox(height: 14),
            const Text(
              'Tecnologia para o seu negócio: do pedido '
              'ao pagamento, tudo integrado e simples de usar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.4, color: _texto),
            ),
            const SizedBox(height: 20),
            const _Produto(
              imagem: 'images/bakeryfood/totem.webp',
              titulo: 'Totem de autoatendimento',
              texto: 'O cliente escolhe, paga e pronto: menos fila no caixa.',
            ),
            const _Produto(
              imagem: 'images/bakeryfood/mesa.webp',
              titulo: 'Cardápio de mesa',
              texto: 'Tablet e QR code na mesa: o pedido vai direto para a '
                  'comanda e para a cozinha.',
            ),
            const _Produto(
              imagem: 'images/bakeryfood/dashboard.webp',
              titulo: 'Dashboard',
              texto: 'Vendas, fiscal, cardápio e unidades na palma da mão, '
                  'em tempo real.',
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: () => launchUrl(Uri.parse(_site),
                  mode: LaunchMode.externalApplication),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(6),
                      child: const SizedBox(
                        width: 92,
                        height: 92,
                        child: CustomPaint(painter: _QrPainter(_site)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Conheça a BakeryFood',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _texto)),
                          SizedBox(height: 4),
                          Text('Aponte a câmera ou toque aqui',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                          SizedBox(height: 2),
                          Text('bakeryfood.com.br',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _laranja)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Produto extends StatelessWidget {
  const _Produto(
      {required this.imagem, required this.titulo, required this.texto});

  final String imagem;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(imagem, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _texto)),
                const SizedBox(height: 3),
                Text(texto,
                    style: const TextStyle(
                        fontSize: 13, height: 1.35, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// QR code desenhado na tela (sem imagem externa)
class _QrPainter extends CustomPainter {
  const _QrPainter(this.dados);

  final String dados;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _texto;
    for (final e in Barcode.qrCode()
        .make(dados, width: size.width, height: size.height, drawText: false)) {
      if (e is BarcodeBar && e.black) {
        canvas.drawRect(Rect.fromLTWH(e.left, e.top, e.width, e.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.dados != dados;
}
