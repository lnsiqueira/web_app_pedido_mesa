import 'package:flutter/widgets.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/filial_nf_model.dart';

FilialNFModel? globalFilialData;

class GlobalKeys {
  static const String idioma = '';
  static const String codFilial = '8urs76lF1QwjcNpi3CwD';
  static const String descricaoFilial = 'Lapa';
  static const String codEmpresa = '1';
  static const String descricaoEmpresa = 'Dona Deola';

  static const ambienteNfe = 'H';
  static const userApiBratter = 'ConexaoMovel';
  static const passwordApiBratter = '20250301';
  static String tokenBratter = '';
  static const String serieNfe = '1';
  static String numSequencialNfe = '';
  static String base64Nfe = '';
  static String errroResponse = '';
  static String errroResponseStatusCode = '';
  static int idInvoice = 0;
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

  static const String urlApiPagtoAzure =
      'https://webapi-sispagamento-hnabgfa6h9h7hrg3.brazilsouth-01.azurewebsites.net/api/';

  static const String urlApiBratter =
      'http://dd-lapa.ddns.com.br:1974/DeolaApi/api/';
  static String urlApimEmissaoNFe =
      GlobalKeys.ambienteNfe == "H"
          ? 'http://helpmachine.ddns.com.br:9006/nfe'
          : 'http://192.168.0.100:9005/nfe';
}
