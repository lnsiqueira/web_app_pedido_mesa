import 'package:flutter/material.dart';

const _laranja = Color(0xFFE8710A);

/// Limite só para não estourar o visor (cada loja tem comandas de um
/// tamanho; o número vai inteiro para a Bratter)
const maximoDigitos = 8;

/// Digitar a comanda quando a câmera não consegue ler: fica na mesma tela
/// escura do scanner (troca a câmera pelo teclado, nada aberto por cima).
class TecladoComanda extends StatelessWidget {
  const TecladoComanda({
    super.key,
    required this.digitos,
    required this.onDigito,
    required this.onApagar,
    required this.onLimpar,
    required this.onConfirmar,
    required this.onVoltarCamera,
    required this.onFechar,
    this.verificando,
    this.erro,
    this.rodape,
  });

  final String digitos;
  final ValueChanged<String> onDigito;
  final VoidCallback onApagar;
  final VoidCallback onLimpar;
  final VoidCallback onConfirmar;
  final VoidCallback onVoltarCamera;
  final VoidCallback onFechar;

  /// Número em conferência na Bratter
  final String? verificando;
  final String? erro;

  /// Fica embaixo de tudo (ex.: Chamar garçom)
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    // confirma com qualquer quantidade de dígitos
    final pode = digitos.isNotEmpty && verificando == null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            _topo(),
            // bolinhas e teclado: ocupam o espaço que sobra; em tela baixa
            // (iPhone pequeno com as barras do Safari) rolam, com teclas de
            // tamanho fixo, e o Confirmar continua sempre à vista
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final rolar = c.maxHeight < 420;
                final teclado = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _teclado(),
                );
                final conteudo = Column(
                  mainAxisSize: rolar ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    const SizedBox(height: 14),
                    _visor(),
                    const SizedBox(height: 6),
                    _situacao(),
                    if (rolar)
                      SizedBox(height: 240, child: teclado)
                    else
                      Expanded(child: teclado),
                  ],
                );
                return rolar
                    ? SingleChildScrollView(child: conteudo)
                    : conteudo;
              }),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Use só a comanda que você recebeu hoje. Usar outra pode ser '
                'considerado fraude.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: pode ? onConfirmar : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _laranja,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirmar comanda',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            if (rodape != null) ...[const SizedBox(height: 12), rodape!],
          ],
        ),
      ),
    );
  }

  /// Fechar, título e voltar para a câmera
  Widget _topo() => Row(
        children: [
          IconButton(
            onPressed: onFechar,
            tooltip: 'Fechar',
            icon:
                const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Digite sua comanda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onVoltarCamera,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            label: const Text('Câmera'),
          ),
        ],
      );

  /// Número digitado (ou a dica, vazio)
  Widget _visor() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 64,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: digitos.isEmpty ? Colors.white24 : _laranja,
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              digitos.isEmpty ? 'Número da comanda' : digitos,
              style: TextStyle(
                color: digitos.isEmpty ? Colors.white38 : Colors.white,
                fontSize: digitos.isEmpty ? 20 : 32,
                fontWeight: FontWeight.w800,
                letterSpacing: digitos.isEmpty ? 0 : 4,
              ),
            ),
          ),
        ),
      );

  /// Conferindo a comanda ou o erro
  Widget _situacao() => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: verificando != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text('Verificando comanda $verificando...',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15)),
                    ),
                  ],
                )
              : erro != null
                  ? Text(
                      erro!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  // antes de confirmar: a orientação
                  : Text(
                      'Informe todos os números da comanda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
        ),
      );

  Widget _teclado() => Column(
        children: [
          for (final linha in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['limpar', '0', 'apagar'],
          ])
            Expanded(
              child: Row(
                children: [
                  for (final t in linha)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: _Tecla(
                          texto: t,
                          onTap: verificando != null
                              ? null
                              : t == 'apagar'
                                  ? onApagar
                                  : t == 'limpar'
                                      ? onLimpar
                                      : digitos.length < maximoDigitos
                                          ? () => onDigito(t)
                                          : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
}

class _Tecla extends StatelessWidget {
  const _Tecla({required this.texto, required this.onTap});

  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget conteudo = switch (texto) {
      'apagar' =>
        const Icon(Icons.backspace_outlined, color: Colors.white, size: 24),
      'limpar' => const Text('Limpar',
          style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
      _ => Text(texto,
          style: const TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
    };
    final numero = texto != 'apagar' && texto != 'limpar';
    return Material(
      color: numero ? Colors.white.withOpacity(0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(child: FittedBox(child: conteudo)),
      ),
    );
  }
}
