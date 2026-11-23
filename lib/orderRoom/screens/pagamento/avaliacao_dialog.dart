import 'package:flutter/material.dart';

/// Janela de avaliação depois do pedido. [salvar] grava a nota, as tags e o
/// comentário (nota 0 = o cliente tocou em "Não").
class AvaliacaoDialog extends StatefulWidget {
  const AvaliacaoDialog({super.key, required this.salvar});

  final Future<void> Function(int nota, List<String> tags, String observacao)
      salvar;

  @override
  State<AvaliacaoDialog> createState() => _AvaliacaoDialogState();
}

class _AvaliacaoDialogState extends State<AvaliacaoDialog> {
  int notaSelecionada = 0;
  final List<String> tagsSelecionadas = [];
  final TextEditingController obsController = TextEditingController();
  bool enviado = false;

  // Com o teclado aberto (iPhone) sobra pouca altura: a janela rola, o topo
  // encolhe e o campo do comentário é rolado para ficar visível
  bool digitando = false;
  final campoKey = GlobalKey();
  void mostrarCampo() {
    // o teclado do iPhone sobe aos poucos: tenta de novo depois
    for (final ms in const [150, 400, 800]) {
      Future.delayed(Duration(milliseconds: ms), () {
        final c = campoKey.currentContext;
        if (c != null && c.mounted) {
          Scrollable.ensureVisible(c,
              alignment: 0.5, duration: const Duration(milliseconds: 200));
        }
      });
    }
  }

  final tags = [
    'Atendimento',
    'Comida ótima',
    'Rápido',
    'Embalagem',
    'Preço justo'
  ];
  final labels = ['', 'Ruim', 'Regular', 'Bom', 'Muito bom', 'Excelente!'];
  final labelColors = [
    Colors.transparent,
    Colors.red.shade600,
    Colors.orange.shade600,
    Colors.yellow.shade700,
    Colors.lightGreen.shade600,
    Colors.green.shade600,
  ];

  @override
  void dispose() {
    obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (enviado) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: Colors.green.shade700, size: 32),
              ),
              const SizedBox(height: 20),
              const Text('Obrigado pela avaliação!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Seu feedback é muito importante\npara continuarmos melhorando.',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade500, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: digitando
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Topo com fundo suave (só o título enquanto digita)
            Container(
              width: double.infinity,
              padding: digitando
                  ? const EdgeInsets.fromLTRB(24, 16, 24, 12)
                  : const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
                ),
              ),
              child: Column(
                children: [
                  if (!digitando) ...[
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.orange.shade200, width: 0.8),
                      ),
                      child: Icon(Icons.storefront_rounded,
                          color: Colors.orange.shade700, size: 30),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text(
                    'Como foi sua experiência?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  if (!digitando) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Sua avaliação ajuda outros clientes\ne melhora nosso serviço.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // Corpo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  // Estrelas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < notaSelecionada;
                      return GestureDetector(
                        onTap: () => setState(() => notaSelecionada = i + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_rounded,
                            size: 44,
                            color: filled
                                ? Colors.amber.shade400
                                : Colors.grey.shade500,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),

                  // Label da nota
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      notaSelecionada > 0
                          ? labels[notaSelecionada]
                          : 'Toque para avaliar',
                      key: ValueKey(notaSelecionada),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: notaSelecionada > 0
                            ? labelColors[notaSelecionada]
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),

                  // Tags (aparecem após seleção)
                  if (notaSelecionada > 0) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: tags.map((tag) {
                        final ativo = tagsSelecionadas.contains(tag);
                        return GestureDetector(
                          onTap: () => setState(() {
                            ativo
                                ? tagsSelecionadas.remove(tag)
                                : tagsSelecionadas.add(tag);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  ativo ? Colors.orange.shade50 : Colors.white,
                              border: Border.all(
                                color: ativo
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade300,
                                width: ativo ? 1.5 : 0.8,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: ativo
                                    ? Colors.orange.shade800
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Campo de texto
                    Container(
                      key: campoKey,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade300, width: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Focus(
                        onFocusChange: (foco) {
                          setState(() => digitando = foco);
                          if (foco) mostrarCampo();
                        },
                        child: TextField(
                          controller: obsController,
                          maxLines: 3,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Quer comentar algo? (opcional)',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Botões
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () async {
                        await widget.salvar(0, const [], '');

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        side:
                            BorderSide(color: Colors.grey.shade300, width: 0.8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Não',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: AnimatedOpacity(
                      opacity: 1.0, // pode manter sempre ativo
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: () async {
                          await widget.salvar(notaSelecionada, tagsSelecionadas,
                              obsController.text);

                          setState(() => enviado = true);

                          Future.delayed(const Duration(seconds: 2), () {
                            if (context.mounted) {
                              Navigator.pop(context, notaSelecionada);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          disabledBackgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Enviar avaliação',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
