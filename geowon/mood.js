/* ═══════════════════════════════════════════════════════════════
   🌡️ 마음온도 — 교실 화면 · 내 폰(mood.html) · 관리 화면이 함께 씀
   ---------------------------------------------------------------
   단계 1~5 → 마음온도 0~100°  (꽁꽁 0 · 쌀쌀 25 · 미지근 50 · 따뜻 75 · 후끈 100)
   캐릭터 「마음이」는 SVG 로 직접 그립니다(머리 위 더듬이 = 센서).
   이름은 받지 않습니다. 반·단계·느낌 낱말만 서버 함수(mood_checkin)로 보냅니다.
   ═══════════════════════════════════════════════════════════════ */
(function () {
  const LEVELS = [null,
    { lv: 1, key: '꽁꽁',   label: '많이 힘들어요', color: '#3d6fd8', deg: 0 },
    { lv: 2, key: '쌀쌀',   label: '조금 처져요',   color: '#2fa6c6', deg: 25 },
    { lv: 3, key: '미지근', label: '그저 그래요',   color: '#93b45f', deg: 50 },
    { lv: 4, key: '따뜻',   label: '좋아요',        color: '#f0a933', deg: 75 },
    { lv: 5, key: '후끈',   label: '최고예요',      color: '#ee6a37', deg: 100 },
  ];
  const FEELINGS = {
    1: ['피곤해요', '속상해요', '걱정돼요', '화나요', '외로워요', '아파요'],
    2: ['피곤해요', '속상해요', '걱정돼요', '졸려요', '심심해요', '아파요'],
    3: ['괜찮아요', '피곤해요', '졸려요', '심심해요', '편안해요'],
    4: ['편안해요', '신나요', '설레요', '뿌듯해요', '고마워요'],
    5: ['신나요', '설레요', '뿌듯해요', '고마워요', '편안해요'],
  };
  const INK = '#22304d';

  /* 「마음이」 — 단계마다 표정이 다른 캐릭터 */
  function face(lv, px) {
    const L = LEVELS[lv] || LEVELS[3];
    const s = `stroke="${INK}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" fill="none"`;
    let eyes = '', mouth = '', extra = '';
    if (lv === 1) {
      eyes = `<path d="M29 54 q7 6 14 0" ${s}/><path d="M57 54 q7 6 14 0" ${s}/>`
           + `<path d="M28 46 l12 -5" ${s}/><path d="M72 46 l-12 -5" ${s}/>`;
      mouth = `<path d="M38 84 q12 -11 24 0" ${s}/>`;
      extra = `<path d="M33 63 q-4 7 0 10 q4 -3 0 -10z" fill="#bfe3ff" stroke="${INK}" stroke-width="2"/>`;
    } else if (lv === 2) {
      eyes = `<circle cx="36" cy="57" r="4.5" fill="${INK}"/><circle cx="64" cy="57" r="4.5" fill="${INK}"/>`
           + `<path d="M29 48 l11 -3" ${s}/><path d="M71 48 l-11 -3" ${s}/>`;   // 안쪽이 올라간 눈썹 = 처진 마음
      mouth = `<path d="M40 82 q10 -6 20 0" ${s}/>`;
    } else if (lv === 3) {
      eyes = `<circle cx="36" cy="57" r="4.5" fill="${INK}"/><circle cx="64" cy="57" r="4.5" fill="${INK}"/>`;
      mouth = `<path d="M40 79 h20" ${s}/>`;
    } else if (lv === 4) {
      eyes = `<circle cx="36" cy="56" r="4.5" fill="${INK}"/><circle cx="64" cy="56" r="4.5" fill="${INK}"/>`;
      mouth = `<path d="M38 74 q12 11 24 0" ${s}/>`;
      extra = `<ellipse cx="26" cy="70" rx="6" ry="3.5" fill="#ff8fa3" opacity=".45"/><ellipse cx="74" cy="70" rx="6" ry="3.5" fill="#ff8fa3" opacity=".45"/>`;
    } else {
      eyes = `<path d="M29 58 q7 -9 14 0" ${s}/><path d="M57 58 q7 -9 14 0" ${s}/>`;
      mouth = `<path d="M36 71 q14 0 28 0 q-2 16 -14 16 q-12 0 -14 -16z" fill="${INK}" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`
            + `<path d="M43 82 q7 -5 14 0 q-3 5 -7 5 q-4 0 -7 -5z" fill="#ff8fa3"/>`;
      extra = `<ellipse cx="25" cy="70" rx="6" ry="3.5" fill="#ff8fa3" opacity=".55"/><ellipse cx="75" cy="70" rx="6" ry="3.5" fill="#ff8fa3" opacity=".55"/>`
            + `<path d="M86 22 l2 6 l6 2 l-6 2 l-2 6 l-2 -6 l-6 -2 l6 -2z" fill="#ffd34d"/>`;
    }
    return `<svg class="mc-face" viewBox="0 0 100 112" width="${px}" height="${px * 1.12}" aria-hidden="true">
      <line x1="50" y1="19" x2="50" y2="8" stroke="${INK}" stroke-width="3.5" stroke-linecap="round"/>
      <circle cx="50" cy="6" r="4.5" fill="${L.color}" stroke="${INK}" stroke-width="2.5"/>
      <ellipse cx="34" cy="106" rx="11" ry="5" fill="${INK}" opacity=".85"/><ellipse cx="66" cy="106" rx="11" ry="5" fill="${INK}" opacity=".85"/>
      <path d="M50 17 C79 17 93 35 93 61 C93 89 75 104 50 104 C25 104 7 89 7 61 C7 35 21 17 50 17Z" fill="${L.color}" stroke="${INK}" stroke-width="3.5"/>
      <ellipse cx="50" cy="88" rx="22" ry="11" fill="#fff" opacity=".2"/>
      ${extra}${eyes}${mouth}</svg>`;
  }

  /* 평균 단계 → 마음온도(0~100°) · 그 온도의 색 */
  const tempOf = avg => (avg - 1) * 25;
  function colorAt(deg) {
    const d = Math.max(0, Math.min(100, deg)) / 25, i = Math.floor(d), f = d - i;
    if (i >= 4) return LEVELS[5].color;
    const a = hex(LEVELS[i + 1].color), b = hex(LEVELS[i + 2].color);
    return `rgb(${a.map((v, k) => Math.round(v + (b[k] - v) * f)).join(',')})`;
  }
  const hex = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
  const levelOfTemp = deg => Math.max(1, Math.min(5, Math.round(deg / 25) + 1));

  /* 우리 반 표정 모음 — 체크인 한 번에 마음이 하나 (단계 순서로) */
  function crowd(el, rows, max) {
    const list = rows.slice().sort((a, b) => b.level - a.level).slice(0, max || 60);
    const n = list.length;
    // 칸 크기에 맞춰 마음이 크기를 정함 (인원이 적으면 크게, 많으면 작게)
    const W = el.clientWidth, H = el.clientHeight;
    let px = n <= 12 ? 64 : n <= 24 ? 52 : n <= 40 ? 42 : 34;
    if (W > 0 && H > 0 && n) {
      px = Math.floor(Math.sqrt(W * H / (n * 1.12)) * 0.78);
      while (px > 24 && Math.floor(W / (px + 4)) * Math.floor(H / (px * 1.12 + 4)) < n) px -= 2;
      px = Math.max(24, Math.min(150, px));
    }
    // 같은 자료면 다시 그리지 않음(깜빡임 방지), 새로 들어온 만큼만 「new」로 표시해 나타나는 효과
    const sig = `${rows.length}|${rows.length ? rows[rows.length - 1].at : ''}|${px}`;
    if (el.dataset.sig === sig) return;
    const prev = el.dataset.sig ? Number(el.dataset.sig.split('|')[0]) : n;
    el.dataset.sig = sig;
    const fresh = Math.max(0, n - prev);
    const newest = new Set(rows.slice(rows.length - fresh));
    el.innerHTML = list.map(r => `<span class="mc-cw${newest.has(r) ? ' new' : ''}" title="${LEVELS[r.level].key}">${face(r.level, px)}</span>`).join('')
      + (rows.length > list.length ? `<span class="mc-more">+${rows.length - list.length}</span>` : '');
  }

  /* 센서 그래프 — 가로: 시각, 세로: 마음온도(그때까지의 평균), 점: 체크인 하나하나 */
  function graph(svg, rows, opt) {
    const W = 600, H = 220, P = { l: 40, r: 12, t: 12, b: 26 };
    const t0 = (opt && opt.from) || 8 * 60, t1 = (opt && opt.to) || 16 * 60 + 30;
    const mins = d => { const x = new Date(d); return x.getHours() * 60 + x.getMinutes() + x.getSeconds() / 60; };
    const X = m => P.l + (Math.max(t0, Math.min(t1, m)) - t0) / (t1 - t0) * (W - P.l - P.r);
    const Y = deg => P.t + (100 - deg) / 100 * (H - P.t - P.b);
    let g = '';
    for (let d = 0; d <= 100; d += 25) {
      g += `<line x1="${P.l}" x2="${W - P.r}" y1="${Y(d)}" y2="${Y(d)}" class="mc-grid"/>`
         + `<text x="${P.l - 6}" y="${Y(d) + 4}" class="mc-ax" text-anchor="end">${d}°</text>`;
    }
    for (let h = Math.ceil(t0 / 60); h * 60 <= t1; h++) {
      g += `<line x1="${X(h * 60)}" x2="${X(h * 60)}" y1="${P.t}" y2="${H - P.b}" class="mc-grid"/>`
         + `<text x="${X(h * 60)}" y="${H - 8}" class="mc-ax" text-anchor="middle">${h}시</text>`;
    }
    let sum = 0, pts = [], dots = '';
    rows.forEach((r, i) => {
      sum += r.level;
      const x = X(mins(r.at));
      pts.push(`${x.toFixed(1)},${Y(tempOf(sum / (i + 1))).toFixed(1)}`);
      dots += `<circle cx="${x.toFixed(1)}" cy="${Y(LEVELS[r.level].deg).toFixed(1)}" r="4" fill="${LEVELS[r.level].color}" opacity=".55"/>`;
    });
    const line = pts.length ? `<polyline points="${pts.join(' ')}" class="mc-line"/>` : '';
    const now = opt && opt.now ? `<line x1="${X(opt.now)}" x2="${X(opt.now)}" y1="${P.t}" y2="${H - P.b}" class="mc-now"/>` : '';
    svg.setAttribute('viewBox', `0 0 ${W} ${H}`);
    svg.innerHTML = g + now + dots + line;
  }

  /* ── 체크인 창 ─────────────────────────────────────────────
     opt: { sb, grade, cls, source:'board'|'phone', onDone(level), talkUrl, onTalk(), autoClose:true } */
  let css = false;
  function injectCss() {
    if (css) return; css = true;
    const st = document.createElement('style');
    st.textContent = `
.mc-ov{position:fixed;inset:0;z-index:90;background:rgba(14,22,40,.55);display:flex;align-items:center;justify-content:center;
  padding:2vmin;font-size:var(--mc-fs,16px);font-family:inherit}
.mc-box{background:#f7f9fc;border-radius:1.4em;width:min(62em,100%);max-height:96vh;overflow:auto;padding:1.4em 1.6em 1.6em;
  box-shadow:0 1em 3em rgba(0,0,0,.25);position:relative}
.mc-top{display:flex;align-items:center;gap:.6em;font-size:.95em;font-weight:800;color:#5a6782}
.mc-led{width:.7em;height:.7em;border-radius:50%;background:#19c37d;box-shadow:0 0 .5em #19c37d;animation:mcBlink 1.4s infinite}
@keyframes mcBlink{50%{opacity:.35}}
.mc-x{margin-left:auto;border:none;background:#e6ebf3;color:#5a6782;font-size:1.1em;font-weight:900;width:2.2em;height:2.2em;border-radius:50%;cursor:pointer}
.mc-q{font-size:1.9em;font-weight:900;color:#1d2742;text-align:center;margin:.5em 0 .7em}
.mc-faces{display:grid;grid-template-columns:repeat(5,1fr);gap:.7em}
.mc-fb{border:2px solid #e3e8f4;background:#fff;border-radius:1.1em;padding:.8em .3em .7em;cursor:pointer;font-family:inherit;
  display:flex;flex-direction:column;align-items:center;gap:.25em;transition:transform .12s}
.mc-fb:active{transform:scale(.96)}
.mc-fb .mc-face{width:72%;height:auto}
.mc-fb b{font-size:1.25em;color:#1d2742}
.mc-fb span{font-size:.95em;color:#5a6782;font-weight:700}
.mc-fb i{font-style:normal;font-size:.9em;font-weight:800;font-family:'DSEG7',ui-monospace,monospace;margin-top:.15em}
.mc-chips{display:flex;flex-wrap:wrap;gap:.6em;justify-content:center;margin:.4em 0 1em}
.mc-chip{border:2px solid #e3e8f4;background:#fff;border-radius:99px;padding:.6em 1.2em;font-size:1.2em;font-weight:800;color:#33405e;cursor:pointer;font-family:inherit}
.mc-skip{display:block;margin:0 auto;border:none;background:none;color:#5a6782;font-size:1.05em;font-weight:700;cursor:pointer;font-family:inherit;text-decoration:underline}
.mc-done{text-align:center;padding:.6em 0}
.mc-done .mc-face{width:9em;height:auto}
.mc-done h3{font-size:1.8em;margin:.3em 0 .2em;color:#1d2742}
.mc-done p{font-size:1.1em;color:#5a6782;font-weight:600}
.mc-talk{margin:1em auto 0;max-width:30em;background:#fff6e8;border:1.5px solid #ffd59a;border-radius:1em;padding:1em;color:#7a4b00;font-weight:700;line-height:1.5}
.mc-talk button,.mc-talk a{display:inline-block;margin-top:.6em;border:none;background:#3b6ef5;color:#fff;border-radius:99px;
  padding:.6em 1.3em;font-size:1em;font-weight:800;cursor:pointer;text-decoration:none;font-family:inherit}
.mc-err{color:#d33;font-weight:800;text-align:center;margin-top:.6em}
@media (max-width:560px){.mc-faces{grid-template-columns:repeat(3,1fr)}.mc-q{font-size:1.5em}}`;
    document.head.appendChild(st);
  }
  function esc(s) { return String(s ?? '').replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c])); }

  function open(opt) {
    injectCss();
    const ov = document.createElement('div');
    ov.className = 'mc-ov';
    ov.innerHTML = `<div class="mc-box" role="dialog" aria-label="마음온도 체크인">
      <div class="mc-top"><span class="mc-led"></span>마음온도 센서 · ${opt.grade}학년 ${opt.cls}반 · 이름은 남지 않아요
        <button class="mc-x" aria-label="닫기">✕</button></div>
      <div class="mc-body"></div></div>`;
    document.body.appendChild(ov);
    const body = ov.querySelector('.mc-body');
    let timer = null;
    const close = () => { clearTimeout(timer); ov.remove(); };
    ov.querySelector('.mc-x').onclick = close;
    ov.addEventListener('click', e => { if (e.target === ov) close(); });

    function step1() {
      body.innerHTML = `<div class="mc-q">지금 내 마음온도는?</div><div class="mc-faces">${
        [1, 2, 3, 4, 5].map(lv => `<button class="mc-fb" data-lv="${lv}">${face(lv, 100)}<b>${LEVELS[lv].key}</b>
          <span>${LEVELS[lv].label}</span><i style="color:${LEVELS[lv].color}">${LEVELS[lv].deg}</i></button>`).join('')}</div>`;
      body.querySelectorAll('.mc-fb').forEach(b => b.onclick = () => step2(Number(b.dataset.lv)));
    }
    function step2(lv) {
      body.innerHTML = `<div class="mc-q">${face(lv, 56)}<br>어떤 마음인지 하나 골라도 돼요</div>
        <div class="mc-chips">${FEELINGS[lv].map(f => `<button class="mc-chip">${f}</button>`).join('')}</div>
        <button class="mc-skip">고르지 않고 보내기</button><div class="mc-err"></div>`;
      body.querySelectorAll('.mc-chip').forEach(b => b.onclick = () => send(lv, b.textContent));
      body.querySelector('.mc-skip').onclick = () => send(lv, null);
    }
    async function send(lv, feeling) {
      body.querySelectorAll('button').forEach(b => b.disabled = true);
      let r = 'ok';
      try {
        const { data, error } = await opt.sb.rpc('mood_checkin', { p_grade: opt.grade, p_class: opt.cls, p_level: lv, p_feeling: feeling, p_source: opt.source || 'board' });
        r = error ? (/function|schema cache|PGRST202/i.test(error.message) ? 'not_ready' : 'error') : data;
      } catch (e) { r = 'error'; }
      if (r !== 'ok') {
        const msg = { full: '오늘은 우리 반 체크인이 너무 많아요. 내일 다시 해 주세요.', not_ready: '마음온도가 아직 준비되지 않았어요. 선생님께 알려 주세요.' }[r] || '보내지 못했어요. 잠시 뒤에 다시 해 주세요.';
        const e = body.querySelector('.mc-err'); if (e) e.textContent = msg; else body.innerHTML += `<div class="mc-err">${msg}</div>`;
        body.querySelectorAll('button').forEach(b => b.disabled = false);
        return;
      }
      const L = LEVELS[lv];
      body.innerHTML = `<div class="mc-done">${face(lv, 150)}<h3>체크인했어요</h3>
        <p>${L.key} · ${L.deg}°${feeling ? ' · ' + esc(feeling) : ''}</p>
        ${lv <= 2 ? `<div class="mc-talk">힘들 땐 선생님께 이야기해도 괜찮아요. 이름을 숨기고 보낼 수도 있어요.<br>
          ${opt.onTalk ? '<button class="mc-tk">📮 선생님께 말하기</button>' : (opt.talkUrl ? `<a href="${esc(opt.talkUrl)}">📮 선생님께 말하기</a>` : '')}</div>` : ''}</div>`;
      const tk = body.querySelector('.mc-tk');
      if (tk) tk.onclick = () => { close(); opt.onTalk(); };
      if (opt.onDone) opt.onDone(lv, feeling);
      if (opt.autoClose !== false) timer = setTimeout(close, lv <= 2 ? 12000 : 3500);
    }
    step1();
    return { close };
  }

  window.MOOD = { LEVELS, FEELINGS, face, tempOf, colorAt, levelOfTemp, crowd, graph, open, injectCss };
})();
