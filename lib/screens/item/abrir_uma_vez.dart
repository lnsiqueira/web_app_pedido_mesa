bool _abrindoProduto = false;

/// Abre um produto/grupo por vez: toques repetidos enquanto ele carrega (ou
/// com um já aberto) são ignorados, senão abre um em cima do outro.
/// [abrir] só termina quando o cliente fecha o que abriu.
Future<void> abrirUmaVez(Future<void> Function() abrir) async {
  if (_abrindoProduto) return;
  _abrindoProduto = true;
  try {
    await abrir();
  } finally {
    _abrindoProduto = false;
  }
}
