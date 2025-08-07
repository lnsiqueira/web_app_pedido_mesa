import 'package:flutter/material.dart';

class MesaComandaModel extends ChangeNotifier {
  String _mesa = '';
  String _comanda = '';

  String get mesa => _mesa;
  String get comanda => _comanda;

  void setMesa(String value) {
    _mesa = value;
    notifyListeners();
  }

  void setComanda(String value) {
    _comanda = value;
    notifyListeners();
  }

  void limpar() {
    _mesa = '';
    _comanda = '';
    notifyListeners();
  }
}
