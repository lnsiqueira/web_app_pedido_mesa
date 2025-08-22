class Log {
  int? id;
  String? descricaoFilial;
  String? idFilial;
  String? idEmpresa;
  String? descricaoEmpresa;
  DateTime dataHora;
  String? tipoEvento;
  String? descricaoEvento;
  String? descricaoAtividade;
  String? status;
  String? valorChave;
  String? descricaoChave;
  String? ambiente;
  String? endpoint;
  Map<String, dynamic>? valorJson; // campo JSON

  Log({
    this.id,
    this.descricaoFilial,
    this.idFilial,
    this.idEmpresa,
    this.descricaoEmpresa,
    required this.dataHora,
    this.tipoEvento,
    this.descricaoEvento,
    this.descricaoAtividade,
    this.status,
    this.valorChave,
    this.descricaoChave,
    this.ambiente,
    this.endpoint,
    this.valorJson,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricaoFilial': descricaoFilial ?? '',
      'idFilial': idFilial ?? '',
      'idEmpresa': idEmpresa ?? '',
      'descricaoEmpresa': descricaoEmpresa ?? '',
      'dataHora': dataHora.toIso8601String(),
      'tipoEvento': tipoEvento ?? '',
      'descricaoEvento': descricaoEvento ?? '',
      'descricaoAtividade': descricaoAtividade ?? '',
      'status': status ?? '',
      'valorChave': valorChave ?? '',
      'descricaoChave': descricaoChave ?? '',
      'ambiente': ambiente ?? '',
      'endpoint': endpoint ?? '',
      'valorJson': valorJson,
    };
  }
}
