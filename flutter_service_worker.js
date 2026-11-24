// make_sw.py가 만든 파일. 직접 고치지 말 것.
const VERSION = 'cc8e94af0c24';
const CACHE = 'sogsal-' + VERSION;
const CORE = ["./", "assets/AssetManifest.bin", "assets/AssetManifest.bin.json", "assets/AssetManifest.json", "assets/FontManifest.json", "favicon.png", "flutter.js", "flutter_bootstrap.js", "index.html", "main.dart.js", "manifest.json"];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE)
      .then((c) => c.addAll(CORE.map((u) => new Request(u, { cache: 'reload' }))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith('sogsal-') && k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

const scope = () => self.registration.scope;

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Flutter가 기본 글꼴(Roboto)을 구글에서 받는다. 이것도 저장해둔다.
  if (url.hostname === 'fonts.gstatic.com') {
    e.respondWith(caches.open(CACHE).then((c) => c.match(req).then((hit) => hit || fetch(req).then((res) => {
      if (res.ok || res.type === 'opaque') c.put(req, res.clone());
      return res;
    }))));
    return;
  }
  if (!req.url.startsWith(scope())) return;
  // 화면: 인터넷 먼저, 안 되면 저장본
  if (req.mode === 'navigate' || url.href === scope() || url.pathname.endsWith('/index.html')) {
    e.respondWith(
      fetch(req).then((res) => {
        if (res.ok) caches.open(CACHE).then((c) => c.put('./', res.clone()));
        return res;
      }).catch(() => caches.match('./', { cacheName: CACHE }))
    );
    return;
  }
  // 나머지: 저장본 먼저, 없으면 받아서 저장 (?v= 꼬리는 떼고 찾는다)
  url.searchParams.delete('v');
  const key = url.href;
  e.respondWith(
    caches.open(CACHE).then((c) => c.match(key).then((hit) => hit || fetch(req).then((res) => {
      if (res.ok) c.put(key, res.clone());
      return res;
    })))
  );
});
