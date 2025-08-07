import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';

class PedidoModel {
  String pedidoId;
  final String codEmpresa;
  final String codFilial;
  final Timestamp dataHoraPedido;
  final String deviceToken;
  final List<ItemModel> itens;
  final double total;
  final bool pedidoPago;
  final String comanda;
  String? serieNfe;
  String? ambiente;
  double? vlrDescontoEmbalagem;
  String? json;
  String? chave;
  bool? pedidoMesa;
  String? mesa;

  PedidoModel({
    required this.pedidoId,
    required this.codEmpresa,
    required this.codFilial,
    required this.dataHoraPedido,
    required this.deviceToken,
    required this.itens,
    required this.total,
    required this.pedidoPago,
    required this.comanda,
    this.serieNfe,
    this.ambiente,
    this.vlrDescontoEmbalagem,
    this.json,
    this.chave,
    this.pedidoMesa = false,
    this.mesa,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': pedidoId,
      'codEmpresa': codEmpresa,
      'codFilial': codFilial,
      'dataHoraPedido': dataHoraPedido,
      'deviceToken': deviceToken,
      'itens': itens.map((item) => item.toMap()).toList(),
      'total': total,
      'pedidoPago': pedidoPago,
      'comanda': comanda,
      'serieNfe': serieNfe,
      'ambiente': ambiente,
      'vlrDescontoEmbalagem': vlrDescontoEmbalagem,
      'json': json,
      'chave': chave,
      'pedidoMesa': pedidoMesa,
      'mesa': mesa,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

class PedidoModelNfe {
  String pedidoId;
  final String codEmpresa;
  final String codFilial;
  final DateTime dataHoraPedido;
  final String deviceToken;
  final List<ItemModel> itens;
  final double total;
  final bool pedidoPago;
  final String comanda;
  String? serieNfe;
  String? ambiente;
  double? vlrDescontoEmbalagem;

  PedidoModelNfe({
    required this.pedidoId,
    required this.codEmpresa,
    required this.codFilial,
    required this.dataHoraPedido,
    required this.deviceToken,
    required this.itens,
    required this.total,
    required this.pedidoPago,
    required this.comanda,
    this.serieNfe,
    this.ambiente,
    this.vlrDescontoEmbalagem,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': pedidoId,
      'codEmpresa': codEmpresa,
      'codFilial': codFilial,
      'dataHoraPedido': dataHoraPedido.toIso8601String(),
      'deviceToken': deviceToken,
      'itens': itens.map((item) => item.toMap()).toList(),
      'total': total,
      'pedidoPago': pedidoPago,
      'comanda': comanda,
      'serieNfe': serieNfe,
      'ambiente': ambiente,
      'vlrDescontoEmbalagem': vlrDescontoEmbalagem,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
