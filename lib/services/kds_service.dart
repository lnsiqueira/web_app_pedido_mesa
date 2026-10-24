import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';

/// Registra o pedido para o KDS (tela "Pedidos das mesas" da Dashboard), no
/// mesmo formato do cardápio de mesa do tablet (coleção `pedidos_mesa`).
/// Só para exibição: se falhar, o pedido segue normal (já foi para a comanda).
void registrarPedidoKds({
  required String comanda,
  required String mesa,
  required List<ItemCarrinho> itens,
}) {
  if (mesa.trim().isEmpty || itens.isEmpty) return;
  final agora = DateTime.now();
  final dia = '${agora.year}-${agora.month.toString().padLeft(2, '0')}-'
      '${agora.day.toString().padLeft(2, '0')}';
  unawaited(FirebaseFirestore.instance
      .collection('pedidos_mesa')
      .add({
        'codFilial': codFilial,
        // dia local: o KDS busca por filial + dia
        'dia': dia,
        'mesa': mesa.trim(),
        'comanda': comanda,
        'origem': 'site_qrcode',
        'criadoEm': Timestamp.fromDate(agora),
        'itens': [
          for (final i in itens)
            {
              'nome': (i.produto.desProduto ?? '').trim(),
              'qtd': i.quantidade,
              'opcoes': const <String>[],
              'acrescimos': [
                for (final a in i.produto.acrescimos) a.nome,
                for (final o in i.produto.obs ?? const [])
                  if (o.modificador == 'C' || o.modificador == 'S') o.titulo,
              ],
              if ((i.produto.obs ?? const [])
                  .any((o) => o.tipo == 'texto' && o.titulo.trim().isNotEmpty))
                'obs': i.produto.obs!
                    .where((o) => o.tipo == 'texto' && o.titulo.trim().isNotEmpty)
                    .map((o) => o.titulo.trim())
                    .join(' · '),
            },
        ],
      })
      .timeout(const Duration(seconds: 10))
      .catchError((e) {
        debugPrint('Erro ao registrar pedido no KDS: $e');
        return FirebaseFirestore.instance.collection('pedidos_mesa').doc();
      }));
}
