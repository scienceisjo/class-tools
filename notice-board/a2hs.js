/* ═══════════════════════════════════════════════════════════════
   📱 홈 화면에 추가 — 해누리중 공지 시스템 공용 조각
   ---------------------------------------------------------------
   쓰는 법 : 페이지 맨 아래에서 아래 두 줄만 넣으면 됩니다.
     <script>window.A2HS={name:()=>'해누리중 공지', theme:'#2563eb'};</script>
     <script src="a2hs.js"></script>

   옵션
     name        앱 이름 (문자열 또는 함수). 반 이름처럼 그때그때
                 달라지는 경우를 위해 함수도 받습니다.
     short       홈 화면 아이콘 아래 짧은 이름
     theme       상단 색
     onlyMobile  true 면 좁은 화면(폰)에서만 버튼을 띄웁니다.
                 전자칠판에는 필요 없는 버튼이라 공지판에 씁니다.
   ═══════════════════════════════════════════════════════════════ */
(function () {
  var CFG = window.A2HS || {};
  var BASE = new URL('.', location.href).href;

  // 이미 홈 화면에서 실행 중이면 버튼을 만들 이유가 없습니다
  var installed = (window.matchMedia &&
                   matchMedia('(display-mode: standalone)').matches) ||
                  window.navigator.standalone === true;
  if (installed) return;

  var isIOS = /iphone|ipad|ipod/i.test(navigator.userAgent) ||
              (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

  function appName() {
    var n = (typeof CFG.name === 'function') ? CFG.name() : CFG.name;
    return n || document.title || '해누리중 공지';
  }

  /* ── 1. 이 페이지에 맞는 앱 정보를 즉석에서 만들어 연결합니다 ──
     반마다 주소(?class=2-3)가 다르므로 파일로 고정해 둘 수 없어,
     지금 보고 있는 주소 그대로를 시작 주소로 넣습니다. */
  function attachManifest() {
    var name = appName();
    var mf = {
      name: name,
      short_name: (CFG.short || name).slice(0, 12),
      start_url: location.pathname + location.search,
      scope: new URL('.', location.href).pathname,
      display: 'standalone',
      background_color: '#ffffff',
      theme_color: CFG.theme || '#2563eb',
      icons: [
        { src: BASE + 'logo-192.png', sizes: '192x192', type: 'image/png' },
        { src: BASE + 'logo-512.png', sizes: '512x512', type: 'image/png' },
        { src: BASE + 'logo-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' }
      ]
    };
    var url = URL.createObjectURL(new Blob([JSON.stringify(mf)], { type: 'application/manifest+json' }));
    var link = document.querySelector('link[rel="manifest"]') || document.createElement('link');
    link.rel = 'manifest'; link.href = url;
    if (!link.parentNode) document.head.appendChild(link);

    if (!document.querySelector('link[rel="apple-touch-icon"]')) {
      var ai = document.createElement('link');
      ai.rel = 'apple-touch-icon'; ai.href = BASE + 'logo-192.png';
      document.head.appendChild(ai);
    }
    if (!document.querySelector('meta[name="theme-color"]')) {
      var tc = document.createElement('meta');
      tc.name = 'theme-color'; tc.content = CFG.theme || '#2563eb';
      document.head.appendChild(tc);
    }
    if (!document.querySelector('meta[name="apple-mobile-web-app-title"]')) {
      var at = document.createElement('meta');
      at.name = 'apple-mobile-web-app-title'; at.content = (CFG.short || name).slice(0, 12);
      document.head.appendChild(at);
    }
  }

  /* ── 2. 설치 안내를 띄우려면 서비스워커가 하나 있어야 합니다.
     내용을 저장해 두지는 않습니다. 저장해 두면 화면이 옛날 것으로
     굳어 버려서, 공지가 바뀌어도 안 바뀐 것처럼 보이게 됩니다. ── */
  function registerSW() {
    if (!('serviceWorker' in navigator) || location.protocol === 'file:') return;
    navigator.serviceWorker.register(BASE + 'sw.js').catch(function () {});
  }

  /* ── 3. 버튼 ── */
  var style = document.createElement('style');
  style.textContent =
    '#a2hsBtn{position:fixed;left:14px;bottom:14px;z-index:9998;display:none;' +
    'align-items:center;gap:6px;padding:10px 15px;border:0;border-radius:999px;' +
    'background:#2563eb;color:#fff;font-size:14px;font-weight:700;cursor:pointer;' +
    'box-shadow:0 6px 18px rgba(37,99,235,.35);font-family:inherit}' +
    '#a2hsBtn:active{transform:scale(.96)}' +
    '#a2hsWrap{position:fixed;inset:0;z-index:9999;display:none;align-items:center;' +
    'justify-content:center;background:rgba(15,23,42,.45);padding:18px}' +
    '#a2hsBox{background:#fff;border-radius:18px;padding:22px;max-width:340px;width:100%;' +
    'font-family:inherit;color:#1e293b;box-shadow:0 20px 50px rgba(0,0,0,.25)}' +
    '#a2hsBox h3{margin:0 0 10px;font-size:17px}' +
    '#a2hsBox ol{margin:0;padding-left:20px;line-height:1.85;font-size:14px}' +
    '#a2hsBox .sh{display:inline-block;padding:1px 7px;border-radius:6px;background:#eff6ff;' +
    'color:#2563eb;font-weight:700}' +
    '#a2hsBox button{margin-top:16px;width:100%;padding:11px;border:0;border-radius:12px;' +
    'background:#2563eb;color:#fff;font-size:15px;font-weight:700;cursor:pointer;font-family:inherit}';
  document.head.appendChild(style);

  var btn = document.createElement('button');
  btn.id = 'a2hsBtn';
  btn.innerHTML = '📱 홈 화면에 추가';
  btn.setAttribute('aria-label', '이 화면을 휴대폰 홈 화면에 추가합니다');

  // 설치 안내 신호가 오지 않는 브라우저를 위해, 직접 하는 방법을 적어 둡니다
  var steps = isIOS
    ? '<li>화면 아래의 <span class="sh">공유 ⬆️</span> 단추를 누릅니다.</li>' +
      '<li>목록을 내려서 <span class="sh">홈 화면에 추가</span>를 고릅니다.</li>' +
      '<li>오른쪽 위 <span class="sh">추가</span>를 누르면 끝입니다.</li>'
    : '<li>오른쪽 위 <span class="sh">⋮</span> (또는 <span class="sh">≡</span>) 를 누릅니다.</li>' +
      '<li><span class="sh">홈 화면에 추가</span> 를 고릅니다.</li>' +
      '<li><span class="sh">설치</span> 또는 <span class="sh">추가</span> 를 누르면 끝입니다.</li>';

  var wrap = document.createElement('div');
  wrap.id = 'a2hsWrap';
  wrap.innerHTML =
    '<div id="a2hsBox">' +
    '<h3>📱 홈 화면에 추가하기</h3>' +
    '<ol>' + steps + '</ol>' +
    '<button type="button">알겠습니다</button></div>';
  wrap.addEventListener('click', function (e) {
    if (e.target === wrap || e.target.tagName === 'BUTTON') wrap.style.display = 'none';
  });

  function show() {
    if (CFG.onlyMobile && window.innerWidth > 900) return;   // 전자칠판에는 띄우지 않습니다
    btn.style.display = 'inline-flex';
  }

  var prompt = null;
  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault(); prompt = e; show();
  });
  window.addEventListener('appinstalled', function () { btn.style.display = 'none'; });

  btn.addEventListener('click', function () {
    if (prompt) {
      prompt.prompt();
      prompt.userChoice.then(function (r) {
        if (r && r.outcome === 'accepted') btn.style.display = 'none';
        prompt = null;
      });
    } else {
      wrap.style.display = 'flex';       // 아이폰 등 — 직접 하는 방법을 안내합니다
    }
  });

  function start() {
    attachManifest();
    registerSW();
    document.body.appendChild(btn);
    document.body.appendChild(wrap);
    // 설치 신호를 주지 않는 브라우저(아이폰 등)도 있어, 버튼은 늘 띄워 두고
    // 신호가 없을 때는 직접 하는 방법을 안내합니다
    show();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
