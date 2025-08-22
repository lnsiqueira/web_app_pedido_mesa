class ResultadoImposto {
  final double baseCompra;
  final double basePisCofins;
  final double valorIcms;
  final double valorPis;
  final double valorCofins;
  final double totalTributos;

  ResultadoImposto({
    required this.baseCompra,
    required this.basePisCofins,
    required this.valorIcms,
    required this.valorPis,
    required this.valorCofins,
    required this.totalTributos,
  });
}

ResultadoImposto calcularImpostos({
  required double precoProduto,
  required double aliquotaIcms,
  required double aliquotaPis,
  required double aliquotaCofins,
  required double quantidade,
}) {
  // Converter alíquotas para decimal
  final icmsDecimal = double.parse((aliquotaIcms / 100).toStringAsFixed(2));
  final pisDecimal = double.parse((aliquotaPis / 100).toStringAsFixed(2));
  final cofinsDecimal = double.parse((aliquotaCofins / 100).toStringAsFixed(2));

  // Valor ICMS
  final valorIcms = double.parse(
    (precoProduto * icmsDecimal).toStringAsFixed(2),
  );

  // Base de compra (sem ICMS)
  final baseCompra = double.parse(
    (precoProduto - valorIcms).toStringAsFixed(2),
  );

  // Base de cálculo PIS/COFINS
  final basePisCofins = double.parse(
    (aliquotaIcms > 0 ? baseCompra : precoProduto).toStringAsFixed(2),
  );

  // Valores de PIS e COFINS
  final valorPis = double.parse(
    (basePisCofins * pisDecimal).toStringAsFixed(2),
  );
  final valorCofins = double.parse(
    (basePisCofins * cofinsDecimal).toStringAsFixed(2),
  );

  // Total de tributos
  final totalTributos = double.parse(
    (valorIcms + valorPis + valorCofins).toStringAsFixed(2),
  );

  return ResultadoImposto(
    // baseCompra: double.parse(baseCompra.toStringAsFixed(2)),
    // basePisCofins: double.parse(basePisCofins.toStringAsFixed(2)),
    // valorIcms: double.parse(valorIcms.toStringAsFixed(2)),
    // valorPis: double.parse(valorPis.toStringAsFixed(2)),
    // valorCofins: double.parse(valorCofins.toStringAsFixed(2)),
    // totalTributos: double.parse(totalTributos.toStringAsFixed(2)),
    baseCompra: double.parse((baseCompra * quantidade).toStringAsFixed(2)),
    basePisCofins: double.parse(
      (basePisCofins * quantidade).toStringAsFixed(2),
    ),
    valorIcms: double.parse((valorIcms * quantidade).toStringAsFixed(2)),
    valorPis: double.parse((valorPis * quantidade).toStringAsFixed(2)),
    valorCofins: double.parse((valorCofins * quantidade).toStringAsFixed(2)),
    totalTributos: double.parse(
      (totalTributos * quantidade).toStringAsFixed(2),
    ),
  );
}
