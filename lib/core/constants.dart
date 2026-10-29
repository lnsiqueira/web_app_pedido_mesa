import 'package:flutter/widgets.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/filial_nf_model.dart';

FilialNFModel? globalFilialData;

String codFilial = '';

/// Filial cujo cardápio (categorias/produtos) é exibido: a própria filial
/// ou, se ela ainda não tiver cardápio, a padrão (Higienópolis).
const filialCardapioPadrao = '1743445823763';
String codFilialCardapio = '';

/// Documento Filial/{codFilial} do Firestore (urlApiBratter, categorias
/// ocultas etc.), lido ao abrir o site.
Map<String, dynamic> dadosFilialFirestore = {};
String numeroMesa = '';
String numeroComanda = '';
bool isQuartoENome = true;

class GlobalKeys {
  static const String idioma = '';
  static const String codEmpresa = '1';
  static const String descricaoEmpresa = 'Dona Deola';

  static const ambienteNfe = 'P';
  static const userApiBratter = 'ConexaoMovel';
  static const passwordApiBratter = '20250301';
  static String tokenBratter = '';
  static const String serieNfe = '20';
  static String numSequencialNfe = '';
  static String base64Nfe = '';
  static String errroResponse = '';
  static String errroResponseStatusCode = '';
  static int idInvoice = 0;
  static late String brCode;
  static late bool pagtoPIX;
  static dynamic nfe;
}

class CustomColor {
  static const Color PRIMARY = Color(0xff62b7e0);
  static const Color ACCENT = Color(0xff0061aa);
  static const textColor = Color(0xFF333333);
  static const Color GreyCustom = Color(0xFF5F6269);
}

class Urls {
  static const String urlApiAzureCardapioDiario =
      'https://webapi-uteis-ezf9f5gaaghcgzah.brazilsouth-01.azurewebsites.net/api/';

  static const String urlApiAzure =
      'https://webapi-sisfiscal-cqf7dxb8dkfye7ap.brazilsouth-01.azurewebsites.net/api/';

  static const String urlApiPagtoAzure =
      'https://webapi-sispagamento-hnabgfa6h9h7hrg3.brazilsouth-01.azurewebsites.net/api/';
  static String urlApiBratter = '';
  // static const String urlApiBratter =
  //     'http://dd-higienopolis.ddns.com.br:1974/DeolaApi/api/';
  // 'http://dd-hsjos.ddns.com.br:1974/DeolaApi/api/';
  // 'http://dd-lapa.ddns.com.br:1974/DeolaApi/api/';
  static String urlApimEmissaoNFe = GlobalKeys.ambienteNfe == "P"
      ? 'http://helpmachine.ddns.com.br:9006/nfe'
      : 'http://192.168.0.100:9005/nfe';
}

void setUrlApiBratterPorFilial(String filialId) {
  // URL da Bratter cadastrada no Firestore: vale para qualquer filial nova,
  // sem mexer no código. Usa a externa (Filial/{id}.urlApiBratterExterna);
  // a urlApiBratter (dos tablets) só se não for de rede interna.
  String campo(String nome) =>
      (dadosFilialFirestore[nome] ?? '').toString().trim();
  final interna =
      RegExp(r'//(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)');
  var cadastrada = campo('urlApiBratterExterna');
  if (cadastrada.isEmpty && !interna.hasMatch(campo('urlApiBratter'))) {
    cadastrada = campo('urlApiBratter');
  }
  if (cadastrada.isNotEmpty) {
    Urls.urlApiBratter = cadastrada.endsWith('/') ? cadastrada : '$cadastrada/';
    return;
  }
  if (filialId == '1743445823763') {
    Urls.urlApiBratter =
        'http://dd-higienopolis.ddns.com.br:1974/DeolaApi/api/';
  } else if (filialId == '8urs76lF1QwjcNpi3CwD') {
    Urls.urlApiBratter = 'http://dd-lapa.ddns.com.br:1974/DeolaApi/api/';
  } else if (filialId == '1743443888148') {
    // Saúde (no Firestore a urlApiBratter é a da rede interna, dos tablets)
    Urls.urlApiBratter = 'http://dd-saude.ddns.com.br:1974/DeolaApi/api/';
  } else if (filialId == '3') {
    Urls.urlApiBratter = 'http://dd-hsjos.ddns.com.br:1974/DeolaApi/api/';
  } else {
    Urls.urlApiBratter =
        'http://dd-higienopolis.ddns.com.br:1974/DeolaApi/api/';
  }
}
