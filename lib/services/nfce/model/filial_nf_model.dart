class FilialNFModel {
  final String cnpj;
  final String ie;
  final String razaoSocial;
  final String endereco;
  final int crt;
  final String telefone;

  FilialNFModel({
    required this.cnpj,
    required this.ie,
    required this.razaoSocial,
    required this.endereco,
    required this.crt,
    required this.telefone,
  });

  factory FilialNFModel.fromJson(Map<String, dynamic> json) {
    return FilialNFModel(
      cnpj: json['cnpj'] ?? '',
      ie: json['ie'] ?? '',
      razaoSocial: json['razaoSocial'] ?? '',
      endereco: json['endereco'] ?? '',
      crt: json['crt'] ?? 0,
      telefone: json['telefone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cnpj': cnpj,
      'ie': ie,
      'razaoSocial': razaoSocial,
      'endereco': endereco,
      'crt': crt,
      'telefone': telefone,
    };
  }
}
