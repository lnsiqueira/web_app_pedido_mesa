import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/quarto_nome_model.dart';
import 'package:http/http.dart' as http;

// Future<String> gerarNovaComandaWebApp() async {
//   final firestore = FirebaseFirestore.instance;

//   final filialRef = firestore.collection('Filial').doc(codFilial);

//   return firestore.runTransaction((transaction) async {
//     final snapshot = await transaction.get(filialRef);

//     if (!snapshot.exists) {
//       throw Exception('Filial não encontrada');
//     }

//     final data = snapshot.data() as Map<String, dynamic>;

//     final String comandaAtualStr = data['comanda_atual_webapp'] ?? '0';

//     final int comandaAtual = int.tryParse(comandaAtualStr) ?? 0;
//     final int novaComanda = comandaAtual + 1;

//     final String novaComandaStr = novaComanda.toString();

//     /// 🔥 ATUALIZA NO FIREBASE
//     transaction.update(filialRef, {
//       'comanda_atual_webapp': novaComandaStr,
//     });

//     /// Retorna a nova comanda pra usar no pedido
//     return novaComandaStr;
//   });
// }

Future<String> gerarComandaLivreWebApp() async {
  final firestore = FirebaseFirestore.instance;
  final filialRef = firestore.collection('Filial').doc(codFilial);

  const int maxTentativas = 50; // pode ajustar conforme o range
  int tentativas = 0;

  while (tentativas < maxTentativas) {
    tentativas++;

    /// 1️⃣ Gera próxima comanda respeitando o RANGE
    final String novaComanda =
        await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(filialRef);

      if (!snapshot.exists) {
        throw Exception('Filial não encontrada');
      }

      final data = snapshot.data() as Map<String, dynamic>;

      final int comandaAtual =
          int.tryParse(data['comanda_atual_webapp'] ?? '0') ?? 0;

      final int comandaInicio =
          int.tryParse(data['comanda_inicio_webapp'] ?? '0') ?? 0;

      final int comandaFim =
          int.tryParse(data['comanda_fim_webapp'] ?? '0') ?? 0;

      int proximaComanda;

      /// 🔁 CONTROLE CIRCULAR
      if (comandaAtual >= comandaFim) {
        proximaComanda = comandaInicio;
      } else {
        proximaComanda = comandaAtual + 1;
      }

      final String novaComandaStr = proximaComanda.toString();

      transaction.update(filialRef, {
        'comanda_atual_webapp': novaComandaStr,
      });

      return novaComandaStr;
    });

    /// 2️⃣ Verifica se está livre
    final bool estaLivre = await comandaEstaLivre(novaComanda);

    if (estaLivre) {
      return novaComanda;
    }

    /// Pequeno delay opcional (evita spam extremo de API)
    await Future.delayed(const Duration(milliseconds: 150));
  }

  throw Exception(
    'Não foi possível gerar uma comanda livre após $maxTentativas tentativas.',
  );
}

Future<bool> comandaEstaLivre(String comanda) async {
  var urlBratter = Urls.urlApiBratter;
  final encodedUrl = Uri.encodeComponent(urlBratter);

  final url = '${Urls.urlApiAzure}Proxy/ConsultaComanda/'
      '?urlBratter=$encodedUrl'
      '&tokenBratter=${GlobalKeys.tokenBratter}'
      '&idComanda=$comanda';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    final double vlrComanda = (data['VlrComanda'] ?? 0).toDouble();
    final String status = data['Status'];

    if (vlrComanda == 0.0 && (status == '00' || status == '01')) {
      return true;
    }
  }

  return false;
}

Future<void> enviarPedidoFireBase({
  required String comanda,
  required CarrinhoModel carrinho,
  required BuildContext context,
}) async {
  final firestore = FirebaseFirestore.instance;

  // 🔥 Recupera o quarto e o nome direto do provider
  final quartoNome = Provider.of<QuartoNomeModel>(context, listen: false);

  final itens = carrinho.itens.map((item) {
    return {
      'id_produto': item.produto.id,
      'nome': item.produto.desProduto,
      'quantidade': item.quantidade,
      'valor_unitario': item.produto.preco,
      'total': item.quantidade * item.produto.preco!,
      'observacoes': item.produto.obs
              ?.where((obs) => obs.modificador != null)
              .map((obs) => obs.toMap())
              .toList() ??
          [],
    };
  }).toList();

  final total = itens.fold<double>(
    0,
    (sum, item) => sum + (item['total'] as double),
  );

  await firestore.collection('Pedidos_Web_App').add({
    'id_filial': codFilial,
    'des_empresa': '1',
    'dat_registro': FieldValue.serverTimestamp(),
    'comanda': comanda,
    'vlr_json': total,
    'IND_PAGO': 'ABERTO',
    'TIP_OPERACAO': 'WEB_APP',
    'quarto': quartoNome.mesa,
    'nome_cliente': quartoNome.comanda,
    'itens': itens,
  });
}

Future<List<QueryDocumentSnapshot>> buscarPedidosFirebase(
  BuildContext context,
) async {
  final firestore = FirebaseFirestore.instance;

  final quartoNome = Provider.of<QuartoNomeModel>(context, listen: false);

  final String quarto = quartoNome.mesa.trim();
  final String nome = quartoNome.comanda.trim();

  DateTime now = DateTime.now();
  DateTime inicioHoje = DateTime(now.year, now.month, now.day);
  DateTime fimHoje = inicioHoje.add(const Duration(days: 1));

  /// 🔹 1ª tentativa: data + quarto + nome
  Query query = firestore
      .collection('Pedidos_Web_App')
      .where('id_filial', isEqualTo: codFilial)
      .where('quarto', isEqualTo: quarto)
      .where('dat_registro',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoje))
      .where('dat_registro', isLessThan: Timestamp.fromDate(fimHoje));

  if (nome.isNotEmpty) {
    query = query.where('nome_cliente', isEqualTo: nome);
  }

  QuerySnapshot snapshot = await query.get();

  /// 🔁 Fallback: sem nome
  if (snapshot.docs.isEmpty && nome.isNotEmpty) {
    snapshot = await firestore
        .collection('Pedidos_Web_App')
        .where('id_filial', isEqualTo: codFilial)
        .where('quarto', isEqualTo: quarto)
        .where('dat_registro',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoje))
        .where('dat_registro', isLessThan: Timestamp.fromDate(fimHoje))
        .get();
  }

  return snapshot.docs;
}
