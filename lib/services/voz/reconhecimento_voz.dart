// Fala -> texto pelo próprio navegador do celular (Web Speech API), sem
// custo e sem servidor. Fora do navegador (testes) o microfone não aparece.
export 'reconhecimento_voz_stub.dart'
    if (dart.library.js_interop) 'reconhecimento_voz_web.dart';
