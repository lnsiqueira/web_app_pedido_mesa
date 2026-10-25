import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/core/model/item_carrinho.dart';
import 'package:webapp_pedido_mesa/screens/item/item_page.dart' show QtyButton;
import 'package:webapp_pedido_mesa/screens/item/sugestoes.dart';
import 'package:webapp_pedido_mesa/services/cardapio_service.dart';

String _reaisPopup(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

/// Escolha da opção de um grupo (ex.: Fatia / Inteira); depois abre o
/// produto normalmente
Future<void> escolherOpcaoGrupo(
  BuildContext context,
  GrupoProdutos grupo,
  List<MapEntry<ItemModel, String>> opcoes, {
  bool sugerir = true,
}) async {
  // selos para marcar as opções veganas/vegetarianas
  final selos = await Complementos.selos();
  if (!context.mounted) return;
  final escolhido = await showModalBottomSheet<ItemModel>(
    context: context,
    isScrollControlled: true,
    constraints:
        BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grupo.nome,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text('Escolha uma opção',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in opcoes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: o.key.preco == null
                              ? null
                              : () => Navigator.pop(ctx, o.key),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(o.value,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ),
                                if ((selos[o.key.id]?.vegano ?? false) ||
                                    (selos[o.key.id]?.vegetariano ?? false))
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(Icons.eco_rounded,
                                        size: 18, color: Color(0xFF2E7D32)),
                                  ),
                                Text(
                                  o.key.preco == null
                                      ? '...'
                                      : 'R\$ ${_reaisPopup(o.key.preco!)}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE8710A)),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded,
                                    color: Color(0xFFE8710A)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  // abre o escolhido e só termina depois (as sugestões esperam para saber se
  // o cliente adicionou e passar para a próxima etapa)
  if (escolhido != null && context.mounted) {
    await abrirProdutoPopup(context, escolhido, sugerir: sugerir);
  }
}

/// Detalhe do produto (quantidade, opções, acréscimos, observação).
/// Com [editando], reabre um item do carrinho já preenchido e salva no lugar
/// dele.
Future<void> abrirProdutoPopup(
  BuildContext context,
  ItemModel produto, {
  ItemCarrinho? editando,
  bool sugerir = true,
}) async {
  // editando item do carrinho: parte das opções originais e marca o que
  // já tinha sido escolhido
  final base = List<ItemObsModel>.from(
      (editando != null ? produto.obsOriginais : null) ?? produto.obs ?? []);
  final anteriores = editando?.produto.obs ?? const <ItemObsModel>[];
  final obs = [
    for (final o in base)
      o.tipo == 'escolha' &&
              anteriores.any((a) =>
                  a.tipo == 'escolha' &&
                  a.titulo == o.titulo &&
                  a.modificador == 'C')
          ? o.copyWith(modificador: 'C')
          : o,
  ];
  final textoAnterior =
      anteriores.where((a) => a.tipo == 'texto').map((a) => a.titulo).join(' ');
  var textoUsado = false;
  final textControllers = <int, TextEditingController>{};
  for (int i = 0; i < obs.length; i++) {
    if (obs[i].tipo != 'texto') continue;
    textControllers[i] =
        TextEditingController(text: textoUsado ? '' : textoAnterior);
    textoUsado = true;
  }
  int quantidade = editando?.quantidade ?? 1;
  final acrescimosFuture = Complementos.doProduto(produto.id);
  final escolhidos = <AcrescimoEscolhido>[...?editando?.produto.acrescimos];
  final mapaSelos = await Complementos.selos();
  final selo = mapaSelos[produto.id];
  final selos = [
    if (selo?.vegano ?? false) 'Vegano',
    if (selo?.vegetariano ?? false) 'Vegetariano',
  ];
  if (!context.mounted) return;
  final carrinhoAtual = Provider.of<CarrinhoModel>(context, listen: false);
  // carrinho novo: volta a oferecer as sugestões
  if (carrinhoAtual.itens.isEmpty) sugestoesOferecidas = false;
  final itensAntes = carrinhoAtual.totalItens;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateSB) {
          final total = ((produto.preco ?? 0) +
                  escolhidos.fold(0.0, (t, a) => t + a.preco)) *
              quantidade;

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) {
              // return Container(
              //   decoration: const BoxDecoration(
              //     color: Colors.white,
              //     borderRadius:
              //         BorderRadius.vertical(top: Radius.circular(24)),
              //   ),
              //   child: Column(
              //     children: [
              //       // Drag handle
              //       Container(
              //         margin: const EdgeInsets.only(top: 12, bottom: 8),
              //         width: 36,
              //         height: 4,
              //         decoration: BoxDecoration(
              //           color: Colors.grey.shade300,
              //           borderRadius: BorderRadius.circular(99),
              //         ),
              //       ),

              //       // Header
              //       Padding(
              //         padding: const EdgeInsets.symmetric(
              //             horizontal: 20, vertical: 12),
              //         child: Row(
              //           children: [
              //             Container(
              //               width: 48,
              //               height: 48,
              //               decoration: BoxDecoration(
              //                 color: Colors.orange.shade50,
              //                 borderRadius: BorderRadius.circular(14),
              //               ),
              //               child: Icon(Icons.fastfood_rounded,
              //                   color: Colors.orange.shade700, size: 24),
              //             ),
              //             const SizedBox(width: 14),
              //             Expanded(
              //               child: Column(
              //                 crossAxisAlignment: CrossAxisAlignment.start,
              //                 children: [
              //                   Text(
              //                     produto.desProduto ?? '',
              //                     style: const TextStyle(
              //                         fontSize: 16,
              //                         fontWeight: FontWeight.w600),
              //                     maxLines: 1,
              //                     overflow: TextOverflow.ellipsis,
              //                   ),
              //                   Text(
              //                     'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
              //                     style: TextStyle(
              //                       fontSize: 14,
              //                       color: Colors.orange.shade800,
              //                       fontWeight: FontWeight.w500,
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //       Divider(height: 1, color: Colors.grey.shade200),

              //       // Scrollable content
              //       Expanded(
              //         child: ListView(
              //           controller: scrollController,
              //           padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              //           children: [
              //             // Quantidade
              //             const Text('Quantidade',
              //                 style: TextStyle(
              //                     fontSize: 11,
              //                     fontWeight: FontWeight.w600,
              //                     letterSpacing: 0.8,
              //                     color: Colors.grey)),
              //             const SizedBox(height: 12),
              //             Row(
              //               children: [
              //                 QtyButton(
              //                   icon: Icons.remove,
              //                   onTap: () => setStateSB(() {
              //                     if (quantidade > 1) quantidade--;
              //                   }),
              //                 ),
              //                 SizedBox(
              //                   width: 40,
              //                   child: Text(
              //                     '$quantidade',
              //                     textAlign: TextAlign.center,
              //                     style: const TextStyle(
              //                         fontSize: 16,
              //                         fontWeight: FontWeight.w600),
              //                   ),
              //                 ),
              //                 QtyButton(
              //                   icon: Icons.add,
              //                   onTap: () => setStateSB(() => quantidade++),
              //                 ),
              //               ],
              //             ),

              //             // Obs de escolha (chips "com")
              //             if (obs.any((o) => o.tipo == 'escolha')) ...[
              //               const SizedBox(height: 24),
              //               const Text('Personalize seu pedido',
              //                   style: TextStyle(
              //                       fontSize: 11,
              //                       fontWeight: FontWeight.w600,
              //                       letterSpacing: 0.8,
              //                       color: Colors.grey)),
              //               const SizedBox(height: 12),
              //               Wrap(
              //                 spacing: 8,
              //                 runSpacing: 8,
              //                 children: obs.mapIndexed((i, o) {
              //                   if (o.tipo != 'escolha')
              //                     return const SizedBox.shrink();
              //                   final selected = o.modificador == 'C';
              //                   return GestureDetector(
              //                     onTap: () => setStateSB(() {
              //                       obs[i] = o.copyWith(
              //                         modificador: selected ? null : 'C',
              //                         clearModificador: selected,
              //                       );
              //                     }),
              //                     child: AnimatedContainer(
              //                       duration:
              //                           const Duration(milliseconds: 150),
              //                       padding: const EdgeInsets.symmetric(
              //                           horizontal: 14, vertical: 9),
              //                       decoration: BoxDecoration(
              //                         color: selected
              //                             ? Colors.orange.shade50
              //                             : Colors.white,
              //                         border: Border.all(
              //                           color: selected
              //                               ? Colors.orange.shade700
              //                               : Colors.grey.shade300,
              //                           width: selected ? 1.5 : 0.8,
              //                         ),
              //                         borderRadius: BorderRadius.circular(99),
              //                       ),
              //                       child: Row(
              //                         mainAxisSize: MainAxisSize.min,
              //                         children: [
              //                           if (selected) ...[
              //                             Container(
              //                               width: 16,
              //                               height: 16,
              //                               decoration: BoxDecoration(
              //                                 color: Colors.orange.shade700,
              //                                 shape: BoxShape.circle,
              //                               ),
              //                               child: const Icon(Icons.check,
              //                                   size: 11,
              //                                   color: Colors.white),
              //                             ),
              //                             const SizedBox(width: 6),
              //                           ],
              //                           Text(
              //                             o.titulo ?? '',
              //                             style: TextStyle(
              //                               fontSize: 14,
              //                               fontWeight: FontWeight.w500,
              //                               color: selected
              //                                   ? Colors.orange.shade800
              //                                   : Colors.black87,
              //                             ),
              //                           ),
              //                         ],
              //                       ),
              //                     ),
              //                   );
              //                 }).toList(),
              //               ),
              //             ],

              //             // Campo de texto livre
              //             const SizedBox(height: 24),
              //             Container(
              //               decoration: BoxDecoration(
              //                 border: Border.all(
              //                     color: Colors.grey.shade300, width: 0.8),
              //                 borderRadius: BorderRadius.circular(14),
              //               ),
              //               padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              //               child: Column(
              //                 crossAxisAlignment: CrossAxisAlignment.start,
              //                 children: [
              //                   Text('Alguma observação?',
              //                       style: TextStyle(
              //                           fontSize: 12,
              //                           color: Colors.grey.shade500)),
              //                   const SizedBox(height: 4),
              //                   ...obs.mapIndexed((i, o) {
              //                     if (o.tipo != 'texto')
              //                       return const SizedBox.shrink();
              //                     return TextField(
              //                       controller: textControllers[i],
              //                       maxLines: 3,
              //                       minLines: 1,
              //                       decoration: const InputDecoration(
              //                         hintText:
              //                             'Ex: sem cebola, bem passado…',
              //                         border: InputBorder.none,
              //                         isDense: true,
              //                       ),
              //                       style: const TextStyle(fontSize: 14),
              //                     );
              //                   }),
              //                 ],
              //               ),
              //             ),
              //             const SizedBox(height: 24),
              //           ],
              //         ),
              //       ),

              //       // Footer
              //       Padding(
              //         padding: EdgeInsets.fromLTRB(20, 12, 20,
              //             MediaQuery.of(context).padding.bottom + 16),
              //         child: Row(
              //           children: [
              //             // Botão cancelar
              //             Expanded(
              //               flex: 1,
              //               child: OutlinedButton(
              //                 onPressed: () => Navigator.pop(context),
              //                 style: OutlinedButton.styleFrom(
              //                   minimumSize: const Size(0, 50),
              //                   side: BorderSide(
              //                       color: Colors.grey.shade300, width: 0.8),
              //                   shape: RoundedRectangleBorder(
              //                       borderRadius: BorderRadius.circular(12)),
              //                 ),
              //                 child: const Text('Cancelar',
              //                     style: TextStyle(
              //                         color: Colors.black54, fontSize: 15)),
              //               ),
              //             ),
              //             const SizedBox(width: 10),
              //             // Botão adicionar
              //             Expanded(
              //               flex: 2,
              //               child: ElevatedButton(
              //                 onPressed: () {
              //                   final List<ItemObsModel> obsFinalizadas = [];
              //                   for (int i = 0; i < obs.length; i++) {
              //                     final o = obs[i];
              //                     if (o.tipo == 'texto') {
              //                       final txt =
              //                           textControllers[i]?.text.trim();
              //                       if (txt != null && txt.isNotEmpty) {
              //                         obsFinalizadas.add(o.copyWith(
              //                             modificador: 'COM',
              //                             pluAdd: 0,
              //                             titulo: txt));
              //                       }
              //                     } else if (o.tipo == 'escolha' &&
              //                         o.modificador == 'C') {
              //                       obsFinalizadas.add(o.copyWith(pluAdd: 0));
              //                     }
              //                   }
              //                   for (int i = 0; i < quantidade; i++) {
              //                     _adicionarAoCarrinho(
              //                         produto.copyWith(obs: obsFinalizadas));
              //                   }
              //                   Navigator.pop(context);
              //                 },
              //                 style: ElevatedButton.styleFrom(
              //                   backgroundColor: Colors.orange.shade800,
              //                   foregroundColor: Colors.white,
              //                   minimumSize: const Size(0, 50),
              //                   elevation: 0,
              //                   shape: RoundedRectangleBorder(
              //                       borderRadius: BorderRadius.circular(12)),
              //                 ),
              //                 child: Row(
              //                   mainAxisAlignment: MainAxisAlignment.center,
              //                   children: [
              //                     const Icon(
              //                       Icons.add,
              //                       size: 18,
              //                       color: Colors.white,
              //                     ),
              //                     const SizedBox(width: 6),
              //                     Text(
              //                       '${editando != null ? 'Salvar' : 'Adicionar'} · R\$ ${total.toStringAsFixed(2)}',
              //                       style: const TextStyle(
              //                           fontSize: 15,
              //                           fontWeight: FontWeight.w600),
              //                     ),
              //                   ],
              //                 ),
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),
              // );
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // HEADER COM IMAGEM
                    Stack(
                      children: [
                        // IMAGEM
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
                                  // child: Icon(
                                  //   Icons.fastfood_rounded,
                                  //   size: 72,
                                  //   color: Colors.orange.shade300,
                                  // ),
                                );
                              },
                            ),
                          ),
                        ),

                        // OVERLAY ESCURO
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

                        // DRAG HANDLE
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

                        // BOTÃO FECHAR
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

                        // TEXOS
                        // Positioned(
                        //   left: 20,
                        //   right: 20,
                        //   bottom: 22,
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       Text(
                        //         produto.desProduto ?? '',
                        //         maxLines: 2,
                        //         overflow: TextOverflow.ellipsis,
                        //         style: const TextStyle(
                        //           color: Colors.white,
                        //           fontSize: 28,
                        //           fontWeight: FontWeight.w800,
                        //           height: 1.05,
                        //           letterSpacing: -0.7,
                        //         ),
                        //       ),
                        //       const SizedBox(height: 12),
                        //       Container(
                        //         padding: const EdgeInsets.symmetric(
                        //           horizontal: 14,
                        //           vertical: 8,
                        //         ),
                        //         decoration: BoxDecoration(
                        //           color: Colors.white.withOpacity(0.14),
                        //           borderRadius: BorderRadius.circular(99),
                        //           border: Border.all(
                        //             color: Colors.white.withOpacity(0.12),
                        //           ),
                        //         ),
                        //         child: Text(
                        //           'R\$ ${produto.preco?.toStringAsFixed(2) ?? '--'}',
                        //           style: const TextStyle(
                        //             color: Colors.white,
                        //             fontSize: 16,
                        //             fontWeight: FontWeight.w700,
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // TEXOS
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

                              // DESCRIÇÃO BONITA
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
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                              ],

                              // PREÇO SÓ QUANDO NÃO TIVER DESCRIÇÃO
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],

                              // selos vegano / vegetariano (Dashboard)
                              if (selos.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final v in selos)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D32),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.eco_rounded,
                                                size: 15, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              v,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // CONTEÚDO
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        children: [
                          // QUANTIDADE
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

                          // Row(
                          //   children: [
                          //     QtyButton(
                          //       icon: Icons.remove,
                          //       onTap: () => setStateSB(() {
                          //         if (quantidade > 1) quantidade--;
                          //       }),
                          //     ),
                          //     SizedBox(
                          //       width: 50,
                          //       child: Text(
                          //         '$quantidade',
                          //         textAlign: TextAlign.center,
                          //         style: const TextStyle(
                          //           fontSize: 18,
                          //           fontWeight: FontWeight.w700,
                          //         ),
                          //       ),
                          //     ),
                          //     QtyButton(
                          //       icon: Icons.add,
                          //       onTap: () => setStateSB(() => quantidade++),
                          //     ),
                          //   ],
                          // ),
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

                              // PREÇO NO FIM DA LINHA QUANDO EXISTIR DESCRIÇÃO
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // PERSONALIZAÇÃO
                          if (obs.any((o) => o.tipo == 'escolha')) ...[
                            const SizedBox(height: 30),
                            const Text(
                              'PERSONALIZE SEU PEDIDO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: obs.mapIndexed((i, o) {
                                if (o.tipo != 'escolha') {
                                  return const SizedBox.shrink();
                                }

                                final selected = o.modificador == 'C';

                                return GestureDetector(
                                  onTap: () => setStateSB(() {
                                    obs[i] = o.copyWith(
                                      modificador: selected ? null : 'C',
                                      clearModificador: selected,
                                    );
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.orange.shade50
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: selected
                                            ? Colors.orange.shade700
                                            : Colors.grey.shade300,
                                        width: selected ? 1.5 : 1,
                                      ),
                                      boxShadow: [
                                        if (selected)
                                          BoxShadow(
                                            color:
                                                Colors.orange.withOpacity(0.12),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (selected) ...[
                                          // Container(
                                          //   width: 18,
                                          //   height: 18,
                                          //   decoration: BoxDecoration(
                                          //     color: Colors.orange.shade700,
                                          //     shape: BoxShape.circle,
                                          //   ),
                                          //   child: const Icon(
                                          //     Icons.check,
                                          //     size: 12,
                                          //     color: Colors.white,
                                          //   ),
                                          // ),
                                          // const SizedBox(width: 8),
                                        ],
                                        Text(
                                          o.titulo ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: selected
                                                ? Colors.orange.shade800
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // OBSERVAÇÃO
                          // ACRÉSCIMOS (Dashboard)
                          FutureBuilder<List<AcrescimoEscolhido>>(
                            future: acrescimosFuture,
                            builder: (context, snap) {
                              final lista = snap.data ?? const [];
                              if (lista.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 30),
                                  const Text(
                                    'ACRÉSCIMOS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  for (final a in lista)
                                    Builder(builder: (context) {
                                      final marcado =
                                          escolhidos.any((e) => e.plu == a.plu);
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Material(
                                          color: marcado
                                              ? const Color(0xFFFFF1E3)
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            side: BorderSide(
                                              color: marcado
                                                  ? Colors.orange.shade700
                                                  : Colors.grey.shade300,
                                              width: marcado ? 1.6 : 1,
                                            ),
                                          ),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            onTap: () => setStateSB(() {
                                              if (marcado) {
                                                escolhidos.removeWhere(
                                                    (e) => e.plu == a.plu);
                                              } else {
                                                escolhidos.add(a);
                                              }
                                            }),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    marcado
                                                        ? Icons
                                                            .check_box_rounded
                                                        : Icons
                                                            .check_box_outline_blank_rounded,
                                                    color: marcado
                                                        ? Colors.orange.shade800
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      a.nome,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '+ R\$ ${_reaisPopup(a.preco)}',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors
                                                          .orange.shade800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                ],
                              );
                            },
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
                                ...obs.mapIndexed((i, o) {
                                  if (o.tipo != 'texto') {
                                    return const SizedBox.shrink();
                                  }

                                  return TextField(
                                    controller: textControllers[i],
                                    maxLines: 3,
                                    minLines: 1,
                                    decoration: const InputDecoration(
                                      hintText: 'Ex: sem cebola, bem passado…',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
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

                    // FOOTER
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
                                final List<ItemObsModel> obsFinalizadas = [];

                                for (int i = 0; i < obs.length; i++) {
                                  final o = obs[i];

                                  if (o.tipo == 'texto') {
                                    final txt = textControllers[i]?.text.trim();

                                    if (txt != null && txt.isNotEmpty) {
                                      obsFinalizadas.add(
                                        o.copyWith(
                                          modificador: 'COM',
                                          pluAdd: 0,
                                          titulo: txt,
                                        ),
                                      );
                                    }
                                  } else if (o.tipo == 'escolha' &&
                                      o.modificador == 'C') {
                                    obsFinalizadas.add(
                                      o.copyWith(pluAdd: 0),
                                    );
                                  }
                                }

                                final novo = produto.copyWith(
                                  obs: obsFinalizadas,
                                  acrescimos: List.of(escolhidos),
                                  obsOriginais: base,
                                );
                                final carrinho = Provider.of<CarrinhoModel>(
                                    context,
                                    listen: false);
                                if (editando != null) {
                                  carrinho.substituir(
                                      editando, novo, quantidade);
                                } else {
                                  for (int i = 0; i < quantidade; i++) {
                                    carrinho.adicionar(novo);
                                  }
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
                                  // const Icon(
                                  //   Icons.add_rounded,
                                  //   size: 18,
                                  //   color: Colors.white,
                                  // ),
                                  // const SizedBox(width: 8),
                                  Text(
                                    '${editando != null ? 'Salvar' : 'Adicionar'} · R\$ ${total.toStringAsFixed(2)}',
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
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );

  if (sugerir &&
      editando == null &&
      context.mounted &&
      carrinhoAtual.totalItens > itensAntes) {
    await oferecerSugestoesAposAdicionar(context, produto);
  }
}
