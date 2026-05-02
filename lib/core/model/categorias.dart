class Categoria {
  final int id;
  final String desCategoria;
  final String imagem;
  final String? horaInicio;
  final String? horaFim;

  Categoria({
    required this.id,
    required this.desCategoria,
    required this.imagem,
    this.horaInicio,
    this.horaFim,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      desCategoria: json['desCategoria'],
      imagem: json['imagem'],

      // NOVOS CAMPOS
      horaInicio: json['horaInicio'],
      horaFim: json['horaFim'],
    );
  }
}
