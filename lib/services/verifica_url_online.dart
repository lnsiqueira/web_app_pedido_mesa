import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math';

import 'package:webapp_pedido_mesa/services/nfce/model/log_model.dart';

Future<bool> verificarUrlOnline(
  Log log,
  String url, {
  int maxTentativas = 3,
  Duration timeout = const Duration(seconds: 3),
}) async {
  int tentativaAtual = 0;
  final random = Random();

  while (tentativaAtual < maxTentativas) {
    tentativaAtual++;
    print('Tentativa $tentativaAtual/$maxTentativas - Verificando URL: $url');

    try {
      final response = await http.get(Uri.parse(url)).timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 400) {
        print('URL acessível: $url (Status: ${response.statusCode})');
        return true;
      } else {
        print('URL com problema: $url (Status: ${response.statusCode})');

        log.descricaoChave =
            '${log.descricaoChave} | Status: ${response.statusCode} | Erro: ${response.reasonPhrase}';

        return false;
      }
    } on TimeoutException {
      print('Timeout na tentativa $tentativaAtual');
      if (tentativaAtual == maxTentativas) {
        print('Falha após $maxTentativas tentativas - URL inacessível: $url');
        log.descricaoChave =
            '${log.descricaoChave} | Erro: Timeout na tentativa';

        //  await pedidoRepository.uploadPedidoContigencia();
        return false;
      }
    } catch (e) {
      print('Erro na tentativa $tentativaAtual: ${e.toString()}');
      if (tentativaAtual == maxTentativas) {
        print('Falha após $maxTentativas tentativas - URL inacessível: $url');
        //  await pedidoRepository.uploadPedidoContigencia();
        log.descricaoChave = '${log.descricaoChave}  | Erro: ${e.toString()}';

        return false;
      }
    }

    // Espera um tempo crescente entre tentativas (com jitter aleatório)
    if (tentativaAtual < maxTentativas) {
      final espera = Duration(
        milliseconds:
            min(1000 * pow(2, tentativaAtual).toInt(), 10000) +
            random.nextInt(1000),
      );
      print(
        '⏳ Aguardando ${espera.inMilliseconds}ms para próxima tentativa...',
      );
      await Future.delayed(espera);
    }
  }

  return false;
}
