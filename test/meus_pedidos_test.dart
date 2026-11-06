import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/pagamento/pedido_enviado_view.dart';
import 'package:webapp_pedido_mesa/services/storage/pedidos_enviados_storage.dart';
import 'package:webapp_pedido_mesa/widgets/meus_pedidos.dart';

Future<void> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => mostrarMeusPedidos(context),
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem pedidos mostra aviso', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _abrir(tester);
    expect(find.text('Meus pedidos'), findsOneWidget);
    expect(find.text('Nenhum pedido enviado ainda'), findsOneWidget);
    expect(find.textContaining('Invoice'), findsNothing);
  });

  testWidgets('mostra os pedidos enviados hoje, o último primeiro',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await PedidosEnviadosStorage.salvar(const PedidoEnviado(
      mesa: '9',
      comanda: '156',
      itens: [(qtd: 1, nome: 'CAFE EXPRESSO', total: 6.5)],
      total: 6.5,
    ));
    await PedidosEnviadosStorage.salvar(const PedidoEnviado(
      mesa: '9',
      comanda: '156',
      itens: [
        (qtd: 2, nome: 'REFRIGERANTE COCA COLA ZERO LATA 350 ML', total: 18.8),
      ],
      total: 18.8,
    ));
    await _abrir(tester);

    expect(find.text('Enviado'), findsNWidgets(2));
    expect(find.text('Mesa 9 · Comanda 156'), findsNWidgets(2));
    expect(find.text('Total dos pedidos'), findsOneWidget);
    expect(find.text('R\$ 25,30'), findsOneWidget);
    // último enviado aparece em cima
    expect(
        tester
            .getTopLeft(find.text('REFRIGERANTE COCA COLA ZERO LATA 350 ML'))
            .dy,
        lessThan(tester.getTopLeft(find.text('CAFE EXPRESSO')).dy));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Meus pedidos'), findsNothing);
  });
}
