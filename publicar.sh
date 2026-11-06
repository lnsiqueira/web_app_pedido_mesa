#!/usr/bin/env bash
# Publica o site do QR code com atualização automática por versão:
#  - grava a versão no app e em build/web/versao.json: o número do
#    pubspec.yaml (ex.: 1.0.0, o que aparece no rodapé) + data e hora; o app
#    confere esse arquivo e recarrega sozinho quando sai versão nova;
#  - depois de publicar, sobe o número no pubspec.yaml (1.0.0 -> 1.0.1);
#  - dá ao programa um nome único por versão (main.<hash>.dart.js), para o
#    navegador nunca reaproveitar um arquivo velho;
#  - publica sem o cache offline do Flutter e troca o service worker antigo
#    por um que se desliga e apaga a cópia guardada nos celulares.
#
# Uso: ./publicar.sh            (gera e publica)
#      ./publicar.sh --so-build (só gera, para conferir antes)
set -euo pipefail
cd "$(dirname "$0")"

# número da versão: "version: 1.0.0+1" do pubspec.yaml
NUMERO="$(sed -n 's/^version: *\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' pubspec.yaml)"
if [ -z "$NUMERO" ]; then
  echo "ERRO: não achei o version: do pubspec.yaml"
  exit 1
fi
# a data e hora diferenciam duas publicações com o mesmo número
VERSAO="$NUMERO - $(date '+%d/%m/%Y %H:%M')"
WEB=build/web

echo "== Versão $VERSAO"
flutter build web --release --pwa-strategy=none \
  --dart-define=APP_VERSAO="$VERSAO"

# nome único do programa (apaga os de builds anteriores)
find "$WEB" -maxdepth 1 -name 'main.*.dart.js' -delete
HASH="$(sha1sum "$WEB/main.dart.js" | cut -c1-10)"
mv "$WEB/main.dart.js" "$WEB/main.$HASH.dart.js"
sed -i "s/\"mainJsPath\":\"main.dart.js\"/\"mainJsPath\":\"main.$HASH.dart.js\"/" \
  "$WEB/flutter_bootstrap.js"
if ! grep -q "main.$HASH.dart.js" "$WEB/flutter_bootstrap.js"; then
  echo "ERRO: não consegui trocar o nome do main.dart.js no flutter_bootstrap.js"
  exit 1
fi

# não registra service worker (o Flutter registra mesmo com
# --pwa-strategy=none): carrega o app direto da rede
perl -0pi -e 's/_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]*\}\s*\}\);/_flutter.loader.load();/' \
  "$WEB/flutter_bootstrap.js"
if ! grep -q "_flutter.loader.load();" "$WEB/flutter_bootstrap.js"; then
  echo "ERRO: o flutter_bootstrap.js ainda registra o service worker"
  exit 1
fi

# versão publicada (lida pelo app a cada 3 minutos)
printf '{"versao": "%s"}\n' "$VERSAO" > "$WEB/versao.json"

# service worker que apaga o cache offline antigo e se desliga
cp tool/service_worker_limpeza.js "$WEB/flutter_service_worker.js"

if [ "${1:-}" = "--so-build" ]; then
  echo "== Só build (não publicado): versão $VERSAO (main.$HASH.dart.js)"
  exit 0
fi

firebase deploy --only hosting --project foodautomation-1a2f8
echo "== Publicado: versão $VERSAO (main.$HASH.dart.js)"

# próxima versão: sobe o último número e o build (1.0.0+1 -> 1.0.1+2)
perl -pi -e 's/^version: *(\d+)\.(\d+)\.(\d+)\+(\d+)/"version: $1.$2.".($3+1)."+".($4+1)/e' pubspec.yaml
echo "== Próxima versão no pubspec.yaml: $(sed -n 's/^version: *//p' pubspec.yaml)"
