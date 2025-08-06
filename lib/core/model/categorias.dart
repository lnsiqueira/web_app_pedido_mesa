class Categoria {
  final int id;
  final String desCategoria;
  final String imagem;

  Categoria({
    required this.id,
    required this.desCategoria,
    required this.imagem,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      desCategoria: json['desCategoria'],
      imagem: json['imagem'],
    );
  }
}
