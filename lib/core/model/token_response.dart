class TokenResponse {
  final String usuario;
  final String tokenDao;
  final String dataValidade;

  TokenResponse({
    required this.usuario,
    required this.tokenDao,
    required this.dataValidade,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      usuario: json['Usuario'],
      tokenDao: json['TokenDao'],
      dataValidade: json['DataValidade'],
    );
  }
}
