import 'package:flutter_test/flutter_test.dart';
import 'package:webapp_pedido_mesa/services/comanda_service.dart';

void main() {
  test('número da comanda lido no código de barras, como no tablet', () {
    // zeros da etiqueta saem
    expect(numeroDaComanda('000156'), '156');
    expect(numeroDaComanda('00975'), '975');
    // só os dígitos
    expect(numeroDaComanda('W0380'), '380');
    expect(numeroDaComanda(' 1858\n'), '1858');
    expect(numeroDaComanda('2222'), '2222');
    // sem número: ignora a leitura
    expect(numeroDaComanda('ABC'), '');
    expect(numeroDaComanda('0000'), '');
    expect(numeroDaComanda(''), '');
  });
}
