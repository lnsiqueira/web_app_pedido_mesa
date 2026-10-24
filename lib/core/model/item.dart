class ItemModel {
  int? id;
  String? idFilial;
  int? idCategoriaFilial;
  int? idProduto;
  String? plu;
  String? desProduto;
  String? descricaoProduto;
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
  int? quantidadeDisponivel;
  bool? ativo;

  /// Acréscimos escolhidos (Dashboard): vão para a comanda como itens
  /// próprios, logo abaixo do produto
  List<AcrescimoEscolhido> acrescimos;

  /// Opções do produto como vieram da Bratter (o carrinho guarda só as
  /// escolhidas); usadas para reabrir o produto e editar
  List<ItemObsModel>? obsOriginais;

  /// Preço do produto + acréscimos (por unidade)
  double get precoComAcrescimos =>
      (preco ?? 0) + acrescimos.fold(0.0, (t, a) => t + a.preco);

  ItemModel({
    this.id,
    this.idFilial,
    this.idCategoriaFilial,
    this.idProduto,
    this.plu,
    this.desProduto,
    this.descricaoProduto,
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
    this.quantidadeDisponivel,
    this.ativo,
    this.obs,
    this.acrescimos = const [],
    this.obsOriginais,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      idFilial: json['idFilial'],
      idCategoriaFilial: json['idCategoriaFilial'],
      idProduto: json['idProduto'],
      plu: json['plu'],
      desProduto: json['desProduto'],
      descricaoProduto: json['descricaoProduto'],
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
      // ADICIONEI AQUI A IMAGEM VINDO DA NOSSA API
      imageUrl: json['imagemProduto'],
      discountpreco: null,
      codigoBarras: null,
      categoria: null,
      subCategorias: null,
      pesavel: null,
      quantidadeDisponivel: json['quantidadeDisponivel'],
      ativo: json['ativo'],
      obs: (json['Obs'] as List?)
              ?.map((obsJson) => ItemObsModel.fromJson(obsJson))
              .toList() ??
          [],
    );
  }
  ItemModel copyWith({
    double? preco,
    List<ItemObsModel>? obs,
    List<AcrescimoEscolhido>? acrescimos,
    List<ItemObsModel>? obsOriginais,
  }) {
    return ItemModel(
      id: id,
      idFilial: idFilial,
      idCategoriaFilial: idCategoriaFilial,
      idProduto: idProduto,
      plu: plu,
      desProduto: desProduto,
      descricaoProduto: descricaoProduto,
      desIpImpressora: desIpImpressora,
      apiPropria: apiPropria,
      dataCriacao: dataCriacao,
      dataAtualizacao: dataAtualizacao,
      desCategoria: desCategoria,
      preco: preco ?? this.preco,
      imageUrl: imageUrl,
      quantidadeDisponivel: quantidadeDisponivel,
      ativo: ativo,
      obs: obs ?? this.obs,
      acrescimos: acrescimos ?? this.acrescimos,
      obsOriginais: obsOriginais ?? this.obsOriginais,
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

/// Acréscimo escolhido no produto (ex.: "Queijo extra"), com o preço da
/// Bratter
class AcrescimoEscolhido {
  const AcrescimoEscolhido({
    required this.plu,
    required this.nome,
    required this.preco,
  });

  final String plu;
  final String nome;
  final double preco;

  /// Observação na comanda (a comanda guarda só 30 letras)
  String get observacao {
    final t = '+ $nome'.trim();
    return t.length <= 30 ? t : t.substring(0, 30);
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
  // PARA O FIRESTORE

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'titulo': titulo,
      'preco': preco,
      'pluAdd': pluAdd,
      'ordem': ordem,
      if (modificador != null) 'modificador': modificador,
    };
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
