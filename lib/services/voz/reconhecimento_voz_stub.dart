/// Sem navegador: não há reconhecimento de voz
class ReconhecimentoVoz {
  bool get disponivel => false;
  bool get ouvindo => false;

  void iniciar({
    required String idioma,
    required void Function(String texto, bool fim) onTexto,
    required void Function() onFim,
    void Function(String erro)? onErro,
  }) {}

  void parar() {}
}

/// Vibração curta do celular (sem navegador: nada)
void vibrar(int milissegundos) {}
