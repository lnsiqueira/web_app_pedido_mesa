import 'package:flutter/material.dart';
import 'package:webapp_pedido_mesa/l10n/app_localizations.dart';
import 'package:webapp_pedido_mesa/services/storage/pedidos_enviados_storage.dart';
import 'package:webapp_pedido_mesa/widgets/pilula_topo.dart';

const _laranja = Color(0xFFE8710A);

String _reais(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "Meus pedidos" do topo: abre os pedidos que este celular enviou hoje.
class MeusPedidosWidget extends StatelessWidget {
  const MeusPedidosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PilulaTopo(
      icone: Icons.receipt_long_outlined,
      texto: AppLocalizations.of(context)!.myOrders,
      onTap: () => mostrarMeusPedidos(context),
    );
  }
}

Future<void> mostrarMeusPedidos(BuildContext context) async {
  final pedidos = await PedidosEnviadosStorage.deHoje();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => _MeusPedidosSheet(pedidos: pedidos),
  );
}

class _MeusPedidosSheet extends StatelessWidget {
  const _MeusPedidosSheet({required this.pedidos});
  final List<PedidoSalvo> pedidos;

  @override
  Widget build(BuildContext context) {
    final total = pedidos.fold<double>(0, (s, p) => s + p.pedido.total);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // alça
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Meus pedidos',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),
            if (pedidos.isEmpty)
              const _Vazio()
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Enviados hoje deste celular',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: pedidos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CardPedido(pedidos[i]),
                ),
              ),
              // total geral só quando há mais de um pedido
              if (pedidos.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Total dos pedidos',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      Text(_reais(total),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Text(
                  'O valor fica na comanda e é pago no caixa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardPedido extends StatelessWidget {
  const _CardPedido(this.salvo);
  final PedidoSalvo salvo;

  @override
  Widget build(BuildContext context) {
    final p = salvo.pedido;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 15, color: Color(0xFF2E7D32)),
                    SizedBox(width: 5),
                    Text('Enviado',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _hora(salvo.quando),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            [
              if (p.mesa.isNotEmpty) 'Mesa ${p.mesa}',
              'Comanda ${p.comanda}',
            ].join(' · '),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final i in p.itens)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i.qtd}x',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _laranja)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(i.nome, style: const TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(width: 10),
                  Text(_reais(i.total), style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          const Divider(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text('Total',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Text(_reais(p.total),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 34, color: Colors.orange.shade700),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum pedido enviado ainda',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Quando você enviar um pedido, ele aparece aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
