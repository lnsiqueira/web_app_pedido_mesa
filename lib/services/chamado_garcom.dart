import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';

/// Chamados de garçom, no mesmo formato do cardápio de mesa do tablet: a tela
/// KDS (dashboard e tablet) mostra os chamados do dia não atendidos.
const _colecao = 'ChamadosGarcom';

String _dia(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Registra o chamado da mesa do QR code. Retorna false se não conseguiu
/// gravar.
Future<bool> chamarGarcom() async {
  try {
    final agora = DateTime.now();
    await FirebaseFirestore.instance.collection(_colecao).add({
      'codFilial': codFilial,
      // dia local: o KDS busca por filial + dia (atendido é filtrado na tela)
      'dia': _dia(agora),
      'mesa': numeroMesa.trim(),
      'origem': 'site_qrcode',
      'criadoEm': Timestamp.fromDate(agora),
      'atendido': false,
    }).timeout(const Duration(seconds: 10));
    return true;
  } catch (e) {
    debugPrint('Erro ao chamar garçom: $e');
    return false;
  }
}
