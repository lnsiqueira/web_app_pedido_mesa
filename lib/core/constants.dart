import 'package:flutter/widgets.dart';

class GlobalKeys {
  static const String idioma = '';
  static const String codFilial = '8urs76lF1QwjcNpi3CwD';
  static const ambienteNfe = 'H';
  static const userApiBratter = 'ConexaoMovel';
  static const passwordApiBratter = '20250301';
}

class CustomColor {
  static const Color PRIMARY = Color(0xff62b7e0);
  static const Color ACCENT = Color(0xff0061aa);
  static const textColor = Color(0xFF333333);
  static const Color GreyCustom = Color(0xFF5F6269);
}

class Urls {
  static const String urlApiAzure =
      'https://webapi-sisfiscal-cqf7dxb8dkfye7ap.brazilsouth-01.azurewebsites.net/api/';
  static const String urlApiBratter = 'http://192.168.0.99:19974/DeolaApi/api/';
  static String urlApimEmissaoNFe =
      GlobalKeys.ambienteNfe == "H"
          ? 'http://helpmachine.ddns.com.br:9006/nfe'
          : 'http://192.168.0.100:9005/nfe';
}
