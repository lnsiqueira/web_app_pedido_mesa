import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/services/log/log.dart';
import 'package:webapp_pedido_mesa/services/nfce/emissao_nfce.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/log_model.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/nfe_model.dart';
import 'package:webapp_pedido_mesa/services/nfce/nfe_sequencial_service.dart';
import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/services/nfce/nfe_sequencial_service_UAT.dart';
import 'package:webapp_pedido_mesa/services/nfce/retorna_impostos.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/nfe_model.dart'
    as nfeModel;
import 'package:webapp_pedido_mesa/services/nfce/model/icms_model.dart'
    as icms_model;
import 'package:webapp_pedido_mesa/services/verifica_url_online.dart';

class NfceService {
  Future<bool> getInformacoesFiscaisDosProdutos(
    dynamic pedido,
    BuildContext context,
  ) async {
    final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
    final mesaComanda = Provider.of<MesaComandaModel>(context, listen: false);

    int itemIndex = 0;
    List<nfeModel.Produto> listaProdutos = [];
    double totalValorNF = 0;
    double totTrib = 0;
    double totPIS = 0;
    double totCOFINS = 0;
    int i = 0;
    var nfe;
    ResultadoImposto? resultado;

    final nfeService = NfeSequencialService();

    try {
      if (GlobalKeys.ambienteNfe == 'P') {
        //await uploadPedido();
      }

      final itensCarrinho = List.from(carrinho.itens);
      if (itensCarrinho.isEmpty) {
        return false;
      }

      for (var item in itensCarrinho) {
        i++;

        // final url = Uri.parse(
        //   '${Urls.urlApiBratter}mercadoriafiscal?codigoproduto=${item.produto.plu}&imagens=false',
        // );

        var urlBratter = Urls.urlApiBratter;
        final encodedUrl = Uri.encodeComponent(urlBratter);

        final url =
            '${Urls.urlApiAzure}Proxy/mercadoriafiscal?codigoproduto=${item.produto.plu}&imagens=false&urlBratter=${encodedUrl}&tokenBratter=${GlobalKeys.tokenBratter}';

        final response = await http.get(Uri.parse(url));

        // final response = await http.get(
        //   url,
        //   headers: {"Authorization": "Bearer $GlobalKeys.tokenBratter"},
        // );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final produtoFiscal = data;
          print(produtoFiscal);

          // double precoItem = double.parse(
          //   ((item.produto.preco?.toDouble() ??
          //               produtoFiscal['preco']?.toDouble() ??
          //               0.0) +
          //           (item.produto.obsSelecionadas?.fold(
          //                 0.0,
          //                 (sum, obs) =>
          //                     sum +
          //                     (obs.modificador == "C" ? obs.preco ?? 0.0 : 0.0),
          //               ) ??
          //               0.0))
          //       .toStringAsFixed(2),
          // );

          double precoItem =
              item.produto.preco?.toDouble() ??
              produtoFiscal['preco']?.toDouble() ??
              0.0;

          if (item.quantidade == 0) {
            item.quantidade = 1;
          }

          //ResultadoImposto? resultado;
          //ResultadoImposto? resultado;

          resultado = ResultadoImposto(
            baseCompra: 0,
            totalTributos: 0,
            valorIcms: 0,
            valorPis: 0,
            valorCofins: 0,
            basePisCofins: 0,
          ); // com construtor padrão

          if (item.produto.plu == '1') {
            resultado = calcularImpostos(
              quantidade: item.produto.peso,
              precoProduto: item.produto.preco * item.produto.peso,
              aliquotaIcms: produtoFiscal['aliquotaicms']?.toDouble() ?? 0.0,
              aliquotaPis: produtoFiscal['aliquotapis']?.toDouble() ?? 0.0,
              aliquotaCofins:
                  produtoFiscal['aliquotacofins']?.toDouble() ?? 0.0,
            );
          } else {
            const cstSemCalculo = ['04', '05', '06', '07', '09'];

            final cstIcms = produtoFiscal['csticms']?.toString() ?? '';
            final cstCofins = produtoFiscal['cstcofins']?.toString() ?? '';

            if (cstSemCalculo.contains(cstIcms) ||
                cstSemCalculo.contains(cstCofins)) {
              resultado = ResultadoImposto(
                baseCompra: 0,
                totalTributos: 0,
                valorIcms: 0,
                valorPis: 0,
                valorCofins: 0,
                basePisCofins: 0,
              );
            } else {
              resultado = calcularImpostos(
                quantidade: item.quantidade.toDouble(),
                precoProduto: precoItem,
                aliquotaIcms: produtoFiscal['aliquotaicms']?.toDouble() ?? 0.0,
                aliquotaPis: produtoFiscal['aliquotapis']?.toDouble() ?? 0.0,
                aliquotaCofins:
                    produtoFiscal['aliquotacofins']?.toDouble() ?? 0.0,
              );
            }
          }

          listaProdutos.add(
            Produto(
              item: itemIndex++,
              codigo: produtoFiscal['plu'].toString(),
              ean: '',
              descricao: produtoFiscal['descricao'] ?? item.produto.descricao,
              ncm: produtoFiscal['ncm'] ?? '',
              extIPI: "",
              cfop:
                  produtoFiscal['csticms']?.toString().padLeft(2, '0').trim() ==
                          '60'
                      ? "5405"
                      : "5102",
              unidade: produtoFiscal['unidade'] ?? 'UN',
              quantidade: item.quantidade.toDouble(),
              precoVenda: double.parse(
                (precoItem * item.quantidade).toStringAsFixed(2),
              ),
              valorUnitario: precoItem,
              valorOutro: 0,
              valorFrete: 0,
              valorSeguro: 0,
              valorDesconto: 0,
              cest: (produtoFiscal['cest']?.toString() ?? '').padLeft(7, '0'),
              infAdProd: produtoFiscal['obs']?[0]['titulo'] ?? '',
              codBarra: '',
              imposto: nfeModel.Imposto(
                vTotTrib: resultado.totalTributos,
                icms: nfeModel.ICMS(
                  cst:
                      produtoFiscal['csticms']
                          ?.toString()
                          .padLeft(2, '0')
                          .trim() ??
                      '99',
                  orig: "Nacional",
                  pICMS: produtoFiscal['aliquotaicms']?.toDouble() ?? 0.0,
                  csosn: 0,
                ),
                pis: nfeModel.PIS(
                  cst:
                      produtoFiscal['cstpis']?.toString().padLeft(2, '0') ??
                      '99',
                  vBC: resultado.baseCompra,
                  vPIS: resultado.valorPis,
                  qBCProd: 0,
                  vAliqProd: produtoFiscal['aliquotapis']?.toDouble() ?? 0.0,
                  pPIS: produtoFiscal['aliquotapis']?.toDouble() ?? 0.0,
                ),
                pisst: nfeModel.PISST(
                  pPIS: 0,
                  vBC: 0,
                  vPIS: 0,
                  qBCProd: 0,
                  vAliqProd: 0,
                  indSomaPISST: '',
                ),
                cofins: nfeModel.COFINS(
                  cst:
                      produtoFiscal['cstcofins']?.toString().padLeft(2, '0') ??
                      '99',
                  vBC: resultado.baseCompra,
                  vCOFINS: resultado.valorCofins,
                  qBCProd: 0,
                  vAliqProd: produtoFiscal['aliquotacofins']?.toDouble() ?? 0.0,
                  pCOFINS: produtoFiscal['aliquotacofins']?.toDouble() ?? 0.0,
                ),
                cofinsst: nfeModel.COFINSST(
                  pCOFINS: 0,
                  vBC: 0,
                  vCOFINS: 0,
                  qBCProd: 0,
                  vAliqProd: 0,
                  indSomaCOFINSST: '',
                ),
              ),
            ),
          );

          totPIS += resultado.valorPis;
          totCOFINS += resultado.valorCofins;
        } else {
          print(
            'Erro ao buscar info fiscal do produto ${item.produto.descricao}: ${response.statusCode}',
          );
          return false;
        }
      }

      // Aqui somamos os precoVenda já arredondados dos produtos na lista
      totalValorNF = listaProdutos.fold(0.0, (sum, p) => sum + p.precoVenda);
      totalValorNF = double.parse(totalValorNF.toStringAsFixed(2));

      double arredondaCustom(double valor) {
        return double.parse(valor.toStringAsFixed(2));
      }

      totalValorNF = arredondaCustom(totalValorNF);

      final endereco = globalFilialData?.endereco ?? '';
      final List<String> partes = [];
      int index = 0;

      while (index < endereco.length) {
        // Verifica vírgula
        int virgulaIndex = endereco.indexOf(',', index);
        if (virgulaIndex != -1 &&
            index < virgulaIndex &&
            virgulaIndex <= endereco.length) {
          partes.add(endereco.substring(index, virgulaIndex).trim());
          index = virgulaIndex + 1;
        } else {
          break;
        }

        // Verifica hífen
        int hifenIndex = endereco.indexOf('-', index);
        if (hifenIndex != -1 &&
            index < hifenIndex &&
            hifenIndex <= endereco.length) {
          partes.add(endereco.substring(index, hifenIndex).trim());
          index = hifenIndex + 1;
        } else {
          break;
        }
      }

      // Pega o que sobrou
      if (index < endereco.length) {
        partes.add(endereco.substring(index).trim());
      }

      // Limpa CNPJ
      final cnpjLimpo = '';
      //***
      // final cnpjLimpo = pedidoController.cartaoCnpj.value.replaceAll(
      //   RegExp(r'\D'),
      //   '',
      // );

      nfe = nfeModel.NFeModel(
        cnpj: globalFilialData!.cnpj,
        modelo: '65',
        numeroDFe: GlobalKeys.numSequencialNfe,
        emitente: nfeModel.Emitente(
          razaoSocial: globalFilialData!.razaoSocial,
          nomeFantasia: globalFilialData!.razaoSocial,
          cnpj: globalFilialData!.cnpj,
          ie: globalFilialData!.ie,
          cnae: '5611201',
          telefone: globalFilialData!.telefone,
          endLogradouro: partes[0],
          endNumero: partes[1],
          endComplemento: '',
          endBairro: partes[2],
          endMunicipio: partes[3],
          endCodMunicipio: 3500709,
          endUf: partes[4],
          endCep:
              '${partes.length > 5 ? partes[5] : ''}-${partes.length > 6 ? partes[6] : ''}',
          crt: 2, //TODO: VALIDAR globalFilialData!.crt,
        ),
        natOp: 'VENDA DE PRODUTOS',
        indPag: 'Vista',
        serie: int.parse(GlobalKeys.serieNfe),
        tipoNfe: 'Saida',
        tipoEmis: 'Normal',
        idDest: 'Interna',
        destinatario: nfeModel.Destinatario(
          cnpjCpf: '',
          ie: '',
          isuf: '',
          nome: '',
          indIEDest: 9,
          endereco: nfeModel.Endereco(
            fone: '',
            cep: 0,
            logradouro: '',
            numero: '',
            complemento: '',
            bairro: '',
            cidade: '',
            estado: '',
            pais: '',
            codMunicipio: '',
          ),
        ),
        produtos: listaProdutos,
        total: nfeModel.Total(
          icms: icms_model.ICMS(
            vProd: totalValorNF,
            vFrete: 0,
            vSeg: 0,
            vDesc: 0,
            vIPI: 0,
            vPIS: double.parse(totPIS.toStringAsFixed(2)),
            vCOFINS: double.parse(totCOFINS.toStringAsFixed(2)),
            vOutro: 0,
            vNF: totalValorNF,
          ),
          retTrib: nfeModel.RetTrib(
            vRetPIS: 0,
            vRetCOFINS: 0,
            vRetCSLL: 0,
            vBCIRRF: 0,
            vIRRF: 0,
            vBCRetPrev: 0,
            vRetPrev: 0,
          ),
        ),
        pagamentos: [
          nfeModel.Pagamento(
            identificacao: "avista",
            tipo: '05', //PIX
            valor: totalValorNF.toStringAsFixed(2),
            bandeiraCartao: '',
            cnpj: '10440482000154',
            integrado: 'PagIntegrado',
            codAutorizacao: (Random().nextInt(9000) + 1000).toString(),
          ),
        ],
      );

      final logFirebase = Log(
        id: 0,
        idFilial: GlobalKeys.codFilial,
        idEmpresa: '1',
        descricaoFilial: GlobalKeys.descricaoFilial,
        descricaoEmpresa: "Dona Deola",
        dataHora: DateTime.now(),
        descricaoAtividade: "CONTINGENCIA",
        tipoEvento: 'POST',
        status: 'E',
        valorChave: 'FIREBASE não está acessível',
        descricaoChave:
            'id:${10000 + Random().nextInt(90000)} vNF:${totalValorNF.toStringAsFixed(2)} nNF:${GlobalKeys.numSequencialNfe}  Serie:${GlobalKeys.serieNfe} Token:-',
        descricaoEvento: 'GERACAO_NFCE-numSequencialNfe',
        ambiente: GlobalKeys.ambienteNfe,
        endpoint: Urls.urlApimEmissaoNFe,
        valorJson: nfe.toJson(),
      );
      if (GlobalKeys.ambienteNfe == "P") {
        GlobalKeys.numSequencialNfe =
            (await nfeService.obterAtualizaProximoNumeroNfe(
              logFirebase,
              filialId: GlobalKeys.codFilial,
              serie: GlobalKeys.serieNfe.toString(),
            )).toString();
      } else {
        final nfeServiceUAT = NfeSequencialServiceUAT();
        GlobalKeys.numSequencialNfe =
            (await nfeServiceUAT.obterAtualizaProximoNumeroNfe(
              logFirebase,
              filialId: GlobalKeys.codFilial,
              serie: GlobalKeys.serieNfe.toString(),
            )).toString();
      }

      nfe.numeroDFe = GlobalKeys.numSequencialNfe.toString();

      //pedidoController.idPedido.value;

      bool retornoAPI;

      final log = Log(
        id: 0,
        idFilial: GlobalKeys.codFilial,
        idEmpresa: '1',
        descricaoFilial: GlobalKeys.descricaoFilial,
        descricaoEmpresa: "Dona Deola",
        dataHora: DateTime.now(),
        descricaoAtividade: "CONTINGENCIA",
        tipoEvento: 'POST',
        status: 'E',
        valorChave: 'URL não está acessível: ${Urls.urlApimEmissaoNFe}',
        descricaoChave:
            'id:${10000 + Random().nextInt(90000)} vNF:${totalValorNF.toStringAsFixed(2)} nNF:${GlobalKeys.numSequencialNfe} Serie:${GlobalKeys.serieNfe} Token:-',
        descricaoEvento: 'GERACAO_NFCE',
        ambiente: GlobalKeys.ambienteNfe,
        endpoint: Urls.urlApimEmissaoNFe,
        valorJson: nfe.toJson(),
      );
      retornoAPI = await verificarUrlOnline(
        log,
        Urls.urlApimEmissaoNFe + '/Status',
      );
      if (!retornoAPI) {
        print('URL não está acessível: $Urls.urlApimEmissaoNFe');
        //await uploadPedidoContigencia();

        LogApiService.gravarLog(log);
        return false;
      }

      final logA = Log(
        id: 0,
        idFilial: GlobalKeys.codFilial,
        idEmpresa: '1',
        descricaoFilial: GlobalKeys.descricaoFilial,
        descricaoEmpresa: "Dona Deola",
        dataHora: DateTime.now(),
        descricaoAtividade: "ERRO API-AZURE",
        tipoEvento: 'POST',
        status: 'E',
        valorChave: 'URL não está acessível: $Urls.urlAPIAzure',
        descricaoChave:
            'id:${10000 + Random().nextInt(90000)} vNF:${totalValorNF.toStringAsFixed(2)} nNF:${GlobalKeys.numSequencialNfe} Serie:${GlobalKeys.serieNfe} Token:-',
        descricaoEvento: 'API AZURE ',
        ambiente: GlobalKeys.ambienteNfe,
        endpoint: Urls.urlApiAzure,
        valorJson: nfe.toJson(),
      );

      retornoAPI = await verificarUrlOnline(logA, Urls.urlApiAzure + 'Ping');
      if (!retornoAPI) {
        //TODO: Acionar contingencia
        print('URL não está acessível: ${Urls.urlApiAzure}');
        //await uploadPedidoContigencia();

        LogApiService.gravarLog(logA);
        return false;
      }

      try {
        GlobalKeys.base64Nfe = await EmissaoNfce().enviarNFe(
          nfe,
          GlobalKeys.descricaoFilial,
          GlobalKeys.codFilial,
          GlobalKeys.ambienteNfe,
          GlobalKeys.serieNfe.toString(),
          pedido,
          Urls.urlApimEmissaoNFe,
        );
      } catch (e) {
        // Erro específico do pacote
        print('Código do erro: ${e.toString()}');
        print('Mensagem: ${e.toString()}');
        print('Detalhes: ${e.toString()}');

        // Gravar log local
        //await uploadPedidoContigencia();

        final logN = Log(
          id: 0,
          idFilial: GlobalKeys.codFilial,
          idEmpresa: '1',
          descricaoFilial: GlobalKeys.descricaoFilial,
          descricaoEmpresa: "Dona Deola",
          dataHora: DateTime.now(),
          descricaoAtividade: "CONTINGENCIA",
          tipoEvento: 'POST',
          status: 'E',
          valorChave: '$e.toString()',
          descricaoChave:
              'id:${10000 + Random().nextInt(90000)} vNF:${totalValorNF.toStringAsFixed(2)} nNF:${GlobalKeys.numSequencialNfe} Serie:${GlobalKeys.serieNfe} Token:- | Erro: ${e.toString()}',
          descricaoEvento: ' ${e.toString()} | ${e.toString()}',
          ambiente: GlobalKeys.ambienteNfe,
          endpoint: '',
          valorJson: nfe.toJson(),
        );
        //await saveLocalService.saveLogLocally(logN);
        LogApiService.gravarLog(logN);
      }

      if (GlobalKeys.base64Nfe.isEmpty) {
        print('Erro ao obter base64 da NFe');

        final logN = Log(
          id: 0,
          idFilial: GlobalKeys.codFilial,
          idEmpresa: '1',
          descricaoFilial: GlobalKeys.descricaoFilial,
          descricaoEmpresa: "Dona Deola",
          dataHora: DateTime.now(),
          descricaoAtividade: "GERACAO_NFCE",
          tipoEvento: 'POST',
          status: 'E',
          valorChave: '$e.toString()',
          descricaoChave:
              'id:${10000 + Random().nextInt(90000)} vNF:${totalValorNF.toStringAsFixed(2)} nNF:${GlobalKeys.numSequencialNfe} Serie:${GlobalKeys.serieNfe} Token:- | Erro: ${e.toString()}',
          descricaoEvento:
              '  ${GlobalKeys.errroResponse} - ${GlobalKeys.errroResponseStatusCode}',
          ambiente: GlobalKeys.ambienteNfe,
          endpoint: '',
          valorJson: nfe.toJson(),
        );
        //await saveLocalService.saveLogLocally(logN);
        LogApiService.gravarLog(logN);

        return false;
      }

      final jsonStr = JsonEncoder.withIndent('  ').convert(nfe.toJson());

      for (var i = 0; i < jsonStr.length; i += 500) {
        print(
          jsonStr.substring(
            i,
            i + 500 > jsonStr.length ? jsonStr.length : i + 500,
          ),
        );

        // await zerarCarrinho();
      }

      return true;
    } catch (e) {
      print('Erro ao obter informações fiscais dos produtos: $e');
      // Gravar log local
      //await uploadPedidoContigencia();

      final logE = Log(
        id: 0,
        idFilial: GlobalKeys.codFilial,
        idEmpresa: '1',
        descricaoFilial: GlobalKeys.descricaoFilial,
        descricaoEmpresa: "Dona Deola",
        dataHora: DateTime.now(),
        descricaoAtividade: "ERRO catch",
        tipoEvento: 'POST',
        status: 'E',
        valorChave: '$e.toString()',
        descricaoChave:
            'id:${10000 + Random().nextInt(90000)} vNF:${totalValorNF.toStringAsFixed(2)} nNF:${GlobalKeys.numSequencialNfe} Serie:${GlobalKeys.serieNfe} Token:- | Erro: ${e.toString()}',
        descricaoEvento: 'Exeption metodo getInformacoesFiscaisDosProdutos',
        ambiente: GlobalKeys.ambienteNfe,
        endpoint: '',
        valorJson: nfe.toJson(),
      );
      //await saveLocalService.saveLogLocally(logE);
      LogApiService.gravarLog(logE);

      return false;
    }
  }
}
