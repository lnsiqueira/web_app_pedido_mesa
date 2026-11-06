import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// ignore: implementation_imports
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
// ignore: implementation_imports
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:webapp_pedido_mesa/screens/carrinho/scanner_comanda_page.dart';
import 'package:webapp_pedido_mesa/services/comanda_service.dart';

/// Câmera de mentira: mostra um fundo cinza e deixa o teste "ler" códigos.
class _CameraFalsa extends MobileScannerPlatform
    with MockPlatformInterfaceMixin {
  final codigos = StreamController<BarcodeCapture?>.broadcast();

  void ler(String codigo) =>
      codigos.add(BarcodeCapture(barcodes: [Barcode(rawValue: codigo)]));

  @override
  Stream<BarcodeCapture?> get barcodesStream => codigos.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.blueGrey);
  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async =>
      const MobileScannerViewAttributes(
        currentTorchMode: TorchState.unavailable,
        numberOfCameras: 1,
        size: Size(1280, 720),
      );
  @override
  Future<void> stop() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<void> updateScanWindow(Rect? window) async {}
  @override
  Future<void> resetZoomScale() async {}
  @override
  Future<void> setZoomScale(double zoomScale) async {}
  @override
  Future<void> toggleTorch() async {}
}

/// Abre o scanner por cima de uma tela e devolve o que ele retornou.
Future<List<String?>> _abrir(
  WidgetTester tester,
  Future<ConsultaComanda> Function(String) consultar, {
  Size tela = const Size(390, 760),
}) async {
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final resultado = <String?>[];
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async => resultado.add(await Navigator.push<String>(
            context,
            MaterialPageRoute(
                builder: (_) => ScannerComandaPage(consultar: consultar)),
          )),
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  return resultado;
}

late _CameraFalsa camera;

void registrarCameraFalsa() {
  camera = _CameraFalsa();
  MobileScannerPlatform.instance = camera;
}

void main() {
  setUp(registrarCameraFalsa);

  for (final tela in const [Size(320, 568), Size(390, 760), Size(430, 900)]) {
    testWidgets('tela do scanner cabe em $tela', (tester) async {
      await _abrir(tester, (_) async => ConsultaComanda.valida, tela: tela);
      expect(find.text('Escaneie sua comanda'), findsOneWidget);
      expect(find.textContaining('Encaixe o código de barras'), findsOneWidget);
      expect(find.text('Chamar garçom'), findsOneWidget);
      // título no topo, instrução no meio e Chamar garçom embaixo
      final titulo = tester.getRect(find.text('Escaneie sua comanda'));
      final instrucao =
          tester.getRect(find.textContaining('Segure parado'));
      final garcom = tester.getRect(find.text('Chamar garçom'));
      expect(titulo.bottom, lessThan(80));
      expect(instrucao.top, greaterThan(titulo.bottom));
      expect(instrucao.bottom, lessThan(garcom.top));
      expect(garcom.bottom, greaterThan(tela.height - 80));
      expect(garcom.bottom, lessThanOrEqualTo(tela.height));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('só aceita depois de 2 leituras iguais e tira os zeros',
      (tester) async {
    final consultadas = <String>[];
    final resultado = await _abrir(tester, (c) async {
      consultadas.add(c);
      return ConsultaComanda.valida;
    });

    camera.ler('000156');
    await tester.pump();
    camera.ler('000157'); // leitura diferente recomeça a contagem
    await tester.pump();
    camera.ler('000156');
    await tester.pump();
    expect(consultadas, isEmpty);

    camera.ler('000156');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(consultadas, ['156']);
    expect(resultado, ['156']);
  });

  testWidgets('comanda inexistente mostra aviso e continua lendo',
      (tester) async {
    final resultado =
        await _abrir(tester, (_) async => ConsultaComanda.naoEncontrada);
    for (var i = 0; i < 3; i++) {
      camera.ler('0380');
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Comanda 380 não encontrada'), findsOneWidget);
    expect(resultado, isEmpty); // continua na tela do scanner
    expect(find.text('Escaneie sua comanda'), findsOneWidget);
  });

  testWidgets('X fecha sem comanda', (tester) async {
    final resultado = await _abrir(tester, (_) async => ConsultaComanda.valida);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(resultado, [null]);
  });
}
