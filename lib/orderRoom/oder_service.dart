import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';

Future<String> gerarNovaComandaWebApp() async {
  final firestore = FirebaseFirestore.instance;

  final filialRef = firestore.collection('Filial').doc(codFilial);

  return firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(filialRef);

    if (!snapshot.exists) {
      throw Exception('Filial não encontrada');
    }

    final data = snapshot.data() as Map<String, dynamic>;

    final String comandaAtualStr = data['comanda_atual_webapp'] ?? '0';

    final int comandaAtual = int.tryParse(comandaAtualStr) ?? 0;
    final int novaComanda = comandaAtual + 1;

    final String novaComandaStr = novaComanda.toString();

    /// 🔥 ATUALIZA NO FIREBASE
    transaction.update(filialRef, {
      'comanda_atual_webapp': novaComandaStr,
    });

    /// Retorna a nova comanda pra usar no pedido
    return novaComandaStr;
  });
}

/*
Future<bool> comandaEstaLivre(String comanda) async {
  var urlBratter = Urls.urlApiBratter;
  final encodedUrl = Uri.encodeComponent(urlBratter);

  final url =
      '${Urls.urlApiAzure}Proxy/ConsultaComanda/'
      '?urlBratter=$encodedUrl'
      '&tokenBratter=${GlobalKeys.tokenBratter}'
      '&idComanda=$comanda';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    final double vlrComanda =
        (data['VlrComanda'] ?? 0).toDouble();
    final String status = data['Status'];

    if (vlrComanda == 0.0 && (status == '00' || status == '01')) {
      return true;
    }
  }

  return false;
}
*/
Future<void> salvarPedidoWebApp({
  required String comanda,
  required CarrinhoModel carrinho,
}) async {
  final firestore = FirebaseFirestore.instance;

  final itens = carrinho.itens.map((item) {
    return {
      'id_produto': item.produto.id,
      'nome': item.produto.desProduto,
      'quantidade': item.quantidade,
      'valor_unitario': item.produto.preco,
      'total': item.quantidade * item.produto.preco!,
      'observacoes': item.produto.obs?.map((obs) => obs.toMap()).toList() ?? [],
    };
  }).toList();

  final total = itens.fold<double>(
    0,
    (sum, item) => sum + (item['total'] as double),
  );

  await firestore.collection('Pedidos_Web_App').add({
    'id_filial': codFilial,
    'des_empresa': '1',
    'dat_registro': FieldValue.serverTimestamp(),
    'comanda': comanda,
    'vlr_json': total,
    'IND_PAGO': 'ABERTO',
    'TIP_OPERACAO': 'WEB_APP',
    'itens': itens,
  });
}
