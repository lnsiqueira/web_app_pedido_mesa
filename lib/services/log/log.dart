import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'dart:convert';

import 'package:webapp_pedido_mesa/services/nfce/model/log_model.dart';

class LogApiService {
  static gravarLog(Log log) async {
    try {
      var body = log.toJson();
      print(body);
      final response = await http.post(
        Uri.parse('${Urls.urlApiAzure}log/inserir'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Log gravado com sucesso: ${response.body}');
      } else {
        debugPrint(
          'Erro ao gravar log: ${response.statusCode} - ${response.body}',
        );
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Erro ao gravar log: $e');
      return false;
    }
  }
}
