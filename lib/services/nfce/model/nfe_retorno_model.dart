class NFeRetorno {
  final String nome;
  final DateTime data;
  final String base64;
  final String xmlNfe;

  NFeRetorno({
    required this.nome,
    required this.data,
    required this.base64,
    required this.xmlNfe,
  });

  // Converte de JSON para o modelo
  factory NFeRetorno.fromJson(Map<String, dynamic> json) {
    return NFeRetorno(
      nome: json['Nome'] ?? '',
      data: DateTime.parse(json['Data']),
      base64: json['Base64'] ?? '',
      xmlNfe: json['XML'] ?? '',
    );
  }

  // Converte o modelo para JSON
  Map<String, dynamic> toJson() {
    return {
      'Nome': nome,
      'Data': data.toIso8601String(),
      'Base64': base64,
      'XML': xmlNfe,
    };
  }

  // Métodos úteis adicionais

  // Verifica se o PDF está vazio
  bool get pdfIsEmpty => base64.isEmpty;

  // Verifica se o XML está vazio
  bool get xmlIsEmpty => xmlNfe.isEmpty;

  // Formata a data para exibição
  String get dataFormatada {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  // Formata a hora para exibição
  String get horaFormatada {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'NFeRetorno(nome: $nome, data: $data, base64: ${base64.length} bytes, xmlNfe: ${xmlNfe.length} bytes)';
  }
}
