/// Leitor de código de barras do próprio navegador (BarcodeDetector), lendo
/// o vídeo da câmera do scanner. Fora da web devolve null.
export 'detector_nativo_stub.dart'
    if (dart.library.js_interop) 'detector_nativo_web.dart';
