import 'package:webapp_pedido_mesa/services/nfce/model/icms_model.dart'
    as icms_model;

class NFeModel {
  final String cnpj;
  final String modelo;
  String numeroDFe;
  final Emitente emitente;
  final String natOp;
  final String indPag;
  final int serie;
  final String tipoNfe;
  final String tipoEmis;
  final String idDest;
  final Destinatario destinatario;
  final List<Produto> produtos;
  final Total total;
  final List<Pagamento> pagamentos;

  NFeModel({
    required this.cnpj,
    required this.modelo,
    required this.numeroDFe,
    required this.emitente,
    required this.natOp,
    required this.indPag,
    required this.serie,
    required this.tipoNfe,
    required this.tipoEmis,
    required this.idDest,
    required this.destinatario,
    required this.produtos,
    required this.total,
    required this.pagamentos,
  });

  Map<String, dynamic> toJson() {
    return {
      'Emitente': emitente.toJson(),
      'NatOp': natOp,
      'IndPag': indPag,
      'Serie': serie,
      'TipoNfe': tipoNfe,
      'TipoEmis': tipoEmis,
      'idDest': idDest,
      'Destinatario': destinatario.toJson(),
      'Produto': produtos.map((produto) => produto.toJson()).toList(),
      'Total': total.toJson(),
      'Pagamento': pagamentos.map((pagamento) => pagamento.toJson()).toList(),
    };
  }
}

class Emitente {
  final String razaoSocial;
  final String nomeFantasia;
  final String cnpj;
  final String ie;
  final String cnae;
  final String telefone;
  final String endLogradouro;
  final String endNumero;
  final String endComplemento;
  final String endBairro;
  final String endMunicipio;
  final int endCodMunicipio;
  final String endUf;
  final String endCep;
  final int crt;

  Emitente({
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.cnpj,
    required this.ie,
    required this.cnae,
    required this.telefone,
    required this.endLogradouro,
    required this.endNumero,
    required this.endComplemento,
    required this.endBairro,
    required this.endMunicipio,
    required this.endCodMunicipio,
    required this.endUf,
    required this.endCep,
    required this.crt,
  });

  Map<String, dynamic> toJson() {
    return {
      'Razao_Social': razaoSocial,
      'Nome_Fantasia': nomeFantasia,
      'CNPJ': cnpj,
      'IE': ie,
      'CNAE': cnae,
      'Telefone': telefone,
      'End_Logradouro': endLogradouro,
      'End_Numero': endNumero,
      'End_Complemento': endComplemento,
      'End_Bairro': endBairro,
      'End_Municipio': endMunicipio,
      'End_Cod_Municipio': endCodMunicipio,
      'End_UF': endUf,
      'End_CEP': endCep,
      'CRT': crt,
    };
  }
}

class Destinatario {
  final String cnpjCpf;
  final String ie;
  final String isuf;
  final String nome;
  final int indIEDest;
  final Endereco endereco;

  Destinatario({
    required this.cnpjCpf,
    required this.ie,
    required this.isuf,
    required this.nome,
    required this.indIEDest,
    required this.endereco,
  });

  Map<String, dynamic> toJson() {
    return {
      'CNPJCPF': cnpjCpf,
      'IE': ie,
      'ISUF': isuf,
      'Nome': nome,
      'indIEDest': indIEDest,
      'Endereco': endereco.toJson(),
    };
  }
}

class Endereco {
  final String fone;
  final int cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String pais;
  final String codMunicipio;

  Endereco({
    required this.fone,
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.pais,
    required this.codMunicipio,
  });

  Map<String, dynamic> toJson() {
    return {
      'Fone': fone,
      'CEP': cep,
      'Logradouro': logradouro,
      'Numero': numero,
      'Complemento': complemento,
      'Bairro': bairro,
      'Cidade': cidade,
      'Estado': estado,
      'Pais': pais,
      'CodMunicipio': codMunicipio,
    };
  }
}

class Produto {
  final int item;
  final String codigo;
  final String ean;
  final String descricao;
  final String ncm;
  final String extIPI;
  final String cfop;
  final String unidade;
  final double quantidade;
  final double precoVenda;
  final double valorUnitario;
  final double valorOutro;
  final double valorFrete;
  final double valorSeguro;
  final double valorDesconto;
  final String cest;
  final dynamic infAdProd;
  final String codBarra;
  final Imposto imposto;

  Produto({
    required this.item,
    required this.codigo,
    required this.ean,
    required this.descricao,
    required this.ncm,
    required this.extIPI,
    required this.cfop,
    required this.unidade,
    required this.quantidade,
    required this.precoVenda,
    required this.valorUnitario,
    required this.valorOutro,
    required this.valorFrete,
    required this.valorSeguro,
    required this.valorDesconto,
    required this.cest,
    this.infAdProd,
    required this.codBarra,
    required this.imposto,
  });

  Map<String, dynamic> toJson() {
    return {
      'Item': item,
      'Codigo': codigo,
      'EAN': ean,
      'Descricao': descricao,
      'NCM': ncm,
      'ExtIPI': extIPI,
      'CFOP': cfop,
      'Unidade': unidade,
      'Quantidade': quantidade,
      'PrecoVenda': precoVenda,
      'ValorUnitario': valorUnitario,
      'ValorOutro': valorOutro,
      'ValorFrete': valorFrete,
      'ValorSeguro': valorSeguro,
      'ValorDesconto': valorDesconto,
      'CEST': cest,
      'InfAdProd': infAdProd,
      'CodBarra': codBarra,
      'Imposto': imposto.toJson(),
    };
  }
}

class Imposto {
  final double vTotTrib;
  final ICMS icms;
  final PIS pis;
  final PISST pisst;
  final COFINS cofins;
  final COFINSST cofinsst;

  Imposto({
    required this.vTotTrib,
    required this.icms,
    required this.pis,
    required this.pisst,
    required this.cofins,
    required this.cofinsst,
  });

  Map<String, dynamic> toJson() {
    return {
      'vTotTrib': vTotTrib,
      'ICMS': icms.toJson(),
      'PIS': pis.toJson(),
      'PISST': pisst.toJson(),
      'COFINS': cofins.toJson(),
      'COFINSST': cofinsst.toJson(),
    };
  }
}

class ICMS {
  final String cst;
  final String orig;
  final double pICMS;
  final int csosn;

  ICMS({
    required this.cst,
    required this.orig,
    required this.pICMS,
    required this.csosn,
  });

  Map<String, dynamic> toJson() {
    return {'CST': cst, 'orig': orig, 'pICMS': pICMS, 'CSOSN': csosn};
  }
}

class PIS {
  final String cst;
  final double vBC;
  final double vPIS;
  final double qBCProd;
  final double vAliqProd;
  final double pPIS;

  PIS({
    required this.cst,
    required this.vBC,
    required this.vPIS,
    required this.qBCProd,
    required this.vAliqProd,
    required this.pPIS,
  });

  Map<String, dynamic> toJson() {
    return {
      'CST': cst,
      'vBC': vBC,
      'vPIS': vPIS,
      'QBCProd': qBCProd,
      'vAliqProd': vAliqProd,
      'pPIS': pPIS,
    };
  }
}

class PISST {
  final double vBC;
  final double pPIS;
  final double qBCProd;
  final double vAliqProd;
  final double vPIS;
  final String indSomaPISST;

  PISST({
    required this.vBC,
    required this.pPIS,
    required this.qBCProd,
    required this.vAliqProd,
    required this.vPIS,
    required this.indSomaPISST,
  });

  Map<String, dynamic> toJson() {
    return {
      'vBC': vBC,
      'pPIS': pPIS,
      'QBCProd': qBCProd,
      'vAliqProd': vAliqProd,
      'vPIS': vPIS,
      'IndSomaPISST': indSomaPISST,
    };
  }
}

class COFINS {
  final String cst;
  final double vBC;
  final double vCOFINS;
  final double qBCProd;
  final double vAliqProd;
  final double pCOFINS;

  COFINS({
    required this.cst,
    required this.vBC,
    required this.vCOFINS,
    required this.qBCProd,
    required this.vAliqProd,
    required this.pCOFINS,
  });

  Map<String, dynamic> toJson() {
    return {
      'CST': cst,
      'vBC': vBC,
      'vCOFINS': vCOFINS,
      'QBCProd': qBCProd,
      'vAliqProd': vAliqProd,
      'pCOFINS': pCOFINS,
    };
  }
}

class COFINSST {
  final double vBC;
  final double pCOFINS;
  final double qBCProd;
  final double vAliqProd;
  final double vCOFINS;
  final String indSomaCOFINSST;

  COFINSST({
    required this.vBC,
    required this.pCOFINS,
    required this.qBCProd,
    required this.vAliqProd,
    required this.vCOFINS,
    required this.indSomaCOFINSST,
  });

  Map<String, dynamic> toJson() {
    return {
      'vBC': vBC,
      'pCOFINS': pCOFINS,
      'QBCProd': qBCProd,
      'vAliqProd': vAliqProd,
      'vCOFINS': vCOFINS,
      'IndSomaCOFINSST': indSomaCOFINSST,
    };
  }
}

class Total {
  final icms_model.ICMS icms;
  final RetTrib retTrib;

  Total({required this.icms, required this.retTrib});

  Map<String, dynamic> toJson() {
    return {'ICMS': icms.toJson(), 'RetTrib': retTrib.toJson()};
  }
}

class RetTrib {
  final double vRetPIS;
  final double vRetCOFINS;
  final double vRetCSLL;
  final double vBCIRRF;
  final double vIRRF;
  final double vBCRetPrev;
  final double vRetPrev;

  RetTrib({
    required this.vRetPIS,
    required this.vRetCOFINS,
    required this.vRetCSLL,
    required this.vBCIRRF,
    required this.vIRRF,
    required this.vBCRetPrev,
    required this.vRetPrev,
  });

  Map<String, dynamic> toJson() {
    return {
      'vRetPIS': vRetPIS,
      'vRetCOFINS': vRetCOFINS,
      'vRetCSLL': vRetCSLL,
      'vBCIRRF': vBCIRRF,
      'vIRRF': vIRRF,
      'vBCRetPrev': vBCRetPrev,
      'vRetPrev': vRetPrev,
    };
  }
}

class Pagamento {
  final String identificacao;
  final String tipo;
  final String valor;
  final dynamic integrado;
  final dynamic cnpj;
  final dynamic bandeiraCartao;
  final dynamic codAutorizacao;

  Pagamento({
    required this.identificacao,
    required this.tipo,
    required this.valor,
    this.integrado,
    this.cnpj,
    this.bandeiraCartao,
    this.codAutorizacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'Identificacao': identificacao,
      'Tipo': tipo,
      'Valor': valor,
      'Integrado': integrado,
      'CNPJ': cnpj,
      'BandeiraCartao': bandeiraCartao,
      'CodAutorizacao': codAutorizacao,
    };
  }
}
