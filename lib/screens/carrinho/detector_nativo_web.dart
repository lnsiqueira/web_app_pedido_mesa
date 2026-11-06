import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

/// O navegador tem leitor nativo (Chrome / Samsung Internet no Android): lê
/// muito melhor que o ZXing com reflexo e foco ruim. No Safari do iPhone não
/// existe e fica só o ZXing do mobile_scanner.
bool get temDetectorNativo => globalContext.has('BarcodeDetector');

JSObject? _detector;

/// Procura código de barras no quadro atual do vídeo da câmera.
Future<String?> lerComDetectorNativo() async {
  if (!temDetectorNativo) return null;
  try {
    final documento = globalContext['document'] as JSObject;
    final video =
        documento.callMethod<JSObject?>('querySelector'.toJS, 'video'.toJS);
    if (video == null) return null;
    // ainda sem imagem
    final pronto = (video['readyState'] as JSNumber?)?.toDartInt ?? 0;
    if (pronto < 2) return null;
    _detector ??= (globalContext['BarcodeDetector'] as JSFunction)
        .callAsConstructor<JSObject>();
    final achados = await _detector!
        .callMethod<JSPromise<JSArray<JSObject>>>('detect'.toJS, video)
        .toDart;
    for (final a in achados.toDart) {
      final valor = (a['rawValue'] as JSString?)?.toDart ?? '';
      if (valor.isNotEmpty) return valor;
    }
  } catch (e) {
    debugPrint('Leitor nativo: $e');
  }
  return null;
}
