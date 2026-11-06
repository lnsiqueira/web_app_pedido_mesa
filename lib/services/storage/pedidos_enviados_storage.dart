import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/pagamento/pedido_enviado_view.dart';

/// Pedido que este celular enviou para a comanda (para o "Meus pedidos").
class PedidoSalvo {
  const PedidoSalvo(this.quando, this.pedido);
  final DateTime quando;
  final PedidoEnviado pedido;
}

/// Pedidos enviados deste celular hoje. Fica salvo no navegador, separado do
/// carrinho (que é limpo ao abrir o site e ao enviar).
class PedidosEnviadosStorage {
  static const _chave = 'pedidos_enviados';

  /// Mantém só os últimos (o "Meus pedidos" mostra os de hoje)
  static const _maximo = 30;

  static Future<void> salvar(PedidoEnviado p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = prefs.getStringList(_chave) ?? [];
      lista.add(jsonEncode({
        'quando': DateTime.now().toIso8601String(),
        'mesa': p.mesa,
        'comanda': p.comanda,
        'total': p.total,
        'itens': [
          for (final i in p.itens)
            {'qtd': i.qtd, 'nome': i.nome, 'total': i.total},
        ],
      }));
      if (lista.length > _maximo) {
        lista.removeRange(0, lista.length - _maximo);
      }
      await prefs.setStringList(_chave, lista);
    } catch (e) {
      debugPrint('Erro ao salvar pedido enviado: $e');
    }
  }

  /// Pedidos de hoje, o mais recente primeiro.
  static Future<List<PedidoSalvo>> deHoje() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final agora = DateTime.now();
      final r = <PedidoSalvo>[];
      for (final s in prefs.getStringList(_chave) ?? const <String>[]) {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final quando = DateTime.tryParse('${m['quando']}');
        if (quando == null ||
            quando.year != agora.year ||
            quando.month != agora.month ||
            quando.day != agora.day) {
          continue;
        }
        r.add(PedidoSalvo(
          quando,
          PedidoEnviado(
            mesa: '${m['mesa'] ?? ''}',
            comanda: '${m['comanda'] ?? ''}',
            total: (m['total'] as num?)?.toDouble() ?? 0,
            itens: [
              for (final i in (m['itens'] as List? ?? const []))
                (
                  qtd: (i['qtd'] as num?)?.toInt() ?? 1,
                  nome: '${i['nome'] ?? ''}',
                  total: (i['total'] as num?)?.toDouble() ?? 0,
                ),
            ],
          ),
        ));
      }
      return r.reversed.toList();
    } catch (e) {
      debugPrint('Erro ao ler pedidos enviados: $e');
      return const [];
    }
  }
}
