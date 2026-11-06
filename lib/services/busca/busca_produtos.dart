// Busca de produtos "inteligente" sem IA: entende o cliente escrevendo do
// jeito dele ("quero um pao com menteiga") e acha o produto como está
// cadastrado ("PAO NA CHAPA C/ MANT").
//
// - ignora palavras que não dizem o produto (quero, um, com, por favor…)
// - entende abreviações do cadastro e sinônimos (mant = manteiga, refri…)
// - tolera erro de digitação (menteiga, qeijo)
// - em vez de "tudo ou nada", dá pontos a cada produto e ordena do melhor
//   para o pior

/// Minúsculas e sem acento ("Pão" -> "pao")
String normalizar(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = de.indexOf(ch);
    b.write(i >= 0 ? para[i] : ch);
  }
  return b.toString();
}

/// Palavras do pedido que não ajudam a achar o produto
const _ignoradas = {
  'quero', 'queria', 'gostaria', 'desejo', 'vou', 'querer', 'eu', 'me', 'pra',
  'pro', 'para', 'por', 'favor', 'pf', 'pfv', 'pfvr', 've', 'traz', 'traga',
  'manda', 'mande', 'pode', 'poderia', 'tem', 'voce', 'voces', 'vc',
  'vcs', 'ai', 'aqui', 'mais', 'de', 'da', 'do', 'das', 'dos', 'com', 'e', 'o',
  'a', 'os', 'as', 'um', 'uma', 'uns', 'umas', 'no', 'na', 'nos', 'nas', 'em',
  'dois', 'duas', 'tres', 'quatro', 'cinco', 'seis', 'oi', 'ola', 'bom', 'dia',
  'boa', 'tarde', 'noite', 'obrigado', 'obrigada', 'so', 'tambem', //
};

/// Sinônimos e abreviações comuns no cadastro (já normalizados). Cada grupo
/// vale nos dois sentidos: quem busca "manteiga" acha "mant" e vice-versa.
const _grupos = [
  ['manteiga', 'mant', 'mantg', 'mtg'],
  ['frances', 'franc', 'fr'],
  ['pao', 'paes', 'paozinho'],
  ['queijo', 'qj', 'qjo', 'queij'],
  ['requeijao', 'req', 'requeij', 'catupiry'],
  ['presunto', 'pres', 'presun'],
  ['refrigerante', 'refri', 'refris'],
  ['chocolate', 'choc', 'chocol'],
  ['integral', 'integ', 'int'],
  ['cafe', 'cafes', 'caf', 'cafezinho'],
  ['leite'],
  ['expresso', 'espresso'],
  ['cappuccino', 'capuccino', 'capucino', 'cappucino', 'capu'],
  ['sanduiche', 'sanduiches', 'sand', 'lanche', 'lanches'],
  ['laranja', 'lar', 'lj'],
  ['grande', 'gde', 'gd'],
  ['pequeno', 'pequena', 'peq', 'pq'],
  ['medio', 'media', 'med', 'md'],
  ['coca', 'cocacola'],
  ['agua', 'aguas'],
  ['suco', 'sucos'],
  ['bolo', 'bolos'],
  ['salgado', 'salgados', 'salg'],
  ['natural', 'nat'],
  ['tradicional', 'trad'],
  ['especial', 'esp'],
  ['vegano', 'vegana', 'veg'],
  ['acucar', 'acuc', 'acu'],
];

final Map<String, Set<String>> _sinonimos = () {
  final m = <String, Set<String>>{};
  for (final g in _grupos) {
    for (final p in g) {
      (m[p] ??= {}).addAll(g);
    }
  }
  return m;
}();

/// Palavras de um texto, já normalizadas ("C/" vira "com", "S/" vira "sem")
List<String> palavrasDe(String texto) => normalizar(texto)
    .replaceAllMapped(RegExp(r'(^|[^a-z0-9])([cs])/'),
        (m) => '${m[1]} ${m[2] == 'c' ? 'com' : 'sem'} ')
    .split(RegExp(r'[^a-z0-9]+'))
    .where((p) => p.isNotEmpty)
    .toList();

/// Quantas letras erradas aceitar numa palavra digitada
int _tolerancia(String p) => p.length <= 3
    ? 0
    : p.length <= 6
        ? 1
        : 2;

/// Distância de edição (com troca de letras vizinhas), parando cedo quando
/// passa do [limite]
int _distancia(String a, String b, int limite) {
  if ((a.length - b.length).abs() > limite) return limite + 1;
  var anterior2 = <int>[];
  var anterior = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final atual = List<int>.filled(b.length + 1, 0);
    atual[0] = i;
    var menor = atual[0];
    for (var j = 1; j <= b.length; j++) {
      final custo = a[i - 1] == b[j - 1] ? 0 : 1;
      var v = [
        anterior[j] + 1,
        atual[j - 1] + 1,
        anterior[j - 1] + custo,
      ].reduce((x, y) => x < y ? x : y);
      if (i > 1 &&
          j > 1 &&
          a[i - 1] == b[j - 2] &&
          a[i - 2] == b[j - 1] &&
          anterior2[j - 2] + 1 < v) {
        v = anterior2[j - 2] + 1;
      }
      atual[j] = v;
      if (v < menor) menor = v;
    }
    if (menor > limite) return limite + 1;
    anterior2 = anterior;
    anterior = atual;
  }
  return anterior[b.length];
}

/// Pontos de uma palavra buscada contra uma palavra do nome do produto.
/// [ultima]: a última palavra digitada, que pode estar pela metade.
double _pontosPalavra(String q, String w, {required bool ultima}) {
  if (q == w) return 3;
  // o cliente ainda está digitando ("pao de quei")
  if ((ultima || q.length >= 3) && w.startsWith(q)) return 2.5;
  // abreviação no cadastro ("manteiga" x "mant")
  if (w.length >= 3 && q.startsWith(w)) return 2.5;
  final tol = _tolerancia(q);
  if (tol == 0) return 0;
  if (_distancia(q, w, tol) <= tol) return 1.5;
  // erro de digitação numa palavra pela metade ("menteig" x "manteiga")
  if (ultima && w.length > q.length && q.length >= 4) {
    if (_distancia(q, w.substring(0, q.length), tol) <= tol) return 1.5;
  }
  return 0;
}

/// Melhor pontuação de uma palavra buscada (ou dos sinônimos dela) no nome
double _melhor(String q, List<String> nome, {required bool ultima}) {
  // plural falado ("expressos", "sucos"): vale o singular
  if (q.length > 4 && q.endsWith('s') && !_sinonimos.containsKey(q)) {
    final singular = _melhor(q.substring(0, q.length - 1), nome, ultima: false);
    if (singular >= 2.5) return singular;
  }
  var melhor = 0.0;
  for (final w in nome) {
    melhor = _max(melhor, _pontosPalavra(q, w, ultima: ultima));
    if (melhor == 3) return 3;
  }
  // sinônimo / abreviação conhecida vale como palavra certa
  final sin = _sinonimos[q];
  if (sin != null && melhor < 2.5) {
    for (final s in sin) {
      if (s != q && nome.contains(s)) return 2.5;
    }
  }
  // erro de digitação + abreviação ("menteiga" -> manteiga -> "mant")
  if (sin == null && melhor < 2) {
    final parecida = _sinonimoParecido(q);
    if (parecida != null && parecida.any(nome.contains)) return 2;
  }
  return melhor;
}

/// Sinônimos da palavra conhecida mais parecida com [q] (com erro de
/// digitação), ou null
Set<String>? _sinonimoParecido(String q) {
  final tol = _tolerancia(q);
  if (tol == 0) return null;
  for (final e in _sinonimos.entries) {
    if (e.key.length >= 4 && _distancia(q, e.key, tol) <= tol) return e.value;
  }
  return null;
}

double _max(double a, double b) => a > b ? a : b;

/// Produtos que combinam com [consulta], do mais parecido para o menos
/// (empate: nome mais curto e depois a ordem do cardápio), com os pontos
List<({T item, double pontos})> _ranquear<T>(
    String consulta, Iterable<T> itens, String Function(T) nome) {
  final todas = palavrasDe(consulta);
  if (todas.isEmpty) return [];
  var palavras = [
    for (final p in todas)
      if (!_ignoradas.contains(p) && !RegExp(r'^\d+$').hasMatch(p)) p
  ];
  // números ("2 cafés", "agua 500") só dão pontos extras se estiverem no nome
  final numeros = [
    for (final p in todas)
      if (RegExp(r'^\d+$').hasMatch(p)) p
  ];
  // só palavras "vazias" (ex.: digitou "do"): busca por elas mesmo
  if (palavras.isEmpty && numeros.isEmpty) palavras = todas;
  if (palavras.isEmpty) palavras = numeros;
  final ultimaDigitada = todas.last;

  final achados = <({T item, double pontos, int tamanho, int ordem})>[];
  var ordem = 0;
  for (final item in itens) {
    final doNome = palavrasDe(nome(item));
    var pontos = 0.0;
    for (final q in palavras) {
      pontos += _melhor(q, doNome, ultima: q == ultimaDigitada);
    }
    if (pontos > 0) {
      for (final n in numeros) {
        if (doNome.any((w) => w == n || w.startsWith(n))) pontos += 0.5;
      }
      achados.add(
          (item: item, pontos: pontos, tamanho: doNome.length, ordem: ordem));
    }
    ordem++;
  }
  if (achados.isEmpty) return [];

  // mostra só os que chegam perto do melhor: se achou "pão de queijo", não
  // enche a lista com todos os pães
  final melhor = achados.map((a) => a.pontos).reduce(_max);
  final bons = achados.where((a) => a.pontos > melhor * 0.5).toList()
    ..sort((a, b) {
      final c = b.pontos.compareTo(a.pontos);
      if (c != 0) return c;
      final t = a.tamanho.compareTo(b.tamanho);
      return t != 0 ? t : a.ordem.compareTo(b.ordem);
    });
  return [for (final a in bons) (item: a.item, pontos: a.pontos)];
}

/// Busca [consulta] em [itens] pelo [nome] de cada um e devolve os que
/// combinam, do mais parecido para o menos.
List<T> buscarProdutos<T>(
        String consulta, Iterable<T> itens, String Function(T) nome) =>
    [for (final a in _ranquear(consulta, itens, nome)) a.item];

// ---------------------------------------------------------------------------
// Pedido falado: "quero um pão com manteiga e dois cafés" vira duas linhas
// (1× pão com manteiga, 2× café), cada uma com os produtos mais parecidos.

/// Uma parte do pedido: o que o cliente pediu, quantas e as opções do
/// cardápio (a primeira é a mais provável; vazia = não achou)
class LinhaPedido<T> {
  const LinhaPedido(this.texto, this.quantidade, this.opcoes,
      {this.ambigua = false});

  final String texto;
  final int quantidade;
  final List<T> opcoes;

  /// O cliente foi genérico ("um café") e há mais de um produto que serve
  /// (expresso, com leite, latte…): ele escolhe em vez de ir o primeiro
  final bool ambigua;
}

/// Palavras do nome que o pedido não disse ("CAFE EXPRESSO" para "um café"
/// sobra "expresso"); zero = o pedido descreve o produto inteiro
int _palavrasNaoDitas(String consulta, String nome) {
  final ditas = [
    for (final p in palavrasDe(consulta))
      if (!_ignoradas.contains(p)) p
  ];
  return palavrasDe(nome)
      .where((w) => !_ignoradas.contains(w) && !RegExp(r'^\d').hasMatch(w))
      .where((w) => !ditas.any((q) => _melhor(q, [w], ultima: false) > 0))
      .length;
}

/// Mais de um produto serve e o pedido não diz qual: o melhor não foi
/// descrito por inteiro e o segundo está quase empatado com ele
bool _ambigua<T>(String consulta, List<({T item, double pontos})> r,
    String Function(T) nome) {
  if (r.length < 2) return false;
  if (_palavrasNaoDitas(consulta, nome(r.first.item)) == 0) return false;
  return r[1].pontos >= r.first.pontos * 0.85;
}

const _numerosFalados = {
  'um': 1, 'uma': 1, 'dois': 2, 'duas': 2, 'tres': 3, 'quatro': 4,
  'cinco': 5, 'seis': 6, 'sete': 7, 'oito': 8, 'nove': 9, 'dez': 10, //
};

/// Quantidade no começo da parte ("dois cafes", "2 pao", "3x suco") e o
/// resto do texto
(int, String) _quantidade(String parte) {
  final palavras = parte.split(' ').where((p) => p.isNotEmpty).toList();
  for (var i = 0; i < palavras.length; i++) {
    final p = palavras[i];
    final n = _numerosFalados[p] ??
        int.tryParse(RegExp(r'^(\d{1,2})x?$').firstMatch(p)?.group(1) ?? '');
    if (n != null && n > 0 && n <= 20) {
      return (
        n,
        [...palavras.sublist(0, i), ...palavras.sublist(i + 1)].join(' ')
      );
    }
    // a quantidade vem antes do produto: parou de procurar ao achar palavra
    // que não é "vazia" ("quero", "me ve"...)
    if (!_ignoradas.contains(p)) break;
  }
  return (1, parte);
}

/// Separa a frase em itens (vírgula, "e", "mais", "também") com a quantidade
/// de cada um e os produtos que combinam. Junta de volta partes que são um
/// produto só ("misto de queijo e presunto").
List<LinhaPedido<T>> interpretarPedido<T>(
    String frase, Iterable<T> itens, String Function(T) nome,
    {int maxOpcoes = 6}) {
  final lista = itens.toList();
  final partes = normalizar(frase)
      .split(RegExp(r'\s*(?:[,;.!?]|\be\b|\bmais\b|\btambem\b|\bjunto\b)\s*'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .map(_quantidade)
      .where((q) => palavrasDe(q.$2).any((p) => !_ignoradas.contains(p)))
      .toList();

  final linhas = <(int, String, List<({T item, double pontos})>)>[];
  for (final (qtd, texto) in partes) {
    final r = _ranquear(texto, lista, nome);
    if (linhas.isNotEmpty && qtd == 1) {
      // "queijo e presunto": se juntando com a parte anterior o mesmo
      // produto fica ainda mais parecido, é um item só
      final (qtdAnt, textoAnt, rAnt) = linhas.last;
      if (rAnt.isNotEmpty) {
        final junto = _ranquear('$textoAnt $texto', lista, nome);
        if (junto.isNotEmpty &&
            identical(junto.first.item, rAnt.first.item) &&
            junto.first.pontos > rAnt.first.pontos &&
            (r.isEmpty ||
                identical(r.first.item, junto.first.item) ||
                junto.first.pontos >=
                    rAnt.first.pontos + r.first.pontos * 0.75)) {
          linhas.last = (qtdAnt, '$textoAnt e $texto', junto);
          continue;
        }
      }
    }
    linhas.add((qtd, texto, r));
  }
  return [
    for (final (qtd, texto, r) in linhas)
      LinhaPedido(texto, qtd, [for (final a in r.take(maxOpcoes)) a.item],
          ambigua: _ambigua(texto, r, nome)),
  ];
}
