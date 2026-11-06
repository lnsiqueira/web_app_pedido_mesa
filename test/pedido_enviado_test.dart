import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/pagamento/pedido_enviado_view.dart';
import 'package:webapp_pedido_mesa/widgets/botao_chamar_garcom.dart';

const _pedido = PedidoEnviado(
  mesa: '16',
  comanda: '380',
  itens: [
    (qtd: 2, nome: 'REFRIGERANTE COCA COLA LATA 350 ML', total: 15.8),
    (qtd: 1, nome: 'PÃO FRANCÊS NA CHAPA COM REQUEIJÃO', total: 10.0),
  ],
  total: 25.8,
);

void _tela(WidgetTester tester, Size tamanho) {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final tamanho in const [
    Size(320, 560),
    Size(375, 664),
    Size(430, 900)
  ]) {
    testWidgets('Pedido enviado! mostra mesa, comanda e itens em $tamanho',
        (tester) async {
      _tela(tester, tamanho);
      var continuou = false;
      await tester.pumpWidget(MaterialApp(
        home: PedidoEnviadoView(
          pedido: _pedido,
          onContinuar: () => continuou = true,
        ),
      ));

      expect(find.text('Pedido enviado!'), findsOneWidget);
      expect(find.text('Mesa 16'), findsOneWidget);
      expect(find.text('Comanda 380'), findsOneWidget);
      expect(find.text('REFRIGERANTE COCA COLA LATA 350 ML'), findsOneWidget);
      expect(find.text('R\$ 15,80'), findsOneWidget);
      expect(find.text('R\$ 25,80'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Continuar fica sempre visível, embaixo
      final continuar = tester.getRect(find.text('Continuar'));
      expect(continuar.bottom, lessThanOrEqualTo(tamanho.height));
      await tester.tap(find.text('Continuar'));
      expect(continuou, isTrue);
    });
  }

  for (final largura in const [320.0, 360.0, 375.0]) {
    testWidgets('topo com Chamar garçom cabe em $largura px', (tester) async {
      _tela(tester, Size(largura, 700));
      // mesmo arranjo do topo da tela inicial: logo + ações que encolhem
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40, height: 40),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(children: const [
                      BotaoChamarGarcom(),
                      SizedBox(width: 6),
                      SizedBox(width: 130, height: 40), // Meus pedidos
                      SizedBox(width: 48, height: 48), // carrinho
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
      expect(find.text('Chamar garçom'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('Chamar garçom')).right,
          lessThanOrEqualTo(largura));
    });
  }
}
