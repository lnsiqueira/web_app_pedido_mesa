/// Recarrega a página (só na web; fora dela não faz nada).
export 'recarregar_stub.dart'
    if (dart.library.js_interop) 'recarregar_web.dart';
