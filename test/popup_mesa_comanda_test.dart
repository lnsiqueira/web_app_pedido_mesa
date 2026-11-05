import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webapp_pedido_mesa/l10n/app_localizations.dart';
import 'package:webapp_pedido_mesa/widgets/popup_mesa_comanda.dart';

/// Abre o popup da comanda numa tela do tamanho [tela] e devolve o resultado
/// do showDialog quando ele fecha.
Future<List<Object?>> _abrir(WidgetTester tester, Size tela,
    {double escalaTexto = 1}) async {
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final resultados = <Object?>[];
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(escalaTexto)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            resultados.add(await showDialog<Map<String, String>?>(
              context: context,
              builder: (_) => PopupMesaComanda(
                formKey: GlobalKey<FormState>(),
                mesaController: TextEditingController(),
                comandaController: TextEditingController(),
              ),
            ));
          },
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultados;
}

void main() {
  // tamanhos de tela (em pontos): Safari do iPhone com as barras, iPhone SE,
  // iPhone grande
  for (final tela in const [
    Size(375, 560),
    Size(375, 620),
    Size(390, 664),
    Size(430, 800),
  ]) {
    for (final escala in const [1.0, 1.3])
      testWidgets(
          'teclado inteiro visível acima do Confirmar em $tela '
          '(texto x$escala)', (tester) async {
        // texto maior simula a fonte do Safari, que ocupa mais altura
        await _abrir(tester, tela, escalaTexto: escala);

        final confirmar = tester.getRect(find.text('Confirmar'));
        final zero = tester.getRect(find
            .ancestor(of: find.text('0'), matching: find.byType(InkWell))
            .first);
        final x = tester.getRect(find
            .ancestor(
                of: find.byIcon(Icons.clear_rounded),
                matching: find.byType(InkWell))
            .first);

        // última linha (⌫ 0 X) inteira, sem ficar embaixo do botão
        expect(zero.bottom, lessThanOrEqualTo(confirmar.top));
        expect(x.bottom, lessThanOrEqualTo(confirmar.top));
        expect(zero.bottom, lessThanOrEqualTo(tela.height));
        expect(tester.takeException(), isNull);
      });
  }

  testWidgets('X fecha o popup sem comanda', (tester) async {
    final resultados = await _abrir(tester, const Size(390, 664));
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(PopupMesaComanda), findsNothing);
    expect(resultados, [null]);
  });

  testWidgets('X fica à esquerda do 0 e o apagar à direita', (tester) async {
    await _abrir(tester, const Size(390, 664));
    final x = tester.getCenter(find.byIcon(Icons.clear_rounded));
    final zero = tester.getCenter(find.text('0'));
    final apagar = tester.getCenter(find.byIcon(Icons.backspace_rounded));
    expect(x.dx, lessThan(zero.dx));
    expect(apagar.dx, greaterThan(zero.dx));
  });

  for (final tela in const [Size(375, 560), Size(390, 664)]) {
    testWidgets('erro aparece dentro do popup, acima do Confirmar, em $tela',
        (tester) async {
      await _abrir(tester, tela);
      // sem número: avisa sem consultar a Bratter
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      final erro = find.text('Digite o número da comanda.');
      expect(erro, findsOneWidget);
      expect(find.descendant(of: find.byType(Dialog), matching: erro),
          findsOneWidget);
      expect(tester.getRect(erro).bottom,
          lessThanOrEqualTo(tester.getRect(find.text('Confirmar')).top));
      // teclado continua inteiro com o aviso na tela
      final zero = tester.getRect(find
          .ancestor(of: find.text('0'), matching: find.byType(InkWell))
          .first);
      expect(zero.bottom, lessThanOrEqualTo(tester.getRect(erro).top));
      expect(tester.takeException(), isNull);

      // ao digitar, o aviso some
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(erro, findsNothing);
    });
  }
}
