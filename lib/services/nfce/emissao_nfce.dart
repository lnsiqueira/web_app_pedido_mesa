import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/services/log/log.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/log_model.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/nfe_model.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/nfe_retorno_model.dart';

// var urlAPIAzure =
//     'https://webapi-sisfiscal-cqf7dxb8dkfye7ap.brazilsouth-01.azurewebsites.net/';

String limparBase64(String base64) {
  return base64
      .replaceAll(RegExp(r'[\r\n\\]'), '') // Remove \r, \n e \
      .replaceAll(' ', ''); // Remove espaços se existirem
}

class EmissaoNfce {
  Future<String> enviarNFe(
    NFeModel nfeModel,
    String filial,
    String codFilial,
    String ambiente,
    String terminalCaixa,
    dynamic pedido,
    String urlApimEmissaoNFe,
  ) async {
    var errroResponse = '';
    var errroResponseStatusCode = '';

    try {
      final jsonStr = JsonEncoder.withIndent('  ').convert(nfeModel.toJson());

      // Configuração dos headers usando os dados do modelo
      var headers = {
        'accept': 'application/json',
        'Cnpj': nfeModel.cnpj.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        ), // Remove formatação
        'Modelo': nfeModel.modelo,
        'NumeroDFe': nfeModel.numeroDFe,
        'Content-Type': 'application/json',
      };

      // Corpo da requisição usando o método toJson() do modelo
      var body = nfeModel.toJson();

      // Fazendo a requisição POST
      var response = await http
          .post(
            Uri.parse(urlApimEmissaoNFe),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 5));

      // Tratamento da resposta
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Resposta da API: ${response.body}');

        try {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          final nfeRetorno = NFeRetorno.fromJson(jsonResponse);

          // Exemplo de uso dos métodos adicionais
          if (!nfeRetorno.pdfIsEmpty) {
            print('\nPrimeiros 50 caracteres do PDF (base64):');
            print(nfeRetorno.base64.substring(0, 50) + '...');
          }

          final dadosParaAzure = {
            "id": 0,
            "descricaoFilial": filial,
            "idFilial": codFilial,
            "descricaoEmpresa": "Dona Deola",
            "idEmpresa": "1",
            "dataEmissaoNfe": nfeRetorno.data.toIso8601String(),
            "cnpjEmpresa": nfeModel.cnpj,
            "modeloNfe": nfeModel.modelo,
            "numeroNfe": nfeModel.numeroDFe,
            "serieNfe": terminalCaixa,
            "ipEmissor": "",
            "dispositivoEmissor": "",
            "ambiente": ambiente,
            "conteudoBase64": nfeRetorno.base64,
            "xmlNfe": nfeRetorno.xmlNfe,
            "nomeArquivo": nfeRetorno.nome,
            "valorTotal": nfeModel.pagamentos.first.valor,
            "linkNfe": "https://api.suaempresa.com/nfe/${nfeRetorno.nome}",
            "dataRegistro": DateTime.now().toIso8601String(),
            "tipPagamento": nfeModel.pagamentos.first.identificacao,
          };
          var base64Limpa = limparBase64(nfeRetorno.base64);
          print(base64Limpa);

          // 4. Chamar a API Azure
          await chamarAPIAzure(Urls.urlApiAzure, dadosParaAzure);

          return base64Limpa;
        } catch (e) {
          print('\nErro ao processar a resposta da API:');
          print('Tipo: ${e.runtimeType}');
          print('Mensagem: ${e.toString()}');

          final log = Log(
            id: 0,
            idFilial: codFilial,
            idEmpresa: '1',
            descricaoFilial: filial,
            descricaoEmpresa: "Dona Deola",
            dataHora: DateTime.now(),
            descricaoAtividade: "Erro ao processar a resposta da API",
            tipoEvento: 'POST',
            status: 'E',
            valorChave: response.statusCode.toString(),
            descricaoChave:
                'Erro na requisição: ${response.statusCode} - ${response.body}',
            descricaoEvento: 'GERACAO_NFCE',
            ambiente: ambiente,
            endpoint: urlApimEmissaoNFe,
            valorJson: pedido, // TODO: 👈 conversão obrigatória aqui
          );

          LogApiService.gravarLog(log);
          GlobalKeys.errroResponse = e.toString();
          GlobalKeys.errroResponseStatusCode = response.statusCode.toString();
          return '';
        }
      } else {
        errroResponse = response.body;
        errroResponseStatusCode = response.statusCode.toString();

        // throw PackageException(
        //   isSuccess: false,
        //   code: 'FALHA_EMISSAO_NFE',
        //   message: 'Não foi possível completar a operação',
        //   details: {
        //     'originalError': response.statusCode.toString(),
        //     'stackTrace': response.body,
        //   },
        // );
        GlobalKeys.errroResponse = response.body;
        GlobalKeys.errroResponseStatusCode = response.statusCode.toString();
        return '';
      }
    } catch (e) {
      print('Erro ao enviar NFe: $e');
      final log = Log(
        id: 0,
        idFilial: codFilial,
        idEmpresa: '1',
        descricaoFilial: filial,
        descricaoEmpresa: "Dona Deola",
        dataHora: DateTime.now(),
        descricaoAtividade: "Erro ao processar a resposta da API",
        tipoEvento: 'POST',
        status: 'E',
        valorChave: e.toString(),
        descricaoChave:
            'Erro na requisição: $errroResponseStatusCode - $errroResponse}',
        descricaoEvento: 'GERACAO_NFCE',
        ambiente: ambiente,
        endpoint: urlApimEmissaoNFe,
        valorJson: pedido, // TODO: 👈 conversão obrigatória aqui
      );

      //LogApiService.gravarLog(log);

      // throw PackageException(
      //   code: 'FALHA_INTERNA',
      //   message: 'Não foi possível completar a operação',
      //   details: {
      //     'originalError': errroResponseStatusCode,
      //     'stackTrace': errroResponse,
      //   },
      // );
      return '';
    }
  }

  // Função para chamar a API Azure
  Future<void> chamarAPIAzure(
    String urlAPIAzure,
    Map<String, dynamic> dados,
  ) async {
    try {
      print('Enviando dados para Azure...');

      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
        'POST',
        Uri.parse('$urlAPIAzure/nfce/inserir'),
      );

      request.headers.addAll(headers);
      request.body = json.encode(dados);

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('NFe registrada com sucesso no Azure');
      } else {
        print('Erro ao registrar no Azure: ${response.statusCode}');
        print('Resposta: ${await response.stream.bytesToString()}');

        final log = Log(
          id: 0,
          idFilial: dados['codFilial'],
          idEmpresa: '1',
          descricaoFilial: dados['filial'],
          descricaoEmpresa: "Dona Deola",
          dataHora: DateTime.now(),
          descricaoAtividade: "Erro ao processar a resposta da API",
          tipoEvento: 'POST',
          status: 'E',
          valorChave: response.statusCode.toString(),
          descricaoChave:
              'Erro na requisição: ${response.statusCode} - ${response.stream.bytesToString()}}',
          descricaoEvento: 'GERACAO_NFCE - AZURE',
          ambiente: dados['ambiente'],
          endpoint: '$urlAPIAzure/nfce/inserir',
        );
        LogApiService.gravarLog(log);
      }
    } catch (e) {
      print('Erro na comunicação com Azure: ${e.toString()}');
      final log = Log(
        id: 0,
        idFilial: dados['codFilial'],
        idEmpresa: '1',
        descricaoFilial: dados['filial'],
        descricaoEmpresa: "Dona Deola",
        dataHora: DateTime.now(),
        descricaoAtividade: "Erro ao processar a resposta da API",
        tipoEvento: 'POST',
        status: 'E',
        valorChave: e.toString(),
        descricaoChave: 'Erro na requisição: ${e.toString()}  ',
        descricaoEvento: 'GERACAO_NFCE - AZURE',
        ambiente: dados['ambiente'],
        endpoint: '$urlAPIAzure/api/nfce/inserir',
      );
      LogApiService.gravarLog(log);
    }
  }

  Future<void> enviarNFe2() async {
    try {
      // Configuração dos headers
      var headers = {
        'accept': 'application/json',
        'Cnpj': '19.834.505/0015-85', // Formato corrigido (sem pontos e traço)
        'Modelo': '65',
        'NumeroDFe': '1',
        'Content-Type': 'application/json',
      };

      // Corpo da requisição
      var body = {
        "Emitente": {
          "Razao_Social": "SALGADO E ANGELICO RESTAURANTE E LANCHONETE LTDA",
          "Nome_Fantasia": "SALGADO E ANGELICO RESTAURANTE E LANCHONETE LTDA",
          "CNPJ": "19.834.505/0015-85", // Formato corrigido
          "IE": "125877324118",
          "CNAE": "5611201",
          "Telefone": "30225640",
          "End_Logradouro": "RUA COMENDADOR ELIAS JAFET",
          "End_Numero": "1377",
          "End_Complemento": "",
          "End_Bairro": "MORUMBI",
          "End_Municipio": "SAO PAULO",
          "End_Cod_Municipio": 3500709,
          "End_UF": "SP",
          "End_CEP": "05653000",
          "CRT": 2,
        },
        "NatOp": "VENDA PRODUCAO DO ESTAB.",
        "IndPag": "Vista",
        "Serie": 7,
        "TipoNfe": "Saida",
        "TipoEmis": "Normal",
        "idDest": "Interna",
        "Destinatario": {
          "CNPJCPF": "",
          "IE": "",
          "ISUF": "",
          "Nome": "bruno monteiro de sousa soares faria",
          "indIEDest": 9,
          "Endereco": {
            "Fone": "",
            "CEP": 38444017,
            "Logradouro": "praça avelino alves coutinho",
            "Numero": "60",
            "Complemento": "casa",
            "Bairro": "miranda",
            "Cidade": "araguari",
            "Estado": "MG",
            "Pais": "Brasil",
            "CodMunicipio": "3103504",
          },
        },
        "Produto": [
          {
            "Item": 1,
            "Codigo": "4593",
            "EAN": "",
            "Descricao": "KIT DE NATAL",
            "NCM": "21069090",
            "ExtIPI": "99",
            "CFOP": "5102",
            "Unidade": "UN",
            "Quantidade": 1,
            "PrecoVenda": 86.9,
            "ValorUnitario": 86.9,
            "ValorOutro": 0,
            "ValorFrete": 0,
            "ValorSeguro": 0,
            "ValorDesconto": 0,
            "CEST": "2002000",
            "InfAdProd": null,
            "CodBarra": "7898449393615",
            "Imposto": {
              "vTotTrib": 11.51,
              "ICMS": {
                "CST": "00",
                "orig": "Nacional",
                "pICMS": "4.00",
                "CSOSN": 0,
              },
              "PIS": {
                "CST": "1",
                "vBC": 0,
                "vPIS": 0,
                "QBCProd": 0,
                "vAliqProd": 1.65,
              },
              "PISST": {
                "vBC": 0,
                "pPIS": 0,
                "QBCProd": 0,
                "vAliqProd": 0,
                "vPIS": 0,
                "IndSomaPISST": "Nenhum",
              },
              "COFINS": {
                "CST": "1",
                "vBC": 0,
                "vCOFINS": 0,
                "QBCProd": 0,
                "vAliqProd": 7.6,
              },
              "COFINSST": {
                "vBC": 0,
                "pCOFINS": 0,
                "QBCProd": 0,
                "vAliqProd": 0,
                "vCOFINS": 0,
                "IndSomaCOFINSST": "Nenhum",
              },
            },
          },
        ],
        "Total": {
          "ICMS": {
            "vProd": 86.9,
            "vFrete": 0,
            "vSeg": 0,
            "vDesc": 0,
            "vIPI": 0,
            "vPIS": 0,
            "vCOFINS": 0,
            "vOutro": 0,
            "vNF": 86.9,
          },
          "RetTrib": {
            "vRetPIS": 0,
            "vRetCOFINS": 0,
            "vRetCSLL": 0,
            "vBCIRRF": 0,
            "vIRRF": 0,
            "vBCRetPrev": 0,
            "vRetPrev": 0,
          },
        },
        "Pagamento": [
          {
            "Identificacao": "Vista",
            "Tipo": "01",
            "Valor": "86.90",
            "Integrado": null,
            "CNPJ": null,
            "BandeiraCartao": null,
            "CodAutorizacao": null,
          },
        ],
      };

      // Fazendo a requisição POST
      var response = await http.post(
        Uri.parse('http://189.78.106.176:9005/nfe'),
        headers: headers,
        body: json.encode(body),
      );

      // Tratamento da resposta
      if (response.statusCode == 200) {
        print('Resposta da API: ${response.body}');
        // Aqui você pode tratar o retorno positivo
      } else {
        print('Erro na requisição: ${response.statusCode} - ${response.body}');
        // Aqui você pode tratar o erro
      }
    } catch (e) {
      print('Erro durante a requisição: $e');
    }
  }
}
