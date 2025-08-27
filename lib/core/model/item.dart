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
  List<ItemObsModel>? obs;
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
    this.obs,
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
      obs: (json['Obs'] as List?)
              ?.map((obsJson) => ItemObsModel.fromJson(obsJson))
              .toList() ??
          [],
    );
  }
  ItemModel copyWith({double? preco, List<ItemObsModel>? obs}) {
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
      obs: obs ?? this.obs,
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

class ItemObsModel {
  final String tipo;
  String titulo;
  final double preco;
  int pluAdd;
  final int ordem;
  String? modificador;

  ItemObsModel(
      {required this.tipo,
      required this.titulo,
      required this.preco,
      required this.pluAdd,
      required this.ordem,
      this.modificador});
  ItemObsModel copyWith({
    String? tipo,
    String? titulo,
    double? preco,
    int? pluAdd,
    int? ordem,
    String? modificador,
    bool clearModificador = false, // ← ADICIONE ESTA LINHA
  }) {
    return ItemObsModel(
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      preco: preco ?? this.preco,
      pluAdd: pluAdd ?? this.pluAdd,
      ordem: ordem ?? this.ordem,
      modificador: clearModificador
          ? null
          : (modificador ?? this.modificador), // ← MODIFIQUE ESTA LINHA
    );
  }

  factory ItemObsModel.fromJson(Map<String, dynamic> json) {
    return ItemObsModel(
        tipo: json['tipo'],
        titulo: json['titulo'],
        preco: json['preco'],
        pluAdd: json['pluAdd'],
        ordem: json['ordem'],
        modificador: json['Modificador']);
  }
}

//// to criando essa model so para a gente pegar as info preço e obs e concatrenar com a nossa lista de produtos do azure
class ProdutoInfo {
  final double? preco;
  final List<ItemObsModel> obs;

  ProdutoInfo({this.preco, this.obs = const []});
}
