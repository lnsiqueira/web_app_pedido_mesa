class PackageException implements Exception {
  final String code; // Código do erro (ex: 'FALHA_CONEXAO')
  final String message; // Mensagem amigável
  final dynamic details;
  final bool isSuccess; // Detalhes técnicos (opcional)

  PackageException({
    required this.code,
    required this.message,
    this.details,
    this.isSuccess = false,
  });

  @override
  String toString() => '[$code] $message';
}
