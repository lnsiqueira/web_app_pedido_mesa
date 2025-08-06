class Produto {
  final int id;
  final String idFilial;
  final int idCategoriaFilial;
  final int idProduto;
  final String plu;
  final String desProduto;
  final String? desIpImpressora;
  final bool apiPropria;
  final String? dataCriacao;
  final String? dataAtualizacao;
  final String? desCategoria;

  Produto({
    required this.id,
    required this.idFilial,
    required this.idCategoriaFilial,
    required this.idProduto,
    required this.plu,
    required this.desProduto,
    this.desIpImpressora,
    required this.apiPropria,
    this.dataCriacao,
    this.dataAtualizacao,
    this.desCategoria,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      idFilial: json['idFilial'],
      idCategoriaFilial: json['idCategoriaFilial'],
      idProduto: json['idProduto'],
      plu: json['plu'],
      desProduto: json['desProduto'],
      desIpImpressora: json['desIpImpressora'],
      apiPropria: json['apiPropria'],
      dataCriacao: json['dataCriacao'],
      dataAtualizacao: json['dataAtualizacao'],
      desCategoria: json['desCategoria'],
    );
  }
}
