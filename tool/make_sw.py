"""flutter build web 뒤에 돌린다. Flutter 기본 서비스 워커는 하위 경로(/sogsal/)에서
캐시를 못 찾아서, 경로와 상관없이 동작하는 걸로 바꿔 끼운다.

- 처음 설치 때: 앱 뼈대(index.html, main.dart.js, 글꼴 목록 등)를 미리 받아둔다.
- 그 뒤: 같은 주소에서 받는 파일은 한 번 받으면 저장해두고 다음부턴 저장본을 쓴다.
- 화면(index.html)은 인터넷이 되면 새로 받고, 안 되면 저장본을 연다.
- 빌드가 바뀌면 VERSION이 바뀌어 새 저장소를 만들고 옛것은 지운다.
"""
import hashlib, json, os, sys

web = sys.argv[1] if len(sys.argv) > 1 else 'build/web'
skip_ext = ('.symbols', '.map')
skip_names = {'flutter_service_worker.js', 'NOTICES'}
files = []
h = hashlib.sha256()
for root, _, names in os.walk(web):
    for n in sorted(names):
        p = os.path.join(root, n)
        rel = os.path.relpath(p, web).replace(os.sep, '/')
        if n in skip_names or n.endswith(skip_ext):
            continue
        files.append(rel)
        with open(p, 'rb') as f:
            h.update(rel.encode()); h.update(f.read())
files.sort()
version = h.hexdigest()[:12]
core = [f for f in files if f in (
    'index.html', 'main.dart.js', 'flutter.js', 'flutter_bootstrap.js', 'manifest.json',
    'favicon.png', 'assets/FontManifest.json', 'assets/AssetManifest.bin.json',
    'assets/AssetManifest.bin', 'assets/AssetManifest.json')]
core.insert(0, './')

sw = f"""// make_sw.py가 만든 파일. 직접 고치지 말 것.
const VERSION = '{version}';
const CACHE = 'sogsal-' + VERSION;
const CORE = {json.dumps(core)};

self.addEventListener('install', (e) => {{
  e.waitUntil(
    caches.open(CACHE)
      .then((c) => c.addAll(CORE.map((u) => new Request(u, {{ cache: 'reload' }}))))
      .then(() => self.skipWaiting())
  );
}});

self.addEventListener('activate', (e) => {{
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith('sogsal-') && k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
}});

const scope = () => self.registration.scope;

self.addEventListener('fetch', (e) => {{
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Flutter가 기본 글꼴(Roboto)을 구글에서 받는다. 이것도 저장해둔다.
  if (url.hostname === 'fonts.gstatic.com') {{
    e.respondWith(caches.open(CACHE).then((c) => c.match(req).then((hit) => hit || fetch(req).then((res) => {{
      if (res.ok || res.type === 'opaque') c.put(req, res.clone());
      return res;
    }}))));
    return;
  }}
  if (!req.url.startsWith(scope())) return;
  // 화면: 인터넷 먼저, 안 되면 저장본
  if (req.mode === 'navigate' || url.href === scope() || url.pathname.endsWith('/index.html')) {{
    e.respondWith(
      fetch(req).then((res) => {{
        if (res.ok) caches.open(CACHE).then((c) => c.put('./', res.clone()));
        return res;
      }}).catch(() => caches.match('./', {{ cacheName: CACHE }}))
    );
    return;
  }}
  // 나머지: 저장본 먼저, 없으면 받아서 저장 (?v= 꼬리는 떼고 찾는다)
  url.searchParams.delete('v');
  const key = url.href;
  e.respondWith(
    caches.open(CACHE).then((c) => c.match(key).then((hit) => hit || fetch(req).then((res) => {{
      if (res.ok) c.put(key, res.clone());
      return res;
    }})))
  );
}});
"""
with open(os.path.join(web, 'flutter_service_worker.js'), 'w') as f:
    f.write(sw)
print(f'service worker {version}: {len(core)} core files')
