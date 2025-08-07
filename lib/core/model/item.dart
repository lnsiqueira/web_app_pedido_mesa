class ItemModel {
  int? id;
  String? idFilial;
  int? idCategoriaFilial;
  int? idProduto;
  String? plu;
  String? desProduto;
  String? desIpImpressora;
  bool? apiPropria;
  String? dataCriacao;
  String? dataAtualizacao;
  String? desCategoria;
  final double? preco;
  String? produtoId;
  String? detalhes;
  String? tipoProduto;
  int? quantidade;
  double? peso;
  String? imageUrl;

  double? discountpreco;
  int? codigoBarras;
  String? categoria;
  String? subCategorias;
  bool? pesavel;

  ItemModel({
    this.id,
    this.idFilial,
    this.idCategoriaFilial,
    this.idProduto,
    this.plu,
    this.desProduto,
    this.desIpImpressora,
    this.apiPropria,
    this.dataCriacao,
    this.dataAtualizacao,
    this.desCategoria,
    this.preco,
    this.produtoId,
    this.detalhes,
    this.tipoProduto,
    this.quantidade,
    this.peso,
    this.imageUrl,
    this.discountpreco,
    this.codigoBarras,
    this.categoria,
    this.subCategorias,
    this.pesavel = false,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
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
      preco: null,
      produtoId: null,
      detalhes: null,
      tipoProduto: null,
      quantidade: null,
      peso: null,
      imageUrl: null,
      discountpreco: null,
      codigoBarras: null,
      categoria: null,
      subCategorias: null,
      pesavel: null,
    );
  }
  ItemModel copyWith({double? preco}) {
    return ItemModel(
      id: id,
      idFilial: idFilial,
      idCategoriaFilial: idCategoriaFilial,
      idProduto: idProduto,
      plu: plu,
      desProduto: desProduto,
      desIpImpressora: desIpImpressora,
      apiPropria: apiPropria,
      dataCriacao: dataCriacao,
      dataAtualizacao: dataAtualizacao,
      desCategoria: desCategoria,
      preco: preco ?? this.preco,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'produtoId': produtoId,
      'nome': desProduto,
      'imageUrl': imageUrl,
      'detalhes': detalhes,
      'preco': preco,
      'discountpreco': discountpreco,
      'tipoProduto': tipoProduto,
      'peso': peso,
      'quantidade': quantidade,
    };
  }
}
