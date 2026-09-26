/* PDF 만능 도구 — 서비스 워커 (오프라인 지원 + 설치)
   버전을 올리면(예: v1 → v2) 이전 캐시가 정리되고 새 파일을 받아옵니다. */
const CACHE = "pdf-tool-v2";
const CORE = [
  "./", "index.html", "manifest.webmanifest",
  "icons/icon-192.png", "icons/icon-512.png",
  "lib/pdf-lib.min.js", "lib/pdf.min.js", "lib/pdf.worker.min.js", "lib/fflate.min.js"
];

self.addEventListener("install", e=>{
  e.waitUntil(
    caches.open(CACHE).then(c=>c.addAll(CORE)).then(()=>self.skipWaiting())
  );
});

self.addEventListener("activate", e=>{
  e.waitUntil(
    caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k))))
      .then(()=>self.clients.claim())
  );
});

self.addEventListener("fetch", e=>{
  const req = e.request;
  if(req.method !== "GET") return;
  const url = new URL(req.url);
  if(url.origin !== location.origin) return;   // 외부 요청(방문자 수 집계)엔 관여하지 않음

  const isDoc = req.mode === "navigate" || url.pathname.endsWith("/") || url.pathname.endsWith("index.html");
  if(isDoc){
    // 문서(HTML)는 최신 우선 → 업데이트가 바로 반영. 학교 와이파이가 느려 4초 안에 안 오면
    // 저장해 둔 화면을 먼저 보여 주고, 새 문서는 뒤에서 받아 다음번에 쓴다. 오프라인이면 캐시로 폴백
    e.respondWith((async ()=>{
      const c = await caches.open(CACHE);
      const net = fetch(req).then(res=>{ if(res.ok) c.put(req, res.clone()); return res; });
      const cached = (await caches.match(req)) || (await caches.match("index.html"));
      if(!cached) return net.catch(()=>Response.error());
      e.waitUntil(net.catch(()=>{}));
      const timeout = new Promise(res=>setTimeout(()=>res(cached), 4000));
      return Promise.race([net.catch(()=>cached), timeout]);
    })());
  }else{
    // 라이브러리·wasm·OCR 데이터 등은 캐시 우선 → 빠르고, 한 번 받으면 인터넷 없이도 열림
    e.respondWith((async ()=>{
      const hit = await caches.match(req);
      if(hit) return hit;
      try{
        const res = await fetch(req);
        if(res.ok){ const c = await caches.open(CACHE); c.put(req, res.clone()); }
        return res;
      }catch(err){
        return hit || Response.error();
      }
    })());
  }
});
