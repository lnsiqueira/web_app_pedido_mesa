import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';

Future<bool> atualizarCardapioDiario() async {
  final url = Uri.parse(
    '${Urls.urlApiAzureCardapioDiario}CardapioHospital/alimentar-diario',
  );

  final body = {
    "idFilial": "1768831340259",
    "dataCardapio": DateTime.now().toIso8601String(),
    "criadoPor": "userTeste",
  };

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    // final jsonBody = jsonEncode(body);

    // debugPrint('📤 BODY ENVIADO PARA API:');
    // debugPrint(jsonBody);
    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ Cardápio diário atualizado com sucesso');
      return true;
    } else {
      debugPrint(
        '❌ Erro ao atualizar cardápio: ${response.statusCode} - ${response.body}',
      );
    }
  } catch (e) {
    debugPrint('❌ Erro na requisição: $e');
  }
  return false;
}

Future<bool> ativarDesativarProduto({
  required int idProduto,
  required bool ativo,
}) async {
  final url = Uri.parse(
    '${Urls.urlApiAzureCardapioDiario}CardapioHospital/ativar-desativar',
  );

  final body = {
    "filialId": "1768831340259",
    "idProduto": idProduto,
    "dataCardapio": DateTime.now().toIso8601String(),
    "ativo": ativo,
  };

  try {
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    // final jsonBody = jsonEncode(body);

    // // debugPrint('📤 BODY ENVIADO PARA API:');
    // // debugPrint(jsonBody);
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    debugPrint('Erro ao ativar/desativar produto: $e');
    return false;
  }
}

Future<bool> atualizarQuantidadeProduto({
  required int idProduto,
  required int novaQuantidade,
}) async {
  final url = Uri.parse(
    '${Urls.urlApiAzureCardapioDiario}CardapioHospital/cardapio/atualizar-quantidade',
  );

  final body = {
    "filialId": "1768831340259",
    "idProduto": idProduto,
    "dataCardapio": DateTime.now().toIso8601String(),
    "novaQuantidade": novaQuantidade,
  };

  try {
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return response.statusCode == 200 || response.statusCode == 204;
  } catch (_) {
    return false;
  }
}

String dataHojeFormatada() {
  final now = DateTime.now();
  return '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}-'
      '${now.year}';
}

Future<bool> cardapioJaExisteHoje() async {
  final data = dataHojeFormatada();

  final url = Uri.parse(
    '${Urls.urlApiAzureCardapioDiario}CardapioHospital/cardapio-diario'
    '?filialId=1768831340259'
    '&data=$data',
  );

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final lista = body['cardapio'] as List?;

      return lista != null && lista.isNotEmpty;
    }

    return false;
  } catch (e) {
    debugPrint('Erro ao verificar cardápio do dia: $e');
    return false;
  }
}

Future<bool> baixarQuantidadeProdutos({
  required List<ItemModel> produtos,
}) async {
  final url = Uri.parse(
    '${Urls.urlApiAzureCardapioDiario}CardapioHospital/cardapio/baixar-quantidade',
  );

  try {
    final futures = produtos.where((p) => p.quantidade! > 0).map((produto) {
      final body = {
        "filialId": '1768831340259',
        "idProduto": produto.id!,
        "dataCardapio": DateTime.now().toUtc().toIso8601String(),
        "novaQuantidade": produto.quantidade,
      };
      final jsonBody = jsonEncode(body);

      debugPrint('📤 BODY ENVIADO PARA API:');
      debugPrint(jsonBody);
      return http.put(
        url,
        headers: const {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
    }).toList();

    final responses = await Future.wait(futures);

    for (final r in responses) {
      debugPrint('📥 STATUS CODE: ${r.statusCode}');
      debugPrint('📥 RESPONSE BODY: ${r.body}');
    }

    return responses.every((r) => r.statusCode == 200);
  } catch (e) {
    debugPrint('Erro ao baixar quantidades: $e');
    return false;
  }
}
