// Substitui o service worker do Flutter (cache offline). Os celulares que já
// têm o antigo instalado baixam este, que apaga a cópia guardada, se desliga
// e recarrega as abas abertas na versão nova. Depois disso o site passa a
// vir sempre da rede (com o controle de versão do versao.json).
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const chaves = await caches.keys();
    await Promise.all(chaves.map((c) => caches.delete(c)));
    await self.registration.unregister();
    // recarrega só se havia cópia antiga (o site novo não registra service
    // worker, então isso acontece uma vez só)
    if (chaves.length === 0) return;
    const abas = await self.clients.matchAll({ type: 'window' });
    for (const aba of abas) {
      aba.navigate(aba.url);
    }
  })());
});
