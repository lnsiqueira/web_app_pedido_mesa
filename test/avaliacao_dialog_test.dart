import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/pagamento/avaliacao_dialog.dart';

/// Abre a avaliação numa tela de celular e devolve o que foi salvo.
Future<List<(int, List<String>, String)>> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final salvos = <(int, List<String>, String)>[];
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showDialog<int>(
            context: context,
            builder: (_) => AvaliacaoDialog(
              salvar: (n, t, o) async => salvos.add((n, List.of(t), o)),
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return salvos;
}

void main() {
  // teclado do iPhone: no Safari a área visível encolhe; em outros
  // navegadores vem como espaço ocupado embaixo (viewInsets)
  for (final (nome, safari) in const [('Safari', true), ('Android', false)]) {
    testWidgets('com o teclado aberto o comentário fica visível ($nome)',
        (tester) async {
      final salvos = await _abrir(tester);
      await tester.tap(find.byIcon(Icons.star_rounded).last); // 5 estrelas
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      // teclado sobe: sobram ~420 px de tela visível
      if (safari) {
        tester.view.physicalSize = const Size(375, 420);
      } else {
        tester.view.viewInsets =
            const FakeViewPadding(bottom: 392); // 812 - 420
      }
      // deixa correr as tentativas de rolar até o campo (150/400/800 ms)
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull); // nada vazando da janela

      final campo = tester.getRect(find.byType(TextField));
      expect(campo.top, greaterThanOrEqualTo(0));
      expect(campo.bottom, lessThanOrEqualTo(420));
      // enquanto digita, o topo encolhe (sem o ícone e o subtítulo)
      expect(find.byIcon(Icons.storefront_rounded), findsNothing);
      expect(find.textContaining('Sua avaliação ajuda'), findsNothing);

      await tester.enterText(find.byType(TextField), 'muito bom');
      await tester.pump();

      // dá para rolar até o botão e enviar
      await tester.ensureVisible(find.text('Enviar avaliação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar avaliação'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(salvos, hasLength(1));
      expect(salvos.first.$1, 5);
      expect(salvos.first.$3, 'muito bom');
      tester.view.resetViewInsets();
    });
  }

  testWidgets('sem teclado mostra o topo completo', (tester) async {
    await _abrir(tester);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
    expect(find.text('Como foi sua experiência?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
