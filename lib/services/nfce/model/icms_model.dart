class ICMS {
  final double vProd;
  final double vFrete;
  final double vSeg;
  final double vDesc;
  final double vIPI;
  final double vPIS;
  final double vCOFINS;
  final double vOutro;
  final double vNF;

  ICMS({
    required this.vProd,
    required this.vFrete,
    required this.vSeg,
    required this.vDesc,
    required this.vIPI,
    required this.vPIS,
    required this.vCOFINS,
    required this.vOutro,
    required this.vNF,
  });

  Map<String, dynamic> toJson() {
    return {
      'vProd': vProd,
      'vFrete': vFrete,
      'vSeg': vSeg,
      'vDesc': vDesc,
      'vIPI': vIPI,
      'vPIS': vPIS,
      'vCOFINS': vCOFINS,
      'vOutro': vOutro,
      'vNF': vNF,
    };
  }
}
