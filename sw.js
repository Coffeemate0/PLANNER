const CACHE = 'together-shell-v1';
const SHELL = [
  './', './index.html', './manifest.json', './icons/icon.svg', './icons/icon-192.png', './icons/icon-512.png', './icons/apple-touch-icon.png'
];
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(SHELL)).then(()=>self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));
});
self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  const cacheableExternal = url.origin === 'https://cdn.jsdelivr.net';
  if (url.origin === location.origin || cacheableExternal) {
    event.respondWith(
      caches.match(req).then(hit => hit || fetch(req).then(res => {
        const clone = res.clone();
        caches.open(CACHE).then(c => c.put(req, clone)).catch(()=>{});
        return res;
      }).catch(() => caches.match('./index.html')))
    );
  }
});
self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil(clients.matchAll({type:'window',includeUncontrolled:true}).then(list=>{for(const client of list){if('focus'in client)return client.focus()}if(clients.openWindow)return clients.openWindow('./')}));
});
self.addEventListener('push', event => {

  let data = {
    title: 'Together ❤️',
    body: 'You have a new reminder.',
    url: './',
    tag: 'together-reminder'
  };

  try {
    if (event.data) {
      data = {
        ...data,
        ...event.data.json()
      };
    }
  } catch (error) {
    try {
      if (event.data) {
        data.body = event.data.text();
      }
    } catch (_) {}
  }

  event.waitUntil(
    self.registration.showNotification(
      data.title,
      {
        body: data.body,
        icon: './icons/icon-192.png',
        badge: './icons/icon-192.png',
        tag: data.tag,
        renotify: true,
        data: {
          url: data.url || './'
        }
      }
    )
  );

});
