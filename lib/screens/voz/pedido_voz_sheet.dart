import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/item.dart';
import 'package:webapp_pedido_mesa/screens/item/produto_popup.dart';
import 'package:webapp_pedido_mesa/screens/item/sugestoes.dart';
import 'package:webapp_pedido_mesa/services/busca/busca_produtos.dart';
import 'package:webapp_pedido_mesa/services/cardapio_service.dart';
import 'package:webapp_pedido_mesa/services/voz/reconhecimento_voz.dart';

// Pedido falado: o cliente toca no microfone e fala ("um pão na chapa e dois
// cafés"); o painel mostra o que entendeu, item por item, com quantidade e
// outras opções, e "Adicionar tudo" põe no carrinho de uma vez. Depois
// oferece o que combina (sugestões da Dashboard). Sem IA: busca do cardápio.

const _laranja = Color(0xFFE8710A);
const _laranjaClaro = Color(0xFFFFF1E3);

String _reais(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

/// O microfone existe neste navegador? (Firefox não tem)
bool get pedidoPorVozDisponivel => ReconhecimentoVoz().disponivel;

/// Abre o painel de voz e, ao confirmar, adiciona os itens ao carrinho
Future<void> abrirPedidoPorVoz(BuildContext context) async {
  final escolhidos = await showModalBottomSheet<List<_Linha>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _PedidoVozSheet(),
  );
  if (escolhidos == null || escolhidos.isEmpty || !context.mounted) return;

  final carrinho = Provider.of<CarrinhoModel>(context, listen: false);
  if (carrinho.itens.isEmpty) sugestoesOferecidas = false;
  final antes = carrinho.totalItens;
  // produtos com opções (ex.: ponto, sabor) abrem o detalhe para escolher
  final comOpcoes = <_Linha>[];
  for (final l in escolhidos) {
    final p = l.produto!;
    if ((p.obs ?? const []).any((o) => o.tipo == 'escolha')) {
      comOpcoes.add(l);
      continue;
    }
    final novo = p.copyWith(obs: const [], obsOriginais: p.obs ?? const []);
    for (var i = 0; i < l.quantidade; i++) {
      carrinho.adicionar(novo);
    }
  }
  for (final l in comOpcoes) {
    if (!context.mounted) return;
    await abrirProdutoPopup(context, l.produto!,
        sugerir: false, quantidadeInicial: l.quantidade);
  }
  if (!context.mounted) return;
  final adicionados = carrinho.totalItens - antes;
  if (adicionados <= 0) return;
  vibrar(40);
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(adicionados == 1
          ? '1 item no carrinho'
          : '$adicionados itens no carrinho'),
    ));
  await oferecerSugestoesAposVoz(context);
}

/// Uma linha do que foi entendido, com a opção escolhida
class _Linha {
  _Linha(this.texto, this.quantidade, this.opcoes, {bool ambigua = false})
      : escolhida = ambigua && opcoes.length > 1 ? -1 : 0;

  final String texto;
  int quantidade;
  final List<ItemModel> opcoes;

  /// Opção escolhida; -1 = pedido genérico ("um café"), o cliente escolhe
  int escolhida;

  bool get pendente => escolhida < 0 && opcoes.isNotEmpty;
  ItemModel? get produto =>
      opcoes.isEmpty || escolhida < 0 ? null : opcoes[escolhida];
  double get total => (produto?.preco ?? 0) * quantidade;
}

enum _Fase { ouvindo, pensando, resultado }

class _PedidoVozSheet extends StatefulWidget {
  const _PedidoVozSheet();

  @override
  State<_PedidoVozSheet> createState() => _PedidoVozSheetState();
}

class _PedidoVozSheetState extends State<_PedidoVozSheet>
    with SingleTickerProviderStateMixin {
  final _voz = ReconhecimentoVoz();
  late final _pulso = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  /// Cardápio que está aparecendo (sem repetidos), carregado uma vez
  late final Future<List<ItemModel>> _cardapio = () async {
    final listas = await Future.wait(
        CardapioService.ultimas.map((c) => CardapioService.produtosDe(c.id)));
    final vistos = <String>{};
    return [
      for (final p in listas.expand((l) => l))
        if (vistos.add(p.plu ?? '')) p,
    ];
  }();

  var _fase = _Fase.ouvindo;
  var _texto = '';
  String? _erro;
  var _linhas = <_Linha>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ouvir());
  }

  @override
  void dispose() {
    _voz.parar();
    _pulso.dispose();
    super.dispose();
  }

  static String _idioma(String codigo) => switch (codigo) {
        'en' => 'en-US',
        'es' => 'es-ES',
        _ => 'pt-BR',
      };

  void _ouvir() {
    if (!mounted) return;
    setState(() {
      _fase = _Fase.ouvindo;
      _texto = '';
      _erro = null;
    });
    vibrar(30);
    _voz.iniciar(
      idioma: _idioma(Localizations.localeOf(context).languageCode),
      onTexto: (texto, fim) {
        if (mounted) setState(() => _texto = texto);
      },
      onFim: () {
        if (!mounted || _fase != _Fase.ouvindo) return;
        if (_texto.isEmpty) {
          setState(() => _erro ??= 'Não ouvi nada. Toque e fale de novo');
          return;
        }
        _entender();
      },
      onErro: (erro) {
        if (!mounted || erro == 'aborted') return;
        setState(() => _erro = switch (erro) {
              'not-allowed' ||
              'service-not-allowed' =>
                'Libere o microfone no navegador para pedir falando',
              'no-speech' => 'Não ouvi nada. Toque e fale de novo',
              'network' => 'Sem internet para entender a fala',
              _ => 'Não consegui ouvir agora. Tente de novo',
            });
      },
    );
  }

  Future<void> _entender() async {
    vibrar(30);
    setState(() => _fase = _Fase.pensando);
    try {
      final cardapio = await _cardapio;
      final pedido = interpretarPedido(
          _texto, cardapio, (ItemModel p) => p.desProduto ?? '');
      // preço da Bratter só das opções que vão aparecer
      final linhas = await Future.wait(pedido.map((l) async {
        final completos =
            await Future.wait(l.opcoes.map(Complementos.completar));
        return _Linha(l.texto, l.quantidade,
            completos.where((p) => p.preco != null).toList(),
            ambigua: l.ambigua);
      }));
      if (!mounted) return;
      setState(() {
        _linhas = linhas;
        _fase = _Fase.resultado;
      });
    } catch (e) {
      debugPrint('Pedido por voz: $e');
      if (!mounted) return;
      setState(() {
        _fase = _Fase.ouvindo;
        _erro = 'Não consegui carregar o cardápio. Tente de novo';
      });
    }
  }

  List<_Linha> get _validas => _linhas.where((l) => l.produto != null).toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (_fase == _Fase.resultado)
                  Flexible(child: _resultado())
                else
                  _ouvindoView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- ouvindo

  Widget _ouvindoView() {
    final ouvindo = _fase == _Fase.ouvindo && _erro == null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (_fase == _Fase.pensando) return;
            ouvindo ? _voz.parar() : _ouvir();
          },
          child: AnimatedBuilder(
            animation: _pulso,
            builder: (_, child) {
              final t = ouvindo ? _pulso.value : 0.0;
              return Container(
                width: 96 + 24 * t,
                height: 96 + 24 * t,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (ouvindo ? Colors.red : _laranja)
                      .withValues(alpha: 0.12 + 0.08 * (1 - t)),
                ),
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ouvindo ? Colors.red : _laranja,
              ),
              child: _fase == _Fase.pensando
                  ? const Padding(
                      padding: EdgeInsets.all(26),
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white),
                    )
                  : Icon(ouvindo ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white, size: 38),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _texto.isNotEmpty
              ? '“$_texto”'
              : (_erro ?? 'Pode falar o seu pedido'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _texto.isNotEmpty ? 20 : 17,
            fontWeight: FontWeight.w700,
            color: _erro != null && _texto.isEmpty
                ? Colors.red.shade700
                : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          switch (_fase) {
            _Fase.pensando => 'Procurando no cardápio…',
            _ when _erro != null => 'Toque no microfone para tentar de novo',
            _ => 'Ex.: “um pão na chapa e dois cafés com leite”',
          },
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // -------------------------------------------------------------- resultado

  Widget _resultado() {
    final validas = _validas;
    final pendentes = _linhas.where((l) => l.pendente).length;
    final total = validas.fold(0.0, (t, l) => t + l.total);
    final itens = validas.fold(0, (t, l) => t + l.quantidade);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    validas.isEmpty && pendentes == 0
                        ? 'Não encontrei no cardápio'
                        : 'Entendi',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  Text('“$_texto”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Falar de novo',
              onPressed: _ouvir,
              style: IconButton.styleFrom(backgroundColor: _laranjaClaro),
              icon: const Icon(Icons.mic_rounded, color: _laranja),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _linhas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _linha(_linhas[i]),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // falta escolher (ex.: qual café): só depois adiciona
            onPressed: pendentes > 0
                ? null
                : validas.isEmpty
                    ? _ouvir
                    : () => Navigator.pop(context, validas),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              pendentes > 0
                  ? (pendentes == 1
                      ? 'Escolha a opção acima'
                      : 'Escolha as $pendentes opções acima')
                  : validas.isEmpty
                      ? 'Falar de novo'
                      : '${itens == 1 ? 'Adicionar' : 'Adicionar tudo'} · ${_reais(total)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  /// Pedido genérico ("um café"): mostra os produtos que servem para o
  /// cliente tocar no que quer
  Widget _escolha(_Linha l) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
      decoration: BoxDecoration(
        color: _laranjaClaro.withValues(alpha: 0.5),
        border: Border.all(color: _laranja.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: _laranja, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.quantidade > 1
                      ? 'Qual você prefere? (${l.quantidade}×)'
                      : 'Qual você prefere?',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Remover',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _linhas.remove(l)),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 8),
              itemCount: l.opcoes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _opcao(l, i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcao(_Linha l, int i) {
    final p = l.opcoes[i];
    final imagem = p.imageUrl ?? '';
    return GestureDetector(
      onTap: () {
        vibrar(20);
        setState(() => l.escolhida = i);
      },
      child: Container(
        width: 116,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: imagem.isNotEmpty
                    ? Image.network(imagem,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                            'images/default_logo.png',
                            fit: BoxFit.cover))
                    : Image.asset('images/default_logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                textoFrase(p.desProduto ?? ''),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.15),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(_reais(p.preco ?? 0),
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _laranja)),
                ),
                const Icon(Icons.add_circle_rounded, color: _laranja, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(_Linha l) {
    if (l.pendente) return _escolha(l);
    final p = l.produto;
    if (p == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.search_off_rounded, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Não encontrei “${l.texto}”',
                  style: TextStyle(color: Colors.grey.shade700)),
            ),
            IconButton(
              tooltip: 'Remover',
              onPressed: () => setState(() => _linhas.remove(l)),
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
      );
    }
    final temOpcoes = (p.obs ?? const []).any((o) => o.tipo == 'escolha');
    final imagem = p.imageUrl ?? '';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: imagem.isNotEmpty
                      ? Image.network(imagem,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                              'images/default_logo.png',
                              fit: BoxFit.cover))
                      : Image.asset('images/default_logo.png',
                          fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(textoFrase(p.desProduto ?? ''),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                        text: _reais(l.total),
                        style: const TextStyle(
                            color: _laranja, fontWeight: FontWeight.w800),
                      ),
                      if (temOpcoes)
                        TextSpan(
                          text: '  · escolher opções',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ])),
                  ],
                ),
              ),
              _quantidade(l),
            ],
          ),
          if (l.opcoes.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < l.opcoes.length; i++)
                    if (i != l.escolhida)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: _laranjaClaro,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          label: Text(
                            textoFrase(l.opcoes[i].desProduto ?? ''),
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF8A4300)),
                          ),
                          onPressed: () => setState(() => l.escolhida = i),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quantidade(_Linha l) {
    Widget botao(IconData icone, VoidCallback onTap) => InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
                color: _laranjaClaro, shape: BoxShape.circle),
            child: Icon(icone, size: 18, color: _laranja),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        botao(l.quantidade == 1 ? Icons.delete_outline_rounded : Icons.remove,
            () {
          setState(() {
            if (l.quantidade == 1) {
              _linhas.remove(l);
            } else {
              l.quantidade--;
            }
          });
        }),
        SizedBox(
          width: 28,
          child: Text('${l.quantidade}',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        botao(Icons.add, () => setState(() => l.quantidade++)),
      ],
    );
  }
}
