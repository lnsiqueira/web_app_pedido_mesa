import 'package:flutter/material.dart';

class QuartoNomeModel extends ChangeNotifier {
  String _quarto = '';
  String _nome = '';

  String get mesa => _quarto;
  String get comanda => _nome;

  void setMesa(String value) {
    _quarto = value;
    notifyListeners();
  }

  void setComanda(String value) {
    _nome = value;
    notifyListeners();
  }

  void limpar() {
    _quarto = '';
    _nome = '';
    notifyListeners();
  }
}
