import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';
import 'package:webapp_pedido_mesa/screens/item/produto_popup.dart'
    show textoFrase;
import 'package:webapp_pedido_mesa/screens/item/sugestoes.dart';
import 'package:webapp_pedido_mesa/services/cardapio_service.dart';

const _laranja = Color(0xFFE8710A);

String _reais(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

/// Pizza meio a meio (grupo "Pizza Meio a Meio" da Dashboard, com os PLUs
/// MEIA): escolhe a 1ª e a 2ª metade. No carrinho/comanda entram as duas
/// MEIAS, cada uma com o seu preço e a observação da outra metade (igual
/// ao cardápio de mesa do tablet).
Future<void> escolherMeioAMeio(
  BuildContext context,
  GrupoProdutos grupo,
  List<MapEntry<ItemModel, String>> opcoes, {
  bool sugerir = true,
  ItemCarrinho? editando,
}) async {
  // só os sabores com preço
  final sabores = opcoes.where((o) => o.key.preco != null).toList();
  MapEntry<ItemModel, String>? primeira, segunda;
  var etapa = 0;
  // editando do carrinho: já vem com os dois sabores escolhidos
  if (editando != null) {
    primeira =
        sabores.where((o) => o.key.plu == editando.produto.plu).firstOrNull;
    segunda = sabores
        .where((o) => o.key.plu == editando.produto.outraMetade?.plu)
        .firstOrNull;
  }

  String nome(MapEntry<ItemModel, String> o) => textoFrase(o.value);

  final confirmou = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    constraints:
        BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSB) {
        Widget metade(int n) {
          final escolhida = n == 0 ? primeira : segunda;
          final ativa = etapa == n;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: n == 1 && primeira == null
                  ? null
                  : () => setSB(() => etapa = n),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ativa ? const Color(0xFFFFF1E3) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: ativa ? _laranja : Colors.transparent, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n == 0 ? '1ª metade' : '2ª metade',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600)),
                    Text(
                      escolhida == null ? 'Escolha o sabor' : nome(escolhida),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: escolhida == null
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final pronto = primeira != null && segunda != null;
        final total = pronto
            ? (primeira!.key.preco ?? 0) + (segunda!.key.preco ?? 0)
            : 0.0;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pizza meio a meio',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    'Escolha os dois sabores. Cada metade sai com o preço dela.',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 14),
                Row(children: [
                  metade(0),
                  const SizedBox(width: 10),
                  metade(1)
                ]),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sabores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final o = sabores[i];
                      // na 2ª metade, o sabor da 1ª não aparece de novo
                      final mesmo = etapa == 1 && primeira == o;
                      final marcado = (etapa == 0 ? primeira : segunda) == o;
                      final imagem = o.key.imageUrl ?? '';
                      return Opacity(
                        opacity: mesmo ? 0.35 : 1,
                        child: Material(
                          color:
                              marcado ? const Color(0xFFFFF1E3) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: marcado
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade300,
                              width: marcado ? 1.6 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: mesmo
                                ? null
                                : () => setSB(() {
                                      if (etapa == 0) {
                                        primeira = o;
                                        if (segunda == o) segunda = null;
                                        etapa = 1;
                                      } else {
                                        segunda = o;
                                      }
                                    }),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: imagem.isNotEmpty
                                          ? Image.network(imagem,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Image.asset(
                                                      'images/default_logo.png',
                                                      fit: BoxFit.cover))
                                          : Image.asset(
                                              'images/default_logo.png',
                                              fit: BoxFit.cover),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(nome(o),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  Text('Metade ${_reais(o.key.preco ?? 0)}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: _laranja)),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: pronto ? () => Navigator.pop(ctx, true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _laranja,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      pronto
                          ? '${editando != null ? 'Salvar' : 'Adicionar'} pizza · ${_reais(total)}'
                          : primeira == null
                              ? 'Escolha a 1ª metade'
                              : 'Agora escolha a 2ª metade',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  final a = primeira, b = segunda;
  if (confirmou != true || a == null || b == null || !context.mounted) return;

  // observação de cada metade (a comanda guarda até 30 letras)
  List<ItemObsModel> obs(MapEntry<ItemModel, String> outra) {
    final t = 'Meia com ${nome(outra)}';
    return [
      ItemObsModel(
        tipo: 'texto',
        titulo: t.length <= 30 ? t : t.substring(0, 30),
        preco: 0,
        pluAdd: 0,
        ordem: 0,
      ),
    ];
  }

  final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
  // um item só no carrinho; na comanda vira as duas MEIAS
  final pizza = a.key.copyWith(
    obs: obs(b),
    acrescimos: const [],
    titulo: 'Pizza meio a meio · ${nome(a)} / ${nome(b)}',
    outraMetade: b.key.copyWith(obs: obs(a), acrescimos: const []),
  );
  if (editando != null) {
    // trocou os sabores: fica na mesma posição, com a mesma quantidade
    carrinho.substituir(editando, pizza, editando.quantidade);
    return;
  }
  carrinho.adicionar(pizza);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Pizza ${nome(a)} / ${nome(b)} adicionada'),
    duration: const Duration(seconds: 2),
  ));
  if (sugerir) await oferecerSugestoesAposAdicionar(context, a.key);
}

/// Reabre a meio a meio do carrinho para trocar os sabores
/// Evita abrir várias telas se tocar de novo enquanto carrega
bool _abrindoEdicao = false;

Future<void> editarMeioAMeio(BuildContext context, ItemCarrinho item) async {
  if (_abrindoEdicao) return;
  _abrindoEdicao = true;
  try {
    await _editarMeioAMeio(context, item);
  } finally {
    _abrindoEdicao = false;
  }
}

Future<void> _editarMeioAMeio(BuildContext context, ItemCarrinho item) async {
  final grupos = await GrupoProdutos.todos();
  final grupo = grupos
      .where(
          (g) => g.meioAMeio && g.opcoes.any((o) => o.key == item.produto.id))
      .firstOrNull;
  final idCategoria = item.produto.idCategoriaFilial;
  if (grupo == null || idCategoria == null) return;
  final produtos = await CardapioService.produtosDe(idCategoria);
  final opcoes = <MapEntry<ItemModel, String>>[];
  for (final o in grupo.opcoes) {
    final p = produtos.where((x) => x.id == o.key).firstOrNull;
    if (p == null) continue;
    opcoes.add(MapEntry(await Complementos.completar(p),
        o.value.isEmpty ? (p.desProduto ?? '').trim() : o.value));
  }
  if (!context.mounted) return;
  await escolherMeioAMeio(context, grupo, opcoes,
      sugerir: false, editando: item);
}
