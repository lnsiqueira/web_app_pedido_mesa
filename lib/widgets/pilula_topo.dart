import 'package:flutter/material.dart';

/// Botão em pílula do topo da tela inicial ("Chamar garçom", "Meus pedidos"):
/// branco com borda suave, no mesmo estilo da barra de busca.
class PilulaTopo extends StatelessWidget {
  const PilulaTopo({
    super.key,
    required this.icone,
    required this.texto,
    this.onTap,
    this.cor,
    this.fundo,
    this.borda,
    this.carregando = false,
  });

  final IconData icone;
  final String texto;
  final VoidCallback? onTap;

  /// Cor do ícone e do texto (padrão: cinza escuro, ícone laranja)
  final Color? cor;
  final Color? fundo;
  final Color? borda;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final corIcone = cor ?? const Color(0xFFE8710A);
    final corTexto = cor ?? Colors.grey.shade900;
    return Material(
      color: fundo ?? Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: borda ?? Colors.grey.shade300),
      ),
      shadowColor: Colors.black.withOpacity(0.25),
      elevation: 1.5,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: carregando
                    ? Padding(
                        padding: const EdgeInsets.all(2),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: corIcone),
                      )
                    : Icon(icone, size: 18, color: corIcone),
              ),
              const SizedBox(width: 7),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: corTexto,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
