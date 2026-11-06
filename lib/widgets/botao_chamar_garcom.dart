import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webapp_pedido_mesa/services/chamado_garcom.dart';
import 'package:webapp_pedido_mesa/widgets/pilula_topo.dart';

/// Depois de chamar, o botão fica "Garçom a caminho" por este tempo (evita
/// vários chamados seguidos).
const _esperaChamado = Duration(seconds: 20);

/// Último chamado (fora do widget: sair e voltar para o início não libera
/// antes do tempo)
DateTime? _ultimoChamado;

/// "Chamar garçom" no topo da tela inicial.
class BotaoChamarGarcom extends StatefulWidget {
  const BotaoChamarGarcom({super.key});

  @override
  State<BotaoChamarGarcom> createState() => _BotaoChamarGarcomState();
}

class _BotaoChamarGarcomState extends State<BotaoChamarGarcom> {
  bool _enviando = false;
  Timer? _liberar;

  bool get _chamado =>
      _ultimoChamado != null &&
      DateTime.now().difference(_ultimoChamado!) < _esperaChamado;

  @override
  void initState() {
    super.initState();
    _agendarLiberacao();
  }

  @override
  void dispose() {
    _liberar?.cancel();
    super.dispose();
  }

  /// Depois de 20 s do chamado o botão volta a ficar livre
  void _agendarLiberacao() {
    _liberar?.cancel();
    if (!_chamado) return;
    final falta = _esperaChamado - DateTime.now().difference(_ultimoChamado!);
    _liberar = Timer(falta + const Duration(milliseconds: 100), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _chamar() async {
    if (_enviando || _chamado) return;
    setState(() => _enviando = true);
    final ok = await chamarGarcom();
    if (ok) _ultimoChamado = DateTime.now();
    if (!mounted) return;
    setState(() => _enviando = false);
    _agendarLiberacao();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? const Color(0xFF2E7D32) : Colors.red.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(ok ? Icons.room_service_rounded : Icons.wifi_off_rounded,
                color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ok
                    ? 'Garçom chamado! Já já alguém vem até a sua mesa.'
                    : 'Não foi possível chamar agora. Tente de novo.',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final chamado = _chamado;
    const verde = Color(0xFF2E7D32);
    return PilulaTopo(
      icone: chamado ? Icons.check_circle_rounded : Icons.room_service_outlined,
      texto: chamado ? 'Garçom a caminho' : 'Chamar garçom',
      // verde depois de chamar
      cor: chamado ? verde : null,
      fundo: chamado ? const Color(0xFFEDF7EE) : null,
      borda: chamado ? const Color(0xFFB9DFBB) : null,
      carregando: _enviando,
      onTap: chamado ? null : _chamar,
    );
  }
}
