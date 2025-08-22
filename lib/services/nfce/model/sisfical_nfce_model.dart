class SisficalNfceModel {
  final int id;
  final String descricaoFilial;
  final String idFilial;
  final String descricaoEmpresa;
  final String idEmpresa;
  final DateTime dataEmissaoNfe;
  final String cnpjEmpresa;
  final String modeloNfe;
  final String numeroNfe;
  final String serieNfe;
  final String ipEmissor;
  final String dispositivoEmissor;
  final String ambiente;
  final String conteudoBase64;
  final String xmlNfe;
  final String nomeArquivo;
  final double valorTotal;
  final String linkNfe;
  final DateTime dataRegistro;
  final String tipPagamento;

  SisficalNfceModel({
    required this.id,
    required this.descricaoFilial,
    required this.idFilial,
    required this.descricaoEmpresa,
    required this.idEmpresa,
    required this.dataEmissaoNfe,
    required this.cnpjEmpresa,
    required this.modeloNfe,
    required this.numeroNfe,
    required this.serieNfe,
    required this.ipEmissor,
    required this.dispositivoEmissor,
    required this.ambiente,
    required this.conteudoBase64,
    required this.xmlNfe,
    required this.nomeArquivo,
    required this.valorTotal,
    required this.linkNfe,
    required this.dataRegistro,
    required this.tipPagamento,
  });

  // Converte de JSON para o modelo
  factory SisficalNfceModel.fromJson(Map<String, dynamic> json) {
    return SisficalNfceModel(
      id: json['id'] ?? 0,
      descricaoFilial: json['descricaoFilial'] ?? '',
      idFilial: json['idFilial'] ?? '',
      descricaoEmpresa: json['descricaoEmpresa'] ?? '',
      idEmpresa: json['idEmpresa'] ?? '',
      dataEmissaoNfe: json['dataEmissaoNfe'] != null
          ? DateTime.parse(json['dataEmissaoNfe'])
          : DateTime.now(),
      cnpjEmpresa: json['cnpjEmpresa'] ?? '',
      modeloNfe: json['modeloNfe'] ?? '',
      numeroNfe: json['numeroNfe'] ?? '',
      serieNfe: json['serieNfe'] ?? '',
      ipEmissor: json['ipEmissor'] ?? '',
      dispositivoEmissor: json['dispositivoEmissor'] ?? '',
      ambiente: json['ambiente'] ?? '',
      conteudoBase64: json['conteudoBase64'] ?? '',
      xmlNfe: json['xmlNfe'] ?? '',
      nomeArquivo: json['nomeArquivo'] ?? '',
      valorTotal: (json['valorTotal'] ?? 0).toDouble(),
      linkNfe: json['linkNfe'] ?? '',
      dataRegistro: json['dataRegistro'] != null
          ? DateTime.parse(json['dataRegistro'])
          : DateTime.now(),
      tipPagamento: json['tipPagamento'] ?? '',
    );
  }

  // Converte o modelo para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricaoFilial': descricaoFilial,
      'idFilial': idFilial,
      'descricaoEmpresa': descricaoEmpresa,
      'idEmpresa': idEmpresa,
      'dataEmissaoNfe': dataEmissaoNfe.toIso8601String(),
      'cnpjEmpresa': cnpjEmpresa,
      'modeloNfe': modeloNfe,
      'numeroNfe': numeroNfe,
      'serieNfe': serieNfe,
      'ipEmissor': ipEmissor,
      'dispositivoEmissor': dispositivoEmissor,
      'ambiente': ambiente,
      'conteudoBase64': conteudoBase64,
      'xmlNfe': xmlNfe,
      'nomeArquivo': nomeArquivo,
      'valorTotal': valorTotal,
      'linkNfe': linkNfe,
      'dataRegistro': dataRegistro.toIso8601String(),
      'tipPagamento': tipPagamento,
    };
  }

  // Cópia do modelo com possibilidade de alterar campos
  SisficalNfceModel copyWith({
    int? id,
    String? descricaoFilial,
    String? idFilial,
    String? descricaoEmpresa,
    String? idEmpresa,
    DateTime? dataEmissaoNfe,
    String? cnpjEmpresa,
    String? modeloNfe,
    String? numeroNfe,
    String? serieNfe,
    String? ipEmissor,
    String? dispositivoEmissor,
    String? ambiente,
    String? conteudoBase64,
    String? xmlNfe,
    String? nomeArquivo,
    double? valorTotal,
    String? linkNfe,
    DateTime? dataRegistro,
    String? tipPagamento,
  }) {
    return SisficalNfceModel(
      id: id ?? this.id,
      descricaoFilial: descricaoFilial ?? this.descricaoFilial,
      idFilial: idFilial ?? this.idFilial,
      descricaoEmpresa: descricaoEmpresa ?? this.descricaoEmpresa,
      idEmpresa: idEmpresa ?? this.idEmpresa,
      dataEmissaoNfe: dataEmissaoNfe ?? this.dataEmissaoNfe,
      cnpjEmpresa: cnpjEmpresa ?? this.cnpjEmpresa,
      modeloNfe: modeloNfe ?? this.modeloNfe,
      numeroNfe: numeroNfe ?? this.numeroNfe,
      serieNfe: serieNfe ?? this.serieNfe,
      ipEmissor: ipEmissor ?? this.ipEmissor,
      dispositivoEmissor: dispositivoEmissor ?? this.dispositivoEmissor,
      ambiente: ambiente ?? this.ambiente,
      conteudoBase64: conteudoBase64 ?? this.conteudoBase64,
      xmlNfe: xmlNfe ?? this.xmlNfe,
      nomeArquivo: nomeArquivo ?? this.nomeArquivo,
      valorTotal: valorTotal ?? this.valorTotal,
      linkNfe: linkNfe ?? this.linkNfe,
      dataRegistro: dataRegistro ?? this.dataRegistro,
      tipPagamento: tipPagamento ?? this.tipPagamento,
    );
  }

  @override
  String toString() {
    return 'NFeModel(id: $id, descricaoFilial: $descricaoFilial, idFilial: $idFilial, ...)';
  }
}
