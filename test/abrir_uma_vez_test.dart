import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:webapp_pedido_mesa/screens/item/abrir_uma_vez.dart';

void main() {
  test('toque repetido enquanto o produto abre não abre outro', () async {
    var aberturas = 0;
    final fechar = Completer<void>();
    Future<void> abrir() async {
      aberturas++;
      await fechar.future; // janela aberta até o cliente fechar
    }

    final primeiro = abrirUmaVez(abrir);
    await abrirUmaVez(abrir); // ignorado: ainda aberto
    await abrirUmaVez(abrir);
    expect(aberturas, 1);

    fechar.complete();
    await primeiro;
    // depois de fechar, abre de novo normalmente
    await abrirUmaVez(() async => aberturas++);
    expect(aberturas, 2);
  });

  test('se der erro ao abrir, libera para abrir de novo', () async {
    await expectLater(
        abrirUmaVez(() async => throw Exception('falhou')), throwsException);
    var abriu = false;
    await abrirUmaVez(() async => abriu = true);
    expect(abriu, isTrue);
  });
}
