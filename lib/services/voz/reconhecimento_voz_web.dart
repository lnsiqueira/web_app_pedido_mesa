import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Reconhecimento de voz do navegador (Chrome/Android, Safari/iPhone,
/// Edge). Firefox não tem: aí [disponivel] é false e o microfone some.
class ReconhecimentoVoz {
  JSObject? _rec;

  static JSFunction? get _construtor {
    for (final nome in ['SpeechRecognition', 'webkitSpeechRecognition']) {
      if (globalContext.has(nome)) return globalContext[nome] as JSFunction;
    }
    return null;
  }

  bool get disponivel => _construtor != null;
  bool get ouvindo => _rec != null;

  /// Começa a ouvir. [onTexto] recebe o que já foi entendido (vai
  /// melhorando enquanto a pessoa fala; [fim] = frase terminada).
  void iniciar({
    required String idioma,
    required void Function(String texto, bool fim) onTexto,
    required void Function() onFim,
    void Function(String erro)? onErro,
  }) {
    final construtor = _construtor;
    if (construtor == null || _rec != null) return;
    final rec = construtor.callAsConstructor<JSObject>();
    rec['lang'] = idioma.toJS;
    rec['interimResults'] = true.toJS;
    rec['continuous'] = false.toJS;
    rec['maxAlternatives'] = 1.toJS;

    rec['onresult'] = ((JSObject evento) {
      final resultados = evento['results'] as JSObject;
      final total = (resultados['length'] as JSNumber).toDartInt;
      final texto = StringBuffer();
      var fim = false;
      for (var i = 0; i < total; i++) {
        final r = resultados.callMethod<JSObject>('item'.toJS, i.toJS);
        final alt = r.callMethod<JSObject>('item'.toJS, 0.toJS);
        texto.write((alt['transcript'] as JSString).toDart);
        fim = (r['isFinal'] as JSBoolean).toDart;
      }
      onTexto(texto.toString().trim(), fim);
    }).toJS;

    rec['onerror'] = ((JSObject evento) {
      final erro = evento['error'];
      onErro?.call(erro.isA<JSString>() ? (erro as JSString).toDart : '');
    }).toJS;

    rec['onend'] = ((JSAny? _) {
      _rec = null;
      onFim();
    }).toJS;

    _rec = rec;
    try {
      rec.callMethod('start'.toJS);
    } catch (e) {
      _rec = null;
      onErro?.call('$e');
      onFim();
    }
  }

  void parar() => _rec?.callMethod('stop'.toJS);
}

/// Vibração curta do celular (Android; o iPhone ignora)
void vibrar(int milissegundos) {
  try {
    final navigator = globalContext['navigator'] as JSObject?;
    if (navigator != null && navigator.has('vibrate')) {
      navigator.callMethod('vibrate'.toJS, milissegundos.toJS);
    }
  } catch (_) {}
}
