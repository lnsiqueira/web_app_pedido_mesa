import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/core/atualizacao/recarregar.dart';

/// Versão deste build, gravada pelo publicar.sh (data e hora). Vazia no
/// `flutter run`: aí a verificação fica desligada.
const versaoDoApp = String.fromEnvironment('APP_VERSAO');

/// Só o número da versão ("1.0.0 - 06/11/2026 11:29" → "1.0.0"), para mostrar
/// no rodapé.
String get numeroDaVersao => versaoDoApp.split(' - ').first.trim();

/// Atualização automática: confere o versao.json publicado a cada 3 minutos
/// e sempre que a pessoa volta para a aba; se saiu versão nova, recarrega a
/// página sozinho. Não recarrega no meio de um pedido ([podeRecarregar]
/// falso: carrinho com itens, outra tela ou janela aberta) e tenta de novo
/// logo depois.
class AtualizacaoAutomatica {
  AtualizacaoAutomatica._();

  static const _intervalo = Duration(minutes: 3);
  static const _esperaOcupado = Duration(seconds: 30);

  static Timer? _timer;
  // guardado para o listener continuar ativo
  // ignore: unused_field
  static AppLifecycleListener? _ciclo;
  static bool _conferindo = false;

  /// Diz se dá para recarregar agora sem atrapalhar o cliente.
  static bool Function() podeRecarregar = () => true;

  static void iniciar({required bool Function() podeRecarregar}) {
    if (!kIsWeb || versaoDoApp.isEmpty || _timer != null) return;
    AtualizacaoAutomatica.podeRecarregar = podeRecarregar;
    _agendar(_intervalo);
    _ciclo = AppLifecycleListener(onResume: conferir);
  }

  static void _agendar(Duration d) {
    _timer?.cancel();
    _timer = Timer(d, conferir);
  }

  static Future<void> conferir() async {
    if (_conferindo) return;
    _conferindo = true;
    try {
      final publicada = await versaoPublicada();
      if (publicada == null || publicada == versaoDoApp) {
        _agendar(_intervalo);
        return;
      }
      if (!podeRecarregar()) {
        _agendar(_esperaOcupado);
        return;
      }
      debugPrint('Nova versão $publicada (rodando $versaoDoApp): recarregando');
      recarregarPagina();
    } finally {
      _conferindo = false;
    }
  }

  /// Versão do versao.json publicado; null se não conseguiu ler.
  static Future<String?> versaoPublicada() async {
    try {
      final r = await http.get(
        Uri.base
            .resolve('versao.json?t=${DateTime.now().millisecondsSinceEpoch}'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return null;
      final v = jsonDecode(r.body)['versao']?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }
}
