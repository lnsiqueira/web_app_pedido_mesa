import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/core/constants.dart';

/// Resultado da consulta da comanda na Bratter.
enum ConsultaComanda { valida, naoEncontrada, falha }

/// Número da comanda lido no código de barras, como no tablet: só os
/// dígitos e sem os zeros à esquerda da etiqueta ("000156" → "156").
/// Vazio se não tiver número.
String numeroDaComanda(String lido) {
  final digitos = lido.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.isEmpty) return '';
  final semZeros = digitos.replaceFirst(RegExp(r'^0+'), '');
  return semZeros.isEmpty ? '' : semZeros;
}

/// Aceita só comanda cadastrada: livre (00/01) ou em uso (02). Id 0 sem
/// status = comanda que não existe na Bratter: o POST responde 200 mas
/// descarta os itens.
Future<ConsultaComanda> consultarComanda(String comanda) async {
  final encodedUrl = Uri.encodeComponent(Urls.urlApiBratter);
  final url = '${Urls.urlApiAzure}Proxy/ConsultaComanda/'
      '?urlBratter=$encodedUrl&tokenBratter=${GlobalKeys.tokenBratter}'
      '&idComanda=$comanda';
  try {
    final r = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) return ConsultaComanda.falha;
    final status = jsonDecode(r.body)['Status']?.toString();
    return status == '00' || status == '01' || status == '02'
        ? ConsultaComanda.valida
        : ConsultaComanda.naoEncontrada;
  } catch (_) {
    return ConsultaComanda.falha;
  }
}
