import 'package:flutter/material.dart';

class LanguageController extends ChangeNotifier {
  Locale _locale = const Locale('pt');

  Locale get locale => _locale;

  void changeLanguage(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
  }
}

// class LanguageController extends ChangeNotifier {
//   bool? isEnglish = true;
//   bool? isSpain = false;
//   bool? isPortuguese = false;

//   void toggleLanguage() {
//     notifyListeners();
//   }
// }
