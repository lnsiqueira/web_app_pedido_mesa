import 'package:flutter/material.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/screens/item/item_page.dart';

class ProdutoPopup {
  static void show(
    BuildContext context, {
    required ItemModel produto,
    required Function(ItemModel) onAdd,
  }) {
    final obs = List<ItemObsModel>.from(produto.obs ?? []);

    final textControllers = {
      for (int i = 0; i < obs.length; i++)
        if (obs[i].tipo == 'texto') i: TextEditingController()
    };

    int quantidade = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final total = (produto.preco ?? 0) * quantidade;

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F7F7),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      /// HEADER (IDÊNTICO)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: Image.network(
                                produto.imageUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: Colors.orange.shade100,
                                    child: Image.asset(
                                      'images/default_logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.08),
                                    Colors.black.withOpacity(0.20),
                                    Colors.black.withOpacity(0.85),
                                  ],
                                  stops: const [0.0, 0.45, 1],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 42,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Material(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => Navigator.pop(context),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 22,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produto.desProduto ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.05,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                                if ((produto.descricaoProduto ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    produto.descricaoProduto!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.82),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                if ((produto.descricaoProduto ?? '')
                                    .trim()
                                    .isEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Text(
                                      'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      /// CONTEÚDO
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          children: [
                            const Text(
                              'Quantidade',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                QtyButton(
                                  icon: Icons.remove,
                                  onTap: () => setStateSB(() {
                                    if (quantidade > 1) quantidade--;
                                  }),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    '$quantidade',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                QtyButton(
                                  icon: Icons.add,
                                  onTap: () => setStateSB(() => quantidade++),
                                ),
                                if ((produto.descricaoProduto ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.orange.shade100,
                                      ),
                                    ),
                                    child: Text(
                                      'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 30),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alguma observação?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...obs.map((o) {
                                    if (o.tipo != 'texto') {
                                      return const SizedBox.shrink();
                                    }

                                    final i = obs.indexOf(o);

                                    return TextField(
                                      controller: textControllers[i],
                                      maxLines: 3,
                                      minLines: 1,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Ex: sem cebola, bem passado…',
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      /// FOOTER
                      Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            12,
                            20,
                            MediaQuery.of(context).padding.bottom + 16,
                          ),
                          child: Row(
                            children: [
                              // CANCELAR
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 54),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // ADICIONAR
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final List<ItemObsModel> obsFinalizadas =
                                        [];

                                    for (int i = 0; i < obs.length; i++) {
                                      final o = obs[i];

                                      if (o.tipo == 'texto') {
                                        final txt =
                                            textControllers[i]?.text.trim();

                                        if (txt != null && txt.isNotEmpty) {
                                          obsFinalizadas.add(
                                            o.copyWith(
                                              modificador: 'COM',
                                              titulo: txt,
                                            ),
                                          );
                                        }
                                      } else if (o.tipo == 'escolha' &&
                                          o.modificador == 'C') {
                                        obsFinalizadas.add(o);
                                      }
                                    }

                                    for (int i = 0; i < quantidade; i++) {
                                      onAdd(
                                        produto.copyWith(
                                          obs: obsFinalizadas,
                                        ),
                                      );
                                    }

                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade800,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 54),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Adicionar · R\$ ${total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
