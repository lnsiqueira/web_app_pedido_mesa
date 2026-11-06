import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/detector_nativo.dart';
import 'package:webapp_pedido_mesa/services/comanda_service.dart';
import 'package:webapp_pedido_mesa/widgets/botao_chamar_garcom.dart';

const _laranja = Color(0xFFE8710A);

/// Quantas leituras seguidas do MESMO código para aceitar (como no tablet):
/// evita aceitar um número errado lido num quadro ruim.
const _leiturasIguais = 2;

/// Se a câmera não abrir nesse tempo, mostra o aviso com "Tentar de novo"
const _tempoParaAbrir = Duration(seconds: 12);

/// Lê a comanda pelo código de barras com a câmera do celular (o cliente não
/// digita mais o número). Confere a comanda na Bratter e devolve o número
/// (sem os zeros da etiqueta) via `Navigator.pop`; null se fechar.
class ScannerComandaPage extends StatefulWidget {
  const ScannerComandaPage({super.key, this.consultar = consultarComanda});

  /// Confere a comanda na Bratter (troca só nos testes)
  final Future<ConsultaComanda> Function(String comanda) consultar;

  @override
  State<ScannerComandaPage> createState() => _ScannerComandaPageState();
}

class _ScannerComandaPageState extends State<ScannerComandaPage>
    with SingleTickerProviderStateMixin {
  final _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    // liga aqui mesmo (_ligar), para não perder erro: o MobileScanner engole
    // erro que não seja MobileScannerException e a tela fica preta
    autoStart: false,
  );

  /// Erro ao ligar a câmera que o plugin não trata: mostra o aviso
  String? _erroAoLigar;

  /// Linha de leitura que corre dentro da janela
  late final _laser = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  String? _ultimoLido;
  int _vezesSeguidas = 0;

  /// Número em conferência na Bratter (mostra "Verificando...")
  String? _verificando;
  String? _erro;

  /// Número recusado e quando: a etiqueta continua na frente da câmera, então
  /// não consulta de novo o mesmo número logo em seguida
  String? _recusado;
  DateTime? _recusadoEm;

  bool _concluido = false;

  /// Quando pediu para abrir a câmera; se não abrir a tempo, mostra o aviso
  /// com "Tentar de novo" em vez de ficar preto
  DateTime _abriuEm = DateTime.now();
  bool _travou = false;
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    // leitor de código de barras (ZXing) vem do próprio site, não do
    // unpkg.com: no Safari do iPhone o de fora não carregava e a câmera
    // ficava preta. Precisa ser antes da câmera ligar.
    MobileScannerPlatform.instance
        .setBarcodeLibraryScriptUrl('zxing/zxing.min.js');
    _ligar();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final estado = _camera.value;
      final travou = !estado.isRunning &&
          estado.error == null &&
          DateTime.now().difference(_abriuEm) > _tempoParaAbrir;
      if (travou != _travou) setState(() => _travou = travou);
    });
    // leitor nativo do navegador (Android), junto com o ZXing do plugin
    if (temDetectorNativo) {
      _nativo = Timer.periodic(const Duration(milliseconds: 250), (_) async {
        if (_lendoNativo || _concluido || _verificando != null) return;
        _lendoNativo = true;
        try {
          final codigo = await lerComDetectorNativo();
          if (mounted && codigo != null) _registrarLeitura(codigo);
        } finally {
          _lendoNativo = false;
        }
      });
    }
  }

  Timer? _nativo;
  bool _lendoNativo = false;

  @override
  void dispose() {
    _relogio?.cancel();
    _nativo?.cancel();
    _laser.dispose();
    _camera.dispose();
    super.dispose();
  }

  bool get _semImagem => _travou || _erroAoLigar != null;

  Future<void> _ligar() async {
    try {
      await _camera.start();
    } catch (e) {
      debugPrint('Câmera: $e');
      if (mounted) setState(() => _erroAoLigar = '$e');
    }
  }

  Future<void> _tentarDeNovo() async {
    setState(() {
      _travou = false;
      _erroAoLigar = null;
      _abriuEm = DateTime.now();
    });
    try {
      await _camera.stop();
    } catch (_) {}
    await _ligar();
  }

  void _onDetect(BarcodeCapture captura) {
    if (captura.barcodes.isEmpty) return;
    final codigo = captura.barcodes.first.rawValue;
    if (codigo == null || codigo.isEmpty) return;
    _registrarLeitura(codigo);
  }

  /// Leitura do ZXing (plugin) ou do leitor nativo do navegador.
  void _registrarLeitura(String codigo) {
    if (_concluido || _verificando != null) return;
    if (codigo == _ultimoLido) {
      _vezesSeguidas++;
    } else {
      _ultimoLido = codigo;
      _vezesSeguidas = 1;
    }
    if (_vezesSeguidas < _leiturasIguais) return;

    final numero = numeroDaComanda(codigo);
    if (numero.isEmpty) return;
    if (numero == _recusado &&
        DateTime.now().difference(_recusadoEm!) < const Duration(seconds: 4)) {
      return;
    }
    _conferir(numero);
  }

  Future<void> _conferir(String numero) async {
    setState(() {
      _verificando = numero;
      _erro = null;
    });
    final r = await widget.consultar(numero);
    if (!mounted) return;
    if (r == ConsultaComanda.valida) {
      _concluido = true;
      numeroComanda = numero;
      await _camera.stop();
      if (mounted) Navigator.pop(context, numero);
      return;
    }
    setState(() {
      _verificando = null;
      _ultimoLido = null;
      _vezesSeguidas = 0;
      _recusado = numero;
      _recusadoEm = DateTime.now();
      _erro = r == ConsultaComanda.naoEncontrada
          ? 'Comanda $numero não encontrada. Tente de novo ou chame um '
              'atendente.'
          : 'Não foi possível conferir a comanda. Verifique a internet e '
              'tente de novo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, c) {
        final janela = _janela(c.biggest);
        // tudo posicionado: o Stack ocupa a tela inteira
        return Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _camera,
                fit: BoxFit.cover,
                onDetect: _onDetect,
                errorBuilder: (context, erro, _) => _semCamera(erro),
              ),
            ),
            // câmera não abriu a tempo ou falhou fora do plugin
            if (_semImagem) Positioned.fill(child: _semCamera(null)),
            // escuro fora da janela, cantos laranja e a linha de leitura
            // (some se a câmera não abriu: fica só a mensagem de erro)
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: _camera,
                  builder: (_, estado, __) => estado.error != null || _semImagem
                      ? const SizedBox.shrink()
                      : AnimatedBuilder(
                          animation: _laser,
                          builder: (_, __) => CustomPaint(
                            painter: _PintorJanela(janela, _laser.value,
                                ativo: _verificando == null),
                          ),
                        ),
                ),
              ),
            ),
            // topo: fechar e título
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Fechar',
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Escaneie sua comanda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // instrução logo abaixo da janela
            Positioned(
              left: 24,
              right: 24,
              top: janela.bottom + 22,
              child: ValueListenableBuilder<MobileScannerState>(
                valueListenable: _camera,
                builder: (_, estado, instrucao) =>
                    estado.error != null || _semImagem
                        ? const SizedBox.shrink()
                        : instrucao!,
                child: Column(
                  children: [
                    const Text(
                      'Encaixe o código de barras\nda comanda no retângulo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Segure parado, a um palmo da câmera.\n'
                      'Se brilhar, incline um pouco a comanda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // embaixo: situação da leitura e ajuda
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_verificando != null)
                        _Aviso(
                          icone: null,
                          texto: 'Verificando comanda $_verificando...',
                          cor: Colors.white,
                          fundo: Colors.black.withOpacity(0.6),
                        )
                      else if (_erro != null)
                        _Aviso(
                          icone: Icons.error_outline_rounded,
                          texto: _erro!,
                          cor: Colors.white,
                          fundo: Colors.red.shade700,
                        ),
                      const SizedBox(height: 12),
                      const BotaoChamarGarcom(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Janela no formato de código de barras: larga e baixa, um pouco acima do
  /// meio da tela
  Rect _janela(Size tela) {
    final largura = (tela.width * 0.84).clamp(0.0, 440.0);
    // tela baixa: janela menor e mais alta, para a instrução caber
    final baixa = tela.height < 700;
    final altura =
        (largura * 0.46).clamp(0.0, tela.height * (baixa ? 0.24 : 0.3));
    return Rect.fromCenter(
      center: Offset(tela.width / 2, tela.height * (baixa ? 0.34 : 0.42)),
      width: largura,
      height: altura,
    );
  }

  /// [erro] null: a câmera não abriu a tempo, sem erro do navegador.
  Widget _semCamera(MobileScannerException? erro) {
    final negado = erro?.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: const Color(0xFF1C1C1C),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_outlined,
              color: Colors.white54, size: 52),
          const SizedBox(height: 16),
          Text(
            negado
                ? 'Precisamos da câmera para ler a comanda'
                : 'Não foi possível abrir a câmera',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            negado
                ? 'Permita o acesso à câmera quando o navegador pedir, ou nas '
                    'configurações do navegador, e toque em Tentar de novo.'
                : 'Toque em Tentar de novo. Se não funcionar, chame um '
                    'atendente.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 15,
                height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _tentarDeNovo,
            style: FilledButton.styleFrom(
              backgroundColor: _laranja,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar de novo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icone,
    required this.texto,
    required this.cor,
    required this.fundo,
  });

  final IconData? icone;
  final String texto;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (icone == null)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: cor),
            )
          else
            Icon(icone, color: cor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                  color: cor, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Escurece fora da janela e desenha os cantos laranja (mesma ideia do
/// tablet) e a linha de leitura.
class _PintorJanela extends CustomPainter {
  _PintorJanela(this.janela, this.laser, {required this.ativo});

  final Rect janela;

  /// Posição da linha de leitura (0 = topo, 1 = base)
  final double laser;

  /// false enquanto confere a comanda (linha some)
  final bool ativo;

  static const _raio = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(janela, const Radius.circular(_raio));
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(rr),
      Paint()..color = Colors.black.withOpacity(0.62),
    );

    // borda fina
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withOpacity(0.35),
    );

    // cantos laranja na mesma curva da janela
    final canto = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = _laranja;
    const reta = 26.0;
    final r = janela;
    for (final (x, y, dx, dy) in [
      (r.left, r.top, 1.0, 1.0),
      (r.right, r.top, -1.0, 1.0),
      (r.left, r.bottom, 1.0, -1.0),
      (r.right, r.bottom, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + dy * (_raio + reta))
          ..lineTo(x, y + dy * _raio)
          ..arcToPoint(
            Offset(x + dx * _raio, y),
            radius: const Radius.circular(_raio),
            clockwise: dx * dy > 0,
          )
          ..lineTo(x + dx * (_raio + reta), y),
        canto,
      );
    }

    if (!ativo) return;
    // linha de leitura
    final y = r.top + 14 + (r.height - 28) * laser;
    final margem = r.width * 0.08;
    canvas.drawLine(
      Offset(r.left + margem, y),
      Offset(r.right - margem, y),
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [
          _laranja.withOpacity(0),
          _laranja,
          _laranja.withOpacity(0),
        ]).createShader(Rect.fromLTWH(r.left, y - 2, r.width, 4)),
    );
  }

  @override
  bool shouldRepaint(_PintorJanela old) =>
      old.laser != laser || old.janela != janela || old.ativo != ativo;
}
