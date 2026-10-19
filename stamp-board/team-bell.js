/* ══════════════════════════════════════════════════════════════════════════
   👥 모둠 골든벨 (2026-10-19) — 칭찬 도장판 🔔 골든벨 탭의 두 번째 모드

   ① 모둠 짜기   결석을 빼고 🎲 섞기 → 모둠마다 고르게 나눈다(두 사람을 차례로 누르면 자리 바꾸기)
   ② 문제 내기   학생 기기(team.html)가 방 번호로 들어와 모둠마다 문제 하나를 보낸다.
                 Supabase 방송 채널 'gbt-<방 번호>' — 표·SQL 없음, 학생 로그인 없음.
                 학생 기기에는 이름 대신 «모둠 번호와 출석 번호»만 보낸다.
                 종이로 받았으면 선생님이 ✏️ 대신 쓰기.
   ③ 골든벨     모둠이 낸 문제를 섞어서 낸다. 맞힌 모둠 +1, 출제 모둠은 그 문제를 쉰다.
                 맞힌 모둠과 틀린 모둠이 둘 다 나오면 출제 모둠에 «좋은 문제 보너스» +1.
   ④ 결과       우승 모둠·💡 베스트 문제(맞힌 비율이 반에 가장 가까운 문제) → 도장, ⭐ 내 문제에 담기

   상태는 이 기기 localStorage(gb_team_v1)에만 둔다. 개인 골든벨(GB)과는 따로 굴러간다.
   본체(index.html)와 이어지는 곳: renderGB 감싸개(모드 막대·모둠 화면), 단축키, 타이머 열쇠.
   ══════════════════════════════════════════════════════════════════════════ */
var TB_KEY = 'gb_team_v1';
var TB = null;
var TB_EMO = ['🦊','🐻','🐼','🐯','🐸','🐵','🐰','🐨','🦁','🐧'];
var TB_EMO_HW = ['🎃','👻','🦇','🕷️','🧙','🧟','💀','🍬','🕸️','🌕'];
var _tbCh = null, _tbChCode = '', _tbSel = null, _tbShufIv = 0, _tbDueIv = 0, _tbDueRang = false, _tbLiveSt = '';

function tbLoad(){ if(!TB) TB = gbLsJ(TB_KEY, null); return TB; }
function tbSave(){ try{ localStorage.setItem(TB_KEY, JSON.stringify(TB)); }catch(e){} }
function tbClear(){ tbUnlisten(); TB = null; try{ localStorage.removeItem(TB_KEY); }catch(e){} }
function gbTeamOn(){ return gbLs('gb_tmode', '0') === '1'; }
function tbMatches(){ return !!(TB && S.selClass && TB.g === S.selClass.grade && TB.c === S.selClass.cls); }
function gbTeamPlaying(){ tbLoad(); return gbTeamOn() && tbMatches() && TB.phase === 'play'; }
function tbEmo(i){ var a = gbHW() ? TB_EMO_HW : TB_EMO; return a[i % a.length]; }
function tbName(t){ return tbEmo(t.no - 1) + ' ' + t.no + '모둠'; }
function tbTeam(no){ for(var i=0;i<TB.teams.length;i++) if(TB.teams[i].no === no) return TB.teams[i]; return null; }
function tbStu(id){ for(var i=0;i<S.students.length;i++) if(S.students[i].id === id) return S.students[i]; return null; }
function tbLabel(id){ var s = tbStu(id); return s ? (s.number ? s.number + '. ' : '') + (s.name || '') : '?'; }
function tbTotal(t){ return (t.score || 0) + (t.bonus || 0); }
function tbUrl(code){
  /* 학생이 크롬북에서 손으로 칠 때는 짧은 주소(승재쌤과학/gb)가 편하다 */
  if(/github\.io$/.test(location.hostname)) return 'https://scienceisjo.github.io/scienceclass/gb/?c=' + code;
  return location.origin + location.pathname.replace(/[^\/]*$/, '') + 'team.html?c=' + code;
}
function tbShortUrl(){ return /github\.io$/.test(location.hostname) ? 'scienceisjo.github.io/scienceclass/gb' : location.host + location.pathname.replace(/[^\/]*$/, '') + 'team.html'; }

/* ── 모드 막대 — 진행 중에는 숨긴다(실수로 바꾸지 않게) ── */
function gbSetMode(team){
  gbLsSet('gb_tmode', team ? '1' : '0');
  gbTimerStop(); _tbSel = null;
  renderGB(); window.scrollTo(0, 0);
}
function gbModeBar(){
  tbLoad();
  var t = gbTeamOn();
  if(!t && GB && GB.ready && !GB.done && gbMatchesClass()) return '';
  if(t && tbMatches() && TB.phase === 'play') return '';
  return '<div class="gbtabs gbmode"><button class="' + (t ? '' : 'on') + '" onclick="gbSetMode(0)">🔔 개인 골든벨</button>' +
         '<button class="' + (t ? 'on' : '') + '" onclick="gbSetMode(1)">👥 모둠 골든벨</button></div>';
}

/* ══ 화면 ══ */
function gbTeamRender(){
  var el = $('p-gb'); if(!el) return;
  tbLoad(); gbHWApply('gb');
  var h = gbModeBar();
  if(!S.selClass){
    h += '<div class="card"><div class="hd"><h3 style="font-size:var(--fs-s)">👥 모둠 골든벨</h3></div>' +
         '<div class="sub">랜덤으로 모둠을 짜고, 모둠마다 문제를 하나씩 만들어 서로 풀어요.</div>' +
         '<div class="chips" id="gbClassChips" style="margin-top:10px"></div>' +
         '<div class="sub" style="margin-top:8px">반을 먼저 골라주세요</div>' + tbHowCard(true) + '</div>';
    el.innerHTML = h; renderGBClassChips(); return;
  }
  if(!TB || !tbMatches()){
    h += '<div class="card"><div class="hd"><h3 style="font-size:var(--fs-s)">👥 모둠 골든벨 · ' + S.selClass.grade + '학년 ' + S.selClass.cls + '반</h3></div>' +
         '<div class="chips" id="gbClassChips" style="margin:8px 0"></div>' + tbHowCard(true) +
         (TB ? '<div class="sub" style="margin-top:8px;color:var(--ac-d)">' + TB.g + '-' + TB.c + '반 모둠 골든벨이 남아 있어요 — 새로 시작하면 지워져요.</div>' : '') +
         '<button class="btn" style="margin-top:12px;background:var(--ac);color:#fff" onclick="tbBegin()">👥 모둠 짜기 시작</button></div>';
    el.innerHTML = h; renderGBClassChips(); return;
  }
  if(TB.phase === 'teams') h += tbTeamsUI();
  else if(TB.phase === 'make') h += tbMakeUI();
  else if(TB.phase === 'play') h += tbPlayUI();
  else h += tbDoneUI();
  el.innerHTML = h;
  if(TB.phase === 'make'){ tbListen(); tbQRDraw(); tbDueRun(); }
}
function tbHowCard(small){
  return '<div class="tb-how' + (small ? ' sm' : '') + '">' +
         '<div><b>1</b>🎲 랜덤 모둠</div><div><b>2</b>✍️ 모둠마다 문제 하나</div><div><b>3</b>🔔 서로 풀기</div><div><b>4</b>🏆 우승·베스트 문제</div></div>' +
         '<div class="sub" style="margin-top:8px">맞힌 모둠 <b>+1점</b> · 출제 모둠은 그 문제를 쉬어요 · 맞힌 모둠과 틀린 모둠이 <b>둘 다</b> 나오면 출제 모둠에 <b>좋은 문제 보너스 +1점</b></div>';
}

/* ══ ① 모둠 짜기 ══ */
function tbBegin(){
  if(!S.selClass){ toast('반을 먼저 골라주세요'); return; }
  if(!S.students || !S.students.length){ toast('이 반 학생 명단이 없어요'); return; }
  tbLoad();
  if(TB && !tbMatches() && !confirm(TB.g + '-' + TB.c + '반 모둠 골든벨을 지우고 새로 시작할까요?')) return;
  tbClear();
  var n = Math.max(2, Math.min(8, Math.round(S.students.length / 4)));
  TB = { g:S.selClass.grade, c:S.selClass.cls, phase:'teams', n:n, absent:{}, teams:[], subs:{}, made:Date.now() };
  tbShuffle(true);
}
function tbDeal(){
  var ids = S.students.filter(function(s){ return !TB.absent[s.id]; }).map(function(s){ return s.id; });
  gbShuffle(ids);
  var n = Math.max(2, Math.min(TB.n, ids.length || 2)), teams = [], i;
  for(i=0;i<n;i++) teams.push({ no:i + 1, ids:[], score:0, bonus:0 });
  ids.forEach(function(id, k){ teams[k % n].ids.push(id); });
  teams.forEach(function(t){ t.ids.sort(function(a, b){ return ((tbStu(a) || {}).number || 0) - ((tbStu(b) || {}).number || 0); }); });
  return teams;
}
/* 섞기 — 전자칠판에서 이름이 몇 번 휙휙 바뀌다가 멈춘다 */
function tbShuffle(anim){
  if(!TB) return;
  clearInterval(_tbShufIv); _tbSel = null;
  if(!anim){ TB.teams = tbDeal(); tbSave(); renderGB(); return; }
  var k = 0;
  _tbShufIv = setInterval(function(){
    TB.teams = tbDeal();
    k++;
    if(k >= 11){ clearInterval(_tbShufIv); _tbShufIv = 0; tbSave(); gbSyn('pop'); renderGB(); return; }
    gbSyn('tick'); renderGB();
  }, 85);
}
function tbSetN(n){ TB.n = n; tbShuffle(true); }
function tbAbsent(id){
  if(TB.absent[id]) delete TB.absent[id]; else TB.absent[id] = 1;
  TB.teams.forEach(function(t){ t.ids = t.ids.filter(function(x){ return x !== id; }); });
  if(!TB.absent[id]){   /* 다시 온 사람은 가장 적은 모둠에 */
    var min = TB.teams.slice().sort(function(a, b){ return a.ids.length - b.ids.length; })[0];
    if(min) min.ids.push(id);
  }
  tbBalance(); tbSave(); renderGB();
}
/* 모둠 크기 차이가 2명 이상이면 큰 모둠에서 작은 모둠으로 한 명씩 옮긴다(손으로 바꾼 자리는 되도록 그대로) */
function tbBalance(){
  var guard = 0, big, small;
  while(guard++ < 50){
    big = TB.teams.reduce(function(a, b){ return b.ids.length > a.ids.length ? b : a; });
    small = TB.teams.reduce(function(a, b){ return b.ids.length < a.ids.length ? b : a; });
    if(big.ids.length - small.ids.length < 2) break;
    small.ids.push(big.ids.pop());
  }
}
/* 두 사람을 차례로 누르면 서로 자리를 바꾼다 — 같은 사람을 다시 누르면 취소 */
function tbPick(id){
  if(_tbShufIv) return;
  if(!_tbSel){ _tbSel = id; renderGB(); return; }
  if(_tbSel === id){ _tbSel = null; renderGB(); return; }
  var a = null, b = null, ia = -1, ib = -1;
  TB.teams.forEach(function(t){
    var i = t.ids.indexOf(_tbSel); if(i >= 0){ a = t; ia = i; }
    var j = t.ids.indexOf(id); if(j >= 0){ b = t; ib = j; }
  });
  if(a && b){ a.ids[ia] = id; b.ids[ib] = _tbSel; }
  _tbSel = null; tbSave(); gbSyn('pop'); renderGB();
}
function tbTeamsUI(){
  var h = '<div class="card"><div class="hd"><h3 style="font-size:var(--fs-s)">🎲 모둠 짜기 · ' + TB.g + '학년 ' + TB.c + '반</h3>' +
          '<span class="sub">' + (S.students.length - Object.keys(TB.absent).length) + '명 참가</span></div>' +
          '<div class="sub">오늘 없는 사람을 먼저 빼고 섞어요. 이름 두 개를 차례로 누르면 서로 자리를 바꿔요.</div>' +
          '<div class="gbsec"><div class="k">모둠 수</div><div class="chips">';
  [3,4,5,6,7,8].forEach(function(n){
    h += '<button class="chip' + (TB.n === n ? ' on' : '') + '" onclick="tbSetN(' + n + ')">' + n + '모둠</button>';
  });
  var live = S.students.length - Object.keys(TB.absent).length, lo = Math.floor(live / TB.n), hi = Math.ceil(live / TB.n);
  h += '</div><div class="sub" style="margin-top:6px">모둠마다 ' + (lo === hi ? lo : lo + '~' + hi) + '명</div></div>';
  h += '<details class="gbsec"' + (Object.keys(TB.absent).length ? ' open' : '') + '><summary class="k" style="cursor:pointer">🙋 오늘 없는 사람 빼기 (' + Object.keys(TB.absent).length + '명)</summary><div class="chips" style="margin-top:6px">' +
       S.students.slice().sort(function(a, b){ return (a.number || 0) - (b.number || 0); }).map(function(s){
         return '<button class="chip sm' + (TB.absent[s.id] ? ' on' : '') + '" onclick="tbAbsent(\'' + s.id + '\')">' + esc(tbLabel(s.id)) + '</button>';
       }).join('') + '</div></details>';
  h += '<div class="tb-cards' + (_tbShufIv ? ' spin' : '') + '">' + TB.teams.map(function(t){
    return '<div class="tb-card"><div class="tb-h">' + tbName(t) + '<span>' + t.ids.length + '명</span></div><div class="tb-mem">' +
           t.ids.map(function(id){
             return '<button class="' + (_tbSel === id ? 'sel' : '') + '" onclick="tbPick(\'' + id + '\')">' + esc(tbLabel(id)) + '</button>';
           }).join('') + '</div></div>';
  }).join('') + '</div>';
  h += '<button class="gbbig" style="margin-top:14px" onclick="tbShuffle(true)">🎲 다시 섞기</button>' +
       '<button class="btn g" style="margin-top:9px" onclick="tbToMake()">✔ 이 모둠으로 문제 만들기 →</button>' +
       '<div style="display:flex;gap:8px;margin-top:9px"><button class="chip sm" style="flex:1" onclick="tbQuit()">그만두기</button>' +
       '<button class="chip sm" style="flex:1" onclick="gbFull()">⛶ 전체화면</button></div>' + gbSndBar() + '</div>';
  return h;
}
function tbQuit(){
  if(!confirm('모둠 골든벨을 끝낼까요? (모둠·문제·점수가 지워져요)')) return;
  gbTimerStop(); gbStopBgm(); tbClear(); renderGB();
}

/* ══ ② 문제 내기 — 학생 기기에서 받는다 ══ */
function tbToMake(again){
  if(!TB.teams.length){ toast('모둠을 먼저 짜 주세요'); return; }
  TB.phase = 'make';
  TB.code = String(1000 + Math.floor(Math.random() * 9000));
  if(again){ TB.subs = {}; }
  TB.subs = TB.subs || {};
  TB.due = 0; _tbDueRang = false;
  tbSave(); renderGB(); window.scrollTo(0, 0);
}
function tbListen(){
  if(!TB || !TB.code || TB.phase !== 'make') return;
  if(_tbCh && _tbChCode === TB.code) return;
  tbUnlisten();
  _tbChCode = TB.code;
  _tbCh = sb.channel('gbt-' + TB.code, { config:{ broadcast:{ self:false } } });
  _tbCh.on('broadcast', { event:'tb' }, function(m){ tbIn(m.payload || {}); });
  _tbLiveSt = '';
  _tbCh.subscribe(function(s){
    if(s === 'SUBSCRIBED'){ _tbLiveSt = 'on'; tbSendInfo(); }
    else if(s === 'CHANNEL_ERROR' || s === 'TIMED_OUT'){ _tbLiveSt = 'err'; }
    tbLivePaint();
  });
}
function tbUnlisten(){ if(_tbCh){ try{ sb.removeChannel(_tbCh); }catch(e){} } _tbCh = null; _tbChCode = ''; _tbLiveSt = ''; }
function tbLiveTxt(){ return _tbLiveSt === 'on' ? '● 받는 중' : _tbLiveSt === 'err' ? '● 연결 끊김 — 새로고침해 주세요' : '● 연결 중'; }
function tbLivePaint(){ var el = $('tbLive'); if(el){ el.textContent = tbLiveTxt(); el.className = 'tb-live' + (_tbLiveSt === 'on' ? ' on' : ''); } }
function tbSend(p){ try{ if(_tbCh) _tbCh.send({ type:'broadcast', event:'tb', payload:p }); }catch(e){} }
/* 학생 기기에 보내는 것 — 모둠 번호·이모지·출석 번호·냈는지만(이름 없음) */
function tbInfo(){
  return { k:'info', open: !!(TB && TB.phase === 'make'), cls: TB ? TB.g + '-' + TB.c : '', hw: gbHW() ? 1 : 0,
           due: TB && TB.due ? TB.due - Date.now() : 0,
           teams: TB ? TB.teams.map(function(t){
             return { no:t.no, emo:tbEmo(t.no - 1),
                      nums: t.ids.map(function(id){ return (tbStu(id) || {}).number; }).filter(Boolean),
                      done: TB.subs && TB.subs[t.no] ? 1 : 0 };
           }) : [] };
}
function tbSendInfo(){ tbSend(tbInfo()); }
function tbCleanQ(q){
  if(!q || typeof q !== 'object') return null;
  var t = q.t, text = String(q.q || '').trim().slice(0, 150), a = String(q.a || '').trim().slice(0, 60), o = null, ch, n;
  if(!text || !a) return null;
  if(t === 'ox'){ a = /^[oO○ㅇ]/.test(a) ? 'O' : /^[xX×✕]/.test(a) ? 'X' : ''; if(!a) return null; o = { t:'ox', q:text, a:a }; }
  else if(t === 'mc'){
    ch = (q.ch instanceof Array ? q.ch : []).map(function(c){ return String(c || '').trim().slice(0, 60); }).filter(Boolean).slice(0, 4);
    if(ch.length < 2) return null;
    n = gbNumOf(a); if(!n || n > ch.length) return null;
    o = { t:'mc', q:text, a:GB_CIRC[n - 1], ch:ch };
  }
  else o = { t:'short', q:text, a:a };
  var ex = String(q.ex || '').trim().slice(0, 100);
  if(ex) o.ex = ex;
  return o;
}
function tbIn(p){
  if(!TB) return;
  if(p.k === 'hello'){ tbSendInfo(); return; }
  if(p.k !== 'sub' || !p.dev) return;
  var ack = function(ok, msg, extra){ var o = { k:'ack', dev:p.dev, ok:ok ? 1 : 0, msg:msg || '' }, k; if(extra) for(k in extra) o[k] = extra[k]; tbSend(o); };
  if(TB.phase !== 'make'){ ack(false, '출제 시간이 끝났어요 — 이제 전자칠판을 보세요!'); return; }
  var no = +p.team, t = tbTeam(no);
  if(!t){ ack(false, '모둠 번호를 다시 골라 주세요'); return; }
  var q = tbCleanQ(p.q);
  if(!q){ ack(false, '문제와 정답을 모두 채워 주세요'); return; }
  var old = TB.subs[no];
  if(old && old.dev && old.dev !== 'teacher' && old.dev !== p.dev && !old.unlock){
    ack(false, '이 모둠 문제는 다른 기기에서 이미 냈어요. 고치려면 그 기기로 보내 주세요(선생님이 잠금을 풀 수 있어요).');
    return;
  }
  q.dev = p.dev; q.at = Date.now(); q.n = old ? (old.n || 1) + 1 : 1;
  TB.subs[no] = q; tbSave();
  ack(true, '', { team:no, n:q.n });
  gbSyn('pop'); toast('📨 ' + tbName(t) + (q.n > 1 ? ' 문제를 고쳐 보냈어요' : ' 문제 도착!'));
  tbSendInfo();
  gbRerender();
}
function tbQRDraw(){ var el = $('tbQR'); if(el && !el.querySelector('svg')) gbQR(el, tbUrl(TB.code)); }
function tbSetDue(min){
  TB.due = min ? Date.now() + min * 60000 : 0; _tbDueRang = false;
  tbSave(); tbSendInfo(); renderGB();
  if(min) gbSyn('go');
}
function tbDueRun(){
  clearInterval(_tbDueIv);
  if(!TB || TB.phase !== 'make' || !TB.due) return;
  var tick = function(){
    var el = $('tbDue'), bar = $('tbDueBar');
    if(!TB || TB.phase !== 'make' || !TB.due || !el){ clearInterval(_tbDueIv); return; }
    var left = Math.max(0, TB.due - Date.now()), s = Math.ceil(left / 1000);
    el.textContent = Math.floor(s / 60) + ':' + ('0' + (s % 60)).slice(-2);
    el.className = 'tb-due' + (s <= 30 ? ' warn' : '');
    if(bar && TB.dueMin) bar.style.width = (left / (TB.dueMin * 60000) * 100) + '%';
    if(left <= 0 && !_tbDueRang){ _tbDueRang = true; gbSyn('buzz'); toast('⏰ 출제 시간 끝!'); tbSendInfo(); }
  };
  tick(); _tbDueIv = setInterval(tick, 500);
}
function tbMakeUI(){
  var subs = TB.subs || {}, done = TB.teams.filter(function(t){ return subs[t.no]; }).length, h;
  h = '<div class="gbs tb-make">' + (gbHW() ? gbHWDeco() : '') +
      '<div class="gbs-top"><span>' + TB.g + '학년 ' + TB.c + '반 · 👥 모둠 골든벨</span><span class="tb-live' + (_tbLiveSt === 'on' ? ' on' : '') + '" id="tbLive">' + tbLiveTxt() + '</span></div>' +
      '<div class="gbs-no">모둠마다 문제 하나!</div>' +
      '<div class="tb-join"><div class="qr" id="tbQR"><span>QR 만드는 중…</span></div>' +
      '<div class="tx"><div class="l">휴대폰·크롬북으로 QR을 찍거나 주소창에</div><div class="u">' + esc(tbShortUrl()) + '</div>' +
      '<div class="l" style="margin-top:10px">방 번호</div><div class="code">' + TB.code + '</div></div></div>';
  if(TB.due){
    TB.dueMin = TB.dueMin || 5;
    h += '<div class="gbs-tm"><div class="gbs-tb"><i id="tbDueBar"></i></div><div class="tb-due" id="tbDue">' + '' + '</div></div>';
  }
  h += '<div class="gbs-btns">' + [3,5,7,10].map(function(m){
         return '<button class="gbs-b" onclick="TB.dueMin=' + m + ';tbSetDue(' + m + ')">⏱ ' + m + '분</button>';
       }).join('') + (TB.due ? '<button class="gbs-b" onclick="tbSetDue(0)">타이머 끄기</button>' : '') + '</div>' +
       '<div class="tb-tips"><b>좋은 문제는</b> 답이 하나로 정해지고 · 10초 안에 종이에 쓸 수 있고 · 우리가 배운 내용이고 · 다른 모둠 절반쯤 맞힐 만한 문제예요 (그래야 <b>보너스 +1</b>)</div></div>';
  h += '<div class="card"><div class="hd"><h3 style="font-size:var(--fs-s)">📨 도착한 문제 ' + done + ' / ' + TB.teams.length + '</h3>' +
       '<span class="sub">문제 내용은 시작할 때까지 비밀이에요</span></div><div class="tb-stat">' +
       TB.teams.map(function(t){
         var s = subs[t.no];
         return '<div class="tb-st' + (s ? ' ok' : '') + '"><div class="nm">' + tbName(t) + '</div>' +
                '<div class="st">' + (s ? '✅ 도착 ' + gbTypeTag(s) + (s.n > 1 ? ' <span class="gbtag">' + s.n + '번째 판</span>' : '') + (s.dev === 'teacher' ? ' <span class="gbtag">선생님 입력</span>' : '') : '⏳ 만드는 중') + '</div>' +
                '<div class="bt">' + (s ? '<button class="gbmini" onclick="tbPeek(' + t.no + ')">👁</button>' : '') +
                '<button class="gbmini" onclick="tbWrite(' + t.no + ')">✏️ 대신 쓰기</button>' +
                (s && s.dev !== 'teacher' && !s.unlock ? '<button class="gbmini" title="다른 기기에서도 고칠 수 있게" onclick="tbUnlock(' + t.no + ')">🔓</button>' : '') +
                (s ? '<button class="gbmini" onclick="tbDelSub(' + t.no + ')">✕</button>' : '') + '</div></div>';
       }).join('') + '</div>' +
       '<button class="btn g" style="margin-top:13px' + (done < 2 ? ';opacity:.5' : '') + '" onclick="tbStart()"' + (done < 2 ? ' disabled' : '') + '>🔔 모둠 골든벨 시작 (' + done + '문제)</button>' +
       '<div style="display:flex;gap:8px;margin-top:9px"><button class="chip sm" style="flex:1" onclick="tbBackTeams()">← 모둠 다시 짜기</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbQuit()">그만두기</button>' +
       '<button class="chip sm" style="flex:1" onclick="gbFull()">⛶ 전체화면</button></div>' + gbSndBar() + '</div>';
  h += '<div class="card">' + tbHowCard(false) + '</div>';
  return h;
}
function tbBackTeams(){
  if(Object.keys(TB.subs || {}).length && !confirm('모둠을 다시 짜면 도착한 문제가 지워져요. 괜찮을까요?')) return;
  tbSend({ k:'info', open:false, teams:[], cls:'' }); tbUnlisten();
  TB.phase = 'teams'; TB.subs = {}; TB.due = 0; tbSave(); renderGB();
}
function tbUnlock(no){ var s = TB.subs[no]; if(!s) return; s.unlock = 1; tbSave(); toast('🔓 이제 다른 기기에서도 고칠 수 있어요'); renderGB(); }
function tbDelSub(no){ if(!confirm(no + '모둠 문제를 지울까요?')) return; delete TB.subs[no]; tbSave(); tbSendInfo(); renderGB(); }
function tbPeek(no){
  var s = TB.subs[no], t = tbTeam(no); if(!s || !t) return;
  var ai = gbAnsIx(s);
  $('mdlIn').innerHTML = '<h3 style="font-size:var(--fs-m);font-weight:900">👁 ' + tbName(t) + ' 문제</h3>' +
    '<div class="sub" style="margin:4px 0 10px;color:var(--bad)">학생들이 화면을 보고 있으면 문제가 들켜요!</div>' +
    '<div style="font-size:15px;font-weight:800;line-height:1.5">' + gbTypeTag(s) + ' ' + esc(s.q) + '</div>' +
    (s.ch ? '<div class="sub" style="margin-top:6px">' + s.ch.map(function(c, i){ return GB_CIRC[i] + ' ' + esc(c); }).join('<br>') + '</div>' : '') +
    '<div style="margin-top:10px;font-weight:900;color:var(--ok-d)">정답: ' + esc(s.a) + (ai >= 0 && s.ch[ai] ? ' ' + esc(s.ch[ai]) : '') + '</div>' +
    (s.ex ? '<div class="sub" style="margin-top:4px">' + esc(s.ex) + '</div>' : '') +
    '<div style="display:flex;gap:8px;margin-top:14px"><button class="btn" style="flex:1;background:var(--line);color:var(--ink)" onclick="closeMdl()">닫기</button>' +
    '<button class="btn g" style="flex:1" onclick="closeMdl();tbWrite(' + no + ')">✏️ 고치기</button></div>';
  $('mdl').classList.add('show');
}
/* 종이로 받은 문제를 선생님이 대신 넣거나, 학생이 낸 문제를 손본다 */
var _tbWT = 'short';
function tbWrite(no){
  var t = tbTeam(no), s = TB.subs[no];
  if(!t) return;
  _tbWT = s ? s.t : _tbWT;
  tbWriteDraw(no, s ? { q:s.q, a:s.a, c:(s.ch || []).join('\n'), e:s.ex || '' } : null);
  $('mdl').classList.add('show');
}
function tbWriteDraw(no, d){
  var t = tbTeam(no), ty = _tbWT;
  d = d || { q:'', a:'', c:'', e:'' };
  $('mdlIn').innerHTML = '<h3 style="font-size:var(--fs-m);font-weight:900">✏️ ' + tbName(t) + ' 문제 넣기</h3>' +
    '<div class="chips" style="margin:10px 0 8px">' + [['short','단답'], ['ox','O/X'], ['mc','객관식']].map(function(m){
      return '<button class="chip sm' + (ty === m[0] ? ' on' : '') + '" onclick="tbWType(' + no + ',\'' + m[0] + '\')">' + m[1] + '</button>';
    }).join('') + '</div>' +
    '<textarea class="inp" id="tbwQ" rows="3" placeholder="문제">' + esc(d.q) + '</textarea>' +
    (ty === 'mc' ? '<textarea class="inp" id="tbwC" rows="4" style="margin-top:7px" placeholder="보기를 한 줄에 하나씩 (2~4개)">' + esc(d.c) + '</textarea>' : '') +
    '<input class="inp" id="tbwA" style="margin-top:7px" placeholder="' + (ty === 'ox' ? '정답: O 또는 X' : ty === 'mc' ? '정답 번호 (예: 2)' : '정답') + '" value="' + escq(d.a) + '">' +
    '<input class="inp" id="tbwE" style="margin-top:7px" placeholder="해설 한 줄 (선택)" value="' + escq(d.e) + '">' +
    '<div style="display:flex;gap:8px;margin-top:12px"><button class="btn" style="flex:1;background:var(--line);color:var(--ink)" onclick="closeMdl()">취소</button>' +
    '<button class="btn g" style="flex:1" onclick="tbWriteSave(' + no + ')">✔ 넣기</button></div>';
}
function tbWType(no, ty){
  var d = { q:($('tbwQ') || {}).value || '', a:($('tbwA') || {}).value || '', c:($('tbwC') || {}).value || '', e:($('tbwE') || {}).value || '' };
  _tbWT = ty; tbWriteDraw(no, d);
}
function tbWriteSave(no){
  var raw = { t:_tbWT, q:$('tbwQ').value, a:$('tbwA').value, ex:$('tbwE').value,
              ch:$('tbwC') ? $('tbwC').value.split('\n').map(function(s){ return s.replace(/^\s*[①-④0-9]+[.)]?\s*/, ''); }) : null };
  var q = tbCleanQ(raw);
  if(!q){ toast(_tbWT === 'mc' ? '문제·보기 2개 이상·정답 번호를 채워 주세요' : _tbWT === 'ox' ? '문제와 정답(O 또는 X)을 채워 주세요' : '문제와 정답을 채워 주세요'); return; }
  var old = TB.subs[no];
  q.dev = 'teacher'; q.at = Date.now(); q.n = old ? (old.n || 1) + 1 : 1;
  TB.subs[no] = q; tbSave(); closeMdl(); tbSendInfo(); renderGB();
  toast('✔ ' + no + '모둠 문제를 넣었어요');
}

/* ══ ③ 모둠 골든벨 진행 ══ */
function tbStart(){
  var nos = Object.keys(TB.subs || {}).map(Number).filter(function(no){ return tbTeam(no); });
  if(nos.length < 2){ toast('문제가 두 개 이상 모여야 시작할 수 있어요'); return; }
  TB.order = gbShuffle(nos); TB.qi = 0; TB.rev = 0; TB.cor = {}; TB.hist = []; TB.awarded = {};
  TB.teams.forEach(function(t){ t.score = 0; t.bonus = 0; });
  TB.phase = 'play'; TB.due = 0;
  tbSave();
  tbSend({ k:'info', open:false, teams:[], cls:TB.g + '-' + TB.c });   /* 학생 기기에 «출제 끝» */
  setTimeout(tbUnlisten, 1500);
  gbTimerStop(); gbPlayBgm(); renderGB(); window.scrollTo(0, 0);
}
function tbCurQ(){
  if(!TB || !TB.order) return null;
  var no = TB.order[TB.qi], s = TB.subs[no], t = tbTeam(no);
  if(!s || !t) return null;
  var q = { t:s.t, q:s.q, a:s.a, src:tbName(t) + ' 출제' };
  if(s.ch) q.ch = s.ch;
  if(s.ex) q.ex = s.ex;
  return q;
}
function tbDots(){
  var h = '<span class="gbs-dots">', i;
  for(i=0;i<TB.order.length;i++) h += '<i class="' + (i < TB.qi ? 'd' : i === TB.qi ? 'c' : '') + '"></i>';
  return h + '</span>';
}
function tbTap(no){
  if(!gbTeamPlaying() || no === TB.order[TB.qi]) return;
  if(TB.cor[no]) delete TB.cor[no]; else { TB.cor[no] = 1; gbSyn('pop'); }
  tbSave(); renderGB();
}
function tbReveal(){ if(!gbTeamPlaying() || TB.rev) return; TB.rev = 1; gbTimerStop(); tbSave(); gbSyn('ding'); renderGB(); }
function tbNext(){
  if(!gbTeamPlaying()) return;
  var author = TB.order[TB.qi], ans = TB.teams.filter(function(t){ return t.no !== author; });
  var cor = ans.filter(function(t){ return TB.cor[t.no]; }).map(function(t){ return t.no; });
  var bonus = cor.length > 0 && cor.length < ans.length;
  TB.hist.push({ a:author, cor:cor, b:bonus ? 1 : 0, n:ans.length });
  cor.forEach(function(no){ tbTeam(no).score++; });
  if(bonus) tbTeam(author).bonus++;
  TB.qi++; TB.rev = 0; TB.cor = {};
  gbTimerStop();
  if(TB.qi >= TB.order.length){ TB.phase = 'done'; gbStopBgm(); gbSfx('fanfare'); }
  else gbSfx('write');
  tbSave(); renderGB(); window.scrollTo(0, 0);
  if(bonus) toast('💡 ' + tbName(tbTeam(author)) + ' 좋은 문제 보너스 +1');
}
/* 한 문제 되돌리기 — 점수도 같이 되돌린다 */
function tbBack(){
  if(!TB || !TB.hist || !TB.hist.length) return;
  var h = TB.hist.pop();
  h.cor.forEach(function(no){ var t = tbTeam(no); if(t) t.score--; });
  if(h.b){ var a = tbTeam(h.a); if(a) a.bonus--; }
  TB.qi--; TB.rev = 1; TB.cor = {};
  h.cor.forEach(function(no){ TB.cor[no] = 1; });
  if(TB.phase === 'done'){ TB.phase = 'play'; gbPlayBgm(); }
  gbTimerStop(); tbSave(); renderGB();
}
function tbRestart(){
  if(!confirm('점수를 0으로 하고 첫 문제부터 다시 할까요?')) return;
  TB.qi = 0; TB.rev = 0; TB.cor = {}; TB.hist = [];
  TB.teams.forEach(function(t){ t.score = 0; t.bonus = 0; });
  TB.phase = 'play'; tbSave(); gbTimerStop(); renderGB();
}
function tbScoreboard(hi){
  var max = Math.max.apply(null, TB.teams.map(tbTotal).concat([1]));
  return '<div class="tb-sb">' + TB.teams.map(function(t){
    var v = tbTotal(t);
    return '<div class="tb-sr' + (hi && hi === t.no ? ' au' : '') + '"><b class="nm">' + tbName(t) + '</b>' +
           '<span class="bar"><i style="width:' + Math.round(v / max * 100) + '%"></i></span>' +
           '<b class="v">' + v + '</b><span class="sub">' + (t.bonus ? '맞힘 ' + t.score + ' · 💡' + t.bonus : '') + '</span></div>';
  }).join('') + '</div>';
}
function tbPlayUI(){
  var author = TB.order[TB.qi], q = tbCurQ(), tl = gbTL(), at = tbTeam(author);
  var corN = Object.keys(TB.cor).length, tOn = _gbT && _gbT.key === gbTKey(), h;
  h = gbStage(q, { rv:false, rev:TB.rev, no:TB.qi + 1, cls:TB.g + '학년 ' + TB.c + '반 · 👥 모둠 골든벨', dots:tbDots(), aliveLab:'맞힘', alive:corN, unit:'모둠',
    btns: (tl && !TB.rev ? '<button class="gbs-b" id="gbTBtn" onclick="gbTimerBtn()">' + (tOn ? (_gbT.done ? '⏱ 시간 끝' : '⏹ 그만 (스페이스)') : '⏱ ' + tl + '초 시작') + '</button>' : '') +
          (q && !TB.rev ? '<button class="gbs-b y" onclick="tbReveal()">👀 정답 공개</button>' : '') +
          '<button class="gbs-b' + (TB.rev ? ' y' : '') + '" onclick="tbNext()">' + (TB.qi + 1 >= TB.order.length ? '🏁 점수 주고 결과 보기' : '점수 주고 다음 →') + '</button>',
    kbd: '맞힌 모둠은 아래에서 누르거나 숫자 키 · 스페이스 = ' + (tl ? '타이머 → ' : '') + '정답 공개 → 점수 주고 다음 · ← 앞 문제 · F 전체화면' });
  h += '<div class="card"><div class="hd"><h3 style="font-size:var(--fs-s)"><b style="color:var(--ok-d)">맞힌 모둠</b>을 누르세요</h3>' +
       '<span class="sub">' + (at ? tbName(at) + '은 출제 모둠이라 쉬어요' : '') + '</span></div><div class="tbt-grid">' +
       TB.teams.map(function(t){
         if(t.no === author) return '<button class="tbt au" disabled><span class="e">✍️</span>' + tbName(t) + '<small>출제 모둠 · 쉬어요</small></button>';
         var on = !!TB.cor[t.no];
         return '<button class="tbt' + (on ? ' on' : '') + '" onclick="tbTap(' + t.no + ')"><span class="e">' + (on ? '✅' : tbEmo(t.no - 1)) + '</span>' +
                t.no + '모둠<small>' + (on ? '맞힘 +1' : t.ids.length + '명') + '</small></button>';
       }).join('') + '</div></div>';
  h += '<div class="card"><h3 style="font-size:var(--fs-s)">📊 점수</h3><div class="sub" style="margin-bottom:8px">맞힌 문제 + 💡 좋은 문제 보너스</div>' + tbScoreboard(author) + '</div>';
  h += '<div class="card"><div style="display:flex;gap:7px">' +
       '<button class="chip" style="flex:1;padding:11px 0" onclick="gbSfx(\'write\')">✍️ 정답을 써주세요</button>' +
       '<button class="chip" style="flex:1;padding:11px 0" onclick="gbSfx(\'show\')">🙌 정답을 들어주세요</button></div>' + gbSndBar() +
       '<div class="gbsec"><div class="k">⏱ 문제마다 제한 시간</div><div class="chips">' +
       [0,20,30,60,90].map(function(n){ return '<button class="chip sm' + (tl === n ? ' on' : '') + '" onclick="gbSetTL(' + n + ')">' + (n ? n + '초' : '없음') + '</button>'; }).join('') +
       '</div></div>' +
       '<div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:12px">' +
       '<button class="chip sm" style="flex:1" onclick="tbBack()"' + (TB.hist.length ? '' : ' disabled') + '>↩ 앞 문제로</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbRestart()">처음부터</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbQuit()">그만두기</button>' +
       '<button class="chip sm" style="flex:1" onclick="gbFull()">⛶ 전체화면</button></div></div>';
  return h;
}

/* ══ ④ 결과 ══ */
function tbWinners(){
  var max = Math.max.apply(null, TB.teams.map(tbTotal));
  return TB.teams.filter(function(t){ return tbTotal(t) === max; });
}
/* 베스트 문제 = 맞힌 비율이 절반에 가장 가까운 문제(모두 맞히거나 모두 틀린 문제는 빼고) */
function tbBest(){
  var best = null, bd = 9;
  (TB.hist || []).forEach(function(h, i){
    if(!h.n || !h.cor.length || h.cor.length >= h.n) return;
    var d = Math.abs(h.cor.length / h.n - 0.5);
    if(d < bd - 1e-9){ bd = d; best = { i:i, h:h }; }
  });
  return best;
}
function tbShort(s, n){ s = String(s || ''); return s.length > n ? s.slice(0, n) + '…' : s; }
function tbDoneUI(){
  var w = tbWinners(), best = tbBest(), rank = TB.teams.slice().sort(function(a, b){ return tbTotal(b) - tbTotal(a) || a.no - b.no; });
  var pod = [rank[1], rank[0], rank[2]], h;
  h = '<div class="gbs tb-res">' + (gbHW() ? gbHWDeco() : '') +
      '<div class="gbs-top"><span>' + TB.g + '학년 ' + TB.c + '반 · 👥 모둠 골든벨</span><span>' + TB.order.length + '문제</span></div>' +
      '<div class="gbs-no">🏆 ' + w.map(tbName).join(' · ') + (w.length > 1 ? ' 공동 우승!' : ' 우승!') + '</div>' +
      '<div class="gbh-pod">' + pod.map(function(t, k){
        if(!t) return '<div class="gbh-p ghost"></div>';
        var place = 1 + rank.filter(function(x){ return tbTotal(x) > tbTotal(t); }).length;
        return '<div class="gbh-p p' + Math.min(3, place) + '"><div class="m">' + (['🥇','🥈','🥉'][place - 1] || '🎖️') + '</div>' +
               '<div class="c">' + tbEmo(t.no - 1) + ' ' + t.no + '모둠</div><div class="v">' + tbTotal(t) + '점</div>' +
               '<div class="n">맞힘 ' + t.score + (t.bonus ? ' · 💡' + t.bonus : '') + '</div><div class="b"></div></div>';
      }).join('') + '</div></div>';

  h += '<div class="card"><h3 style="font-size:var(--fs-s)">🏆 우승 모둠</h3>' +
       w.map(function(t){ return '<div class="sub" style="margin-top:6px"><b>' + tbName(t) + '</b> — ' + t.ids.map(function(id){ return esc(tbLabel(id)); }).join(' · ') + '</div>'; }).join('') +
       '<button class="btn g" style="margin-top:12px' + (TB.awarded && TB.awarded.win ? ';opacity:.5' : '') + '" onclick="tbAward(\'win\')"' + (TB.awarded && TB.awarded.win ? ' disabled' : '') + '>' +
       (TB.awarded && TB.awarded.win ? '✔ 도장을 찍었어요' : '🏅 우승 모둠 ' + w.reduce(function(n, t){ return n + t.ids.length; }, 0) + '명에게 도장 찍기') + '</button></div>';

  if(best){
    var bs = TB.subs[best.h.a], bt = tbTeam(best.h.a);
    h += '<div class="card tb-best"><h3 style="font-size:var(--fs-s)">💡 베스트 문제 — ' + (bt ? tbName(bt) : '') + '</h3>' +
         '<div class="q">' + gbTypeTag(bs) + ' ' + esc(bs ? bs.q : '') + '</div>' +
         '<div class="sub">' + best.h.n + '모둠 중 ' + best.h.cor.length + '모둠이 맞혔어요 — 맞힌 모둠과 틀린 모둠이 가장 고르게 갈린 문제</div>' +
         (bt ? '<div class="sub" style="margin-top:6px">' + bt.ids.map(function(id){ return esc(tbLabel(id)); }).join(' · ') + '</div>' : '') +
         '<button class="btn g" style="margin-top:12px' + (TB.awarded && TB.awarded.best ? ';opacity:.5' : '') + '" onclick="tbAward(\'best\')"' + (TB.awarded && TB.awarded.best ? ' disabled' : '') + '>' +
         (TB.awarded && TB.awarded.best ? '✔ 도장을 찍었어요' : '🏅 베스트 문제 모둠 ' + (bt ? bt.ids.length : 0) + '명에게 도장 찍기') + '</button></div>';
  }

  h += '<div class="card"><h3 style="font-size:var(--fs-s)">📋 문제별 결과</h3><div style="margin-top:6px">' +
       (TB.hist || []).map(function(x, i){
         var s = TB.subs[x.a], t = tbTeam(x.a);
         return '<div class="tb-qr"><b class="n">' + (i + 1) + '</b><span class="tx"><span class="src">' + (t ? tbName(t) : '') + ' 출제</span>' + esc(s ? s.q : '') +
                (s ? ' <b style="color:var(--ok-d)">→ ' + esc(s.a) + '</b>' : '') + '</span>' +
                '<b class="r">' + x.cor.length + '/' + x.n + (x.b ? ' 💡' : '') + '</b></div>';
       }).join('') + '</div>' +
       '<button class="chip" style="margin-top:10px" onclick="tbToMine()">⭐ 모둠 문제 ' + (TB.hist || []).length + '개를 내 문제에 담기</button></div>';

  h += '<div class="card"><h3 style="font-size:var(--fs-s)">📊 점수</h3>' + tbScoreboard(0) + '</div>';
  h += '<div class="card"><div style="display:flex;gap:8px;flex-wrap:wrap">' +
       '<button class="chip sm" style="flex:1" onclick="tbBack()">↩ 마지막 문제로</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbAgain()">🔁 같은 모둠으로 한 판 더</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbNewTeams()">🎲 모둠 새로 짜기</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbQuit()">끝내기</button></div>' + gbSndBar(true) + '</div>';
  return h;
}
function tbAgain(){ if(!confirm('같은 모둠으로 문제를 새로 받을까요? (점수는 0부터)')) return; TB.teams.forEach(function(t){ t.score = 0; t.bonus = 0; }); tbToMake(true); }
function tbNewTeams(){ if(!confirm('모둠을 새로 짤까요? (이번 판 점수·문제는 지워져요)')) return; TB.phase = 'teams'; TB.subs = {}; TB.hist = []; tbSave(); tbShuffle(true); }
function tbToMine(){
  var mine = gbmyAll(), seen = {}, add = 0, day = todayStr().slice(5).replace('-', '/');
  mine.forEach(function(q){ seen[q.q] = 1; });
  (TB.hist || []).forEach(function(x){
    var s = TB.subs[x.a]; if(!s || seen[s.q]) return;
    var it = { id:'my-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 5), t:s.t, q:s.q, a:s.a,
               src:'👥 ' + TB.g + '-' + TB.c + ' ' + x.a + '모둠 출제 (' + day + ')', g:TB.g };
    if(s.ch) it.ch = s.ch.slice();
    if(s.ex) it.ex = s.ex;
    mine.push(it); seen[s.q] = 1; add++;
  });
  gbmySave(mine);
  toast(add ? '⭐ 모둠 문제 ' + add + '개를 내 문제에 담았어요 — ✋ 골라서 출제에서 꺼내 쓸 수 있어요' : '이미 다 담겨 있어요');
}
/* 도장 — 행동 문장은 세특 근거라 «무엇을 했는지»를 그대로 적는다 */
async function tbAward(kind){
  var ids, beh, cat, w, best, bt, bs;
  if(kind === 'win'){
    w = tbWinners();
    ids = [].concat.apply([], w.map(function(t){ return t.ids; }));
    cat = 'collaborate';
    beh = '모둠 골든벨에서 모둠원과 협력하여 다른 모둠이 만든 문제를 풀고 ' + (w.length > 1 ? '공동 우승함' : '우승함');
  } else {
    best = tbBest(); if(!best) return;
    bt = tbTeam(best.h.a); bs = TB.subs[best.h.a]; if(!bt || !bs) return;
    ids = bt.ids.slice();
    cat = 'concept';
    beh = '모둠 골든벨에서 모둠원과 함께 «' + tbShort(bs.q, 40) + '» 문제를 만들어 출제했고, 가장 변별력 있는 문제로 뽑힘';
  }
  if(!ids.length){ toast('줄 사람이 없어요'); return; }
  if(!confirm(ids.length + '명에게 도장을 찍을까요?\n\n«' + beh + '»')) return;
  showLoad();
  try{
    var note = S.selPlan ? planNote(S.selPlan) : null, say = S.selPlan ? planConcept(S.selPlan) : null, today = todayStr(), rows = [], i, s;
    if(say) beh = say + ' — ' + beh;
    for(i=0;i<ids.length;i++){
      s = tbStu(ids[i]) || {};
      rows.push({ student_id:ids[i], school_year:nowYear(), semester:nowSem(),
                  class_no_snap:s.class_no || TB.c || null, number_snap:s.number || null,
                  category:cat, behavior:beh, lesson_note: note ? note + ' · 모둠 골든벨' : '모둠 골든벨', observed_on:today });
    }
    var r = await sb.from('observations').insert(rows).select('id');
    if(r.error){ toast('저장에 실패했어요 — ' + (r.error.message || r.error.code || '')); console.error('[모둠 골든벨 도장]', r.error, rows); return; }
    var saved = (r.data || []).length;
    if(saved !== rows.length) alert('⚠️ ' + rows.length + '명에게 찍으려 했는데 ' + saved + '명만 저장됐어요.\n「👥 학생」 탭에서 확인해 주세요.');
    TB.awarded = TB.awarded || {}; TB.awarded[kind] = 1; tbSave();
    if(!_gbAwardKey) gbAwardPlay('award');
    await loadTeacherObs();
    toast('🏅 ' + saved + '명에게 도장을 찍었어요!');
    renderGB();
  } finally { hideLoad(); }
}

/* ══ 본체와 잇기 — 타이머 열쇠·정답 공개 여부·단축키 ══ */
var _tbTKey0 = gbTKey, _tbRevNow0 = gbRevNow, _tbTimerStart0 = gbTimerStart;
gbTKey = function(){ return gbTeamPlaying() ? 'tb' + TB.qi : _tbTKey0(); };
gbRevNow = function(){ return gbTeamPlaying() ? !!TB.rev : _tbRevNow0(); };
gbTimerStart = function(){
  if(!gbTeamPlaying()) return _tbTimerStart0();
  var tl = gbTL(); if(!tl || TB.rev) return;
  gbTimerStop();
  _gbT = { key:gbTKey(), end:Date.now() + tl * 1000, done:false, last:tl };
  gbSyn('go');
  _gbT.iv = setInterval(gbTimerTick, 100);
  gbTimerTick();
  var b = $('gbTBtn'); if(b) b.textContent = '⏹ 그만 (스페이스)';
};
function gbTeamKey(e){
  if(!gbTeamPlaying()) return;
  var mine = _gbT && _gbT.key === gbTKey(), tl = gbTL(), n;
  if(e.code === 'Space'){
    e.preventDefault();
    if(!TB.rev && tl && !mine){ gbTimerStart(); return; }
    if(!TB.rev && mine && !_gbT.done){ _gbT.end = Date.now(); gbTimerTick(); return; }
    if(!TB.rev){ tbReveal(); return; }
    tbNext();
  }
  else if(e.key === 'ArrowLeft'){ e.preventDefault(); tbBack(); }
  else if(e.key === 'ArrowRight'){ e.preventDefault(); tbNext(); }
  else if(e.code === 'KeyF') gbFull();
  else if(e.code === 'KeyR') tbReveal();
  else if(e.code === 'KeyT') gbTimerBtn();
  else if(/^Digit[0-9]$/.test(e.code)){ n = +e.code.slice(5); if(n === 0) n = 10; tbTap(n); }
}

/* 모둠 화면 꾸밈 */
(function(){
  var css = [
    '.gbmode{margin-bottom:12px;background:var(--card);border:2px solid var(--line)}',
    '.tb-how{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:6px;margin-top:10px}',
    '.tb-how div{background:#fff;border:2px solid var(--line);border-radius:12px;padding:9px 6px;text-align:center;font-size:12px;font-weight:800;line-height:1.35}',
    '.tb-how b{display:block;width:20px;height:20px;margin:0 auto 4px;border-radius:50%;background:var(--ac);color:#fff;font-size:11px;line-height:20px}',
    '.tb-cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(170px,1fr));gap:10px;margin-top:14px}',
    '.tb-card{border:2px solid var(--line);border-radius:16px;background:#fff;padding:10px}',
    '.tb-cards.spin .tb-card{animation:tbjig .12s linear infinite alternate}',
    '@keyframes tbjig{to{transform:translateY(-2px) rotate(.6deg)}}',
    '.tb-h{display:flex;justify-content:space-between;align-items:center;font-size:var(--fs-s);font-weight:900;margin-bottom:7px}',
    '.tb-h span{font-size:11px;color:var(--mute)}',
    '.tb-mem{display:flex;flex-wrap:wrap;gap:5px}',
    '.tb-mem button{padding:6px 9px;border-radius:999px;border:2px solid var(--line);background:var(--paper);font-size:12.5px;font-weight:800}',
    '.tb-mem button.sel{border-color:var(--ac);background:var(--ac);color:#fff}',
    '.tb-make .gbs-no{font-size:clamp(24px,3.6vw,48px)}',
    '.tb-join{display:flex;gap:clamp(14px,3vw,40px);align-items:center;justify-content:center;flex-wrap:wrap;margin:14px auto 4px}',
    '.tb-join .qr{width:clamp(150px,18vw,230px);aspect-ratio:1/1;background:#fff;border-radius:16px;padding:8px;display:grid;place-items:center;color:#333;font-size:12px}',
    '.tb-join .qr svg{width:100%;height:100%}',
    '.tb-join .tx{text-align:left}',
    '.tb-join .l{font-size:clamp(13px,1.4vw,18px);font-weight:800;color:#cdd6ff}',
    '.tb-join .u{font-size:clamp(15px,2vw,26px);font-weight:900;word-break:break-all}',
    '.tb-join .code{font-size:clamp(46px,8vw,110px);font-weight:900;letter-spacing:.12em;line-height:1;color:#ffd666;text-shadow:0 0 26px rgba(255,214,102,.45);font-variant-numeric:tabular-nums}',
    'body.gbhw .tb-join .code{color:#ffb347}',
    '.tb-live{font-size:12px;font-weight:800;color:#ff9a9a}',
    '.tb-live.on{color:#86e698}',
    '.tb-due{min-width:3.2em;text-align:right;font-size:clamp(26px,3.4vw,46px);font-weight:900;font-variant-numeric:tabular-nums}',
    '.tb-due.warn{color:#ff8a5c;animation:gbblink .5s infinite alternate}',
    '.tb-tips{max-width:900px;margin:14px auto 0;font-size:clamp(12.5px,1.4vw,17px);font-weight:700;color:#dfe5ff;text-align:center;line-height:1.6}',
    '.tb-tips b{color:#ffd666}',
    '.tb-stat{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:8px}',
    '.tb-st{border:2px dashed var(--line);border-radius:14px;padding:10px;background:#fff}',
    '.tb-st.ok{border-style:solid;border-color:var(--ok);background:#F4FBF5}',
    '.tb-st .nm{font-weight:900;font-size:var(--fs-s)}',
    '.tb-st .st{font-size:12px;font-weight:800;color:var(--ink2);margin:4px 0 7px}',
    '.tb-st .bt{display:flex;gap:4px;flex-wrap:wrap}',
    '.tbt-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:9px}',
    '.tbt{padding:14px 6px;border-radius:16px;border:2.5px solid var(--line);background:#fff;font-size:var(--fs-m);font-weight:900;text-align:center;line-height:1.25;transition:transform .12s}',
    '.tbt:active{transform:scale(.97)}',
    '.tbt .e{display:block;font-size:clamp(26px,3vw,40px)}',
    '.tbt small{display:block;font-size:11px;font-weight:800;color:var(--mute);margin-top:3px}',
    '.tbt.on{border-color:var(--ok);background:#E8F7EC;box-shadow:0 4px 14px rgba(92,184,110,.3)}',
    '.tbt.on small{color:var(--ok-d)}',
    '.tbt.au{opacity:.5;border-style:dashed}',
    '.tb-sb{display:flex;flex-direction:column;gap:6px}',
    '.tb-sr{display:flex;align-items:center;gap:8px;flex-wrap:wrap}',
    '.tb-sr .nm{flex:0 0 auto;min-width:5.6em;font-size:13.5px}',
    '.tb-sr .bar{flex:1 1 120px;height:12px;border-radius:999px;background:#EFE6D2;overflow:hidden}',
    '.tb-sr .bar i{display:block;height:100%;border-radius:999px;background:linear-gradient(90deg,var(--ok),var(--warn));transition:width .5s}',
    '.tb-sr .v{flex:0 0 auto;min-width:1.8em;text-align:right;font-size:16px;color:var(--ac-d)}',
    '.tb-sr.au .nm{color:var(--ac-d)}',
    '.tb-res .gbs-no{font-size:clamp(22px,3.6vw,46px)}',
    '.tb-best{border-color:#e9b949;background:linear-gradient(135deg,#fffaf0,#fff2cf)}',
    '.tb-best .q{font-size:15px;font-weight:800;line-height:1.5;margin:6px 0}',
    '.tb-qr{display:flex;gap:8px;align-items:flex-start;padding:7px 0;border-bottom:1.5px dashed var(--line);font-size:12.5px;font-weight:700;line-height:1.45}',
    '.tb-qr .n{flex:0 0 auto;color:var(--ac-d)}',
    '.tb-qr .tx{flex:1;min-width:0;word-break:keep-all}',
    '.tb-qr .src{display:block;font-size:10.5px;color:var(--mute);font-weight:800}',
    '.tb-qr .r{flex:0 0 auto;color:var(--ok-d)}',
    '@media (max-width:520px){.tb-how{grid-template-columns:repeat(2,minmax(0,1fr))}}'
  ].join('\n');
  var st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);
})();
