/* ══════════════════════════════════════════════════════════════════════════
   👥 모둠 골든벨 (2026-10-19) — 칭찬 도장판 🔔 골든벨 탭의 두 번째 모드

   ① 모둠 짜기   📋 정해 둔 모둠(TB_FIXED, 출석 번호만) 또는 🎲 랜덤 — 결석을 빼고 고르게 나눈다
                 (두 사람을 차례로 누르면 자리 바꾸기)
   ② 문제 내기   학생 기기(team.html)가 방 번호로 들어와 모둠 문제를 몇 개든 보낸다(2026-10-29).
                 선생님이 📝 검토 창에서 ✅ 통과 / ✏️ 피드백을 보내면 그 문제를 낸 기기에 뜨고,
                 학생은 피드백을 보고 «무엇을 고쳤는지» 한 줄과 함께 고쳐 다시 보낸다.
                 Supabase 방송 채널 'gbt-<방 번호>' — 표·SQL 없음, 학생 로그인 없음.
                 학생 기기에는 이름 대신 «모둠 번호와 출석 번호», 그리고 «그 기기가 낸 문제»만 보낸다.
                 종이로 받았으면 선생님이 ✏️ 대신 쓰기.
   ③ 골든벨     시작할 때 문항 수를 정하면 모둠마다 고르게 랜덤으로 뽑는다. 맞힌 모둠 +1, 출제 모둠은 쉰다.
                 맞힌 모둠과 틀린 모둠이 둘 다 나오면 출제 모둠에 «좋은 문제 보너스» +1.
   ④ 결과       우승 모둠·💡 베스트 문제(맞힌 비율이 반에 가장 가까운 문제) → 도장, ⭐ 내 문제에 담기

   상태는 이 기기 localStorage(gb_team_v1)에만 둔다. 개인 골든벨(GB)과는 따로 굴러간다.
   문제 = TB.qs[{id, team, t, q, a, ch, ex, dev, n(몇 번째 판), st(new 검토 전·fix 고치는 중·ok 통과), fb, prev, note, used}]
   본체(index.html)와 이어지는 곳: renderGB 감싸개(모드 막대·모둠 화면), 단축키, 타이머 열쇠.
   ══════════════════════════════════════════════════════════════════════════ */
var TB_KEY = 'gb_team_v1';
var TB = null;
var TB_EMO = ['🦊','🐻','🐼','🐯','🐸','🐵','🐰','🐨','🦁','🐧'];
var TB_EMO_HW = ['🎃','👻','🦇','🕷️','🧙','🧟','💀','🍬','🕸️','🌕'];
var _tbCh = null, _tbChCode = '', _tbSel = null, _tbShufIv = 0, _tbDueIv = 0, _tbDueRang = false, _tbLiveSt = '';

/* 📋 정해 둔 모둠 — 반마다 «1모둠부터» 출석 번호로만 적는다. 이 파일은 공개되니 이름은 넣지 않고,
   이름은 도장판 명단에서 번호로 찾는다. 여기 없는 번호의 학생은 «오늘 안 함»으로 두고 눌러서 넣는다. */
var TB_FIXED = {
  '2-1':  [[1,14,15,25], [2,20,27,28], [3,9,16,24], [4,6,11,19], [5,12,13,29], [7,10,21], [18,23,26]],
  '2-11': [[1,18,21,26], [2,11,16,30], [3,8,9,12,29], [4,6,10,14,15], [5,7,19,28], [13,20,23,27], [17,22,24,25]]
};
function tbFixedOf(g, c){ return TB_FIXED[g + '-' + c] || null; }

function tbLoad(){ if(!TB){ TB = gbLsJ(TB_KEY, null); if(TB) tbMigrate(); } return TB; }
/* 10-19 판(모둠마다 문제 하나 = TB.subs{모둠: 문제})을 문제 목록 TB.qs 로 옮긴다 — 진행 중이던 판도 이어지게 */
function tbMigrate(){
  if(!TB.subs){ TB.qs = TB.qs || []; return; }
  var map = {};
  TB.qs = Object.keys(TB.subs).map(function(no){
    var s = TB.subs[no], q = {}, k;
    for(k in s) if(k !== 'unlock') q[k] = s[k];
    q.id = 'm' + no; q.team = +no; q.st = 'ok'; map[no] = q.id;
    return q;
  });
  if(TB.order) TB.order = TB.order.map(function(no){ return map[no]; }).filter(Boolean);
  (TB.hist || []).forEach(function(h){ h.qid = map[h.a]; });
  delete TB.subs; tbSave();
}
function tbQs(){ return TB.qs || (TB.qs = []); }
function tbQ(id){ var a = tbQs(), i; for(i=0;i<a.length;i++) if(a[i].id === id) return a[i]; return null; }
function tbTeamQs(no){ return tbQs().filter(function(q){ return q.team === no; }); }
/* 문제의 모양만 떼어 둔다(고치기 전 판 보관용) */
function tbQBody(q){ var o = { t:q.t, q:q.q, a:q.a }; if(q.ch) o.ch = q.ch.slice(); if(q.ex) o.ex = q.ex; return o; }
function tbQSet(dst, src){ dst.t = src.t; dst.q = src.q; dst.a = src.a; if(src.ch) dst.ch = src.ch; else delete dst.ch; if(src.ex) dst.ex = src.ex; else delete dst.ex; }
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
         '<div class="sub">모둠을 짜고(정해 둔 모둠 또는 랜덤), 모둠마다 문제를 만들어 서로 풀어요.</div>' +
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
         '<div><b>1</b>📋 모둠 짜기</div><div><b>2</b>✍️ 문제 만들기 · 💬 피드백</div><div><b>3</b>🔔 뽑아서 서로 풀기</div><div><b>4</b>🏆 우승·베스트 문제</div></div>' +
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
  TB = { g:S.selClass.grade, c:S.selClass.cls, phase:'teams', n:n, absent:{}, teams:[], qs:[], made:Date.now() };
  /* 정해 둔 모둠이 있는 반은 지난번에 고른 방법으로(처음이면 정해 둔 모둠) */
  var fx = tbFixedOf(TB.g, TB.c), how = (gbLsJ('gb_thow_v1', {}) || {})[TB.g + '-' + TB.c];
  if(fx && how !== 'rand') tbUseFixed(); else { TB.how = 'rand'; tbShuffle(true); }
}
function tbHowSave(how){ var o = gbLsJ('gb_thow_v1', {}) || {}; o[TB.g + '-' + TB.c] = how; gbLsSet('gb_thow_v1', JSON.stringify(o)); }
function tbPickHow(how){
  if(!TB || _tbShufIv) return;
  tbHowSave(how);
  if(how === 'fixed') tbUseFixed(); else { TB.how = 'rand'; tbShuffle(true); }
}
/* 📋 정해 둔 모둠대로 — 번호로 학생을 찾고, 표에 없는 학생은 «오늘 안 함»으로 둔다(오면 눌러서 넣기) */
function tbUseFixed(){
  var fx = tbFixedOf(TB.g, TB.c);
  if(!fx){ toast('이 반은 정해 둔 모둠이 없어요'); return; }
  clearInterval(_tbShufIv); _tbShufIv = 0; _tbSel = null;
  var byNo = {}, seen = {}, manual = {}, id;
  S.students.forEach(function(s){ if(s.number) byNo[+s.number] = s.id; });
  for(id in (TB.absent || {})) if(TB.absent[id] === 1) manual[id] = 1;   /* 손으로 뺀 사람은 그대로 */
  TB.how = 'fixed'; TB.n = fx.length; TB.absent = {};
  TB.teams = fx.map(function(nums, i){
    var ids = [];
    nums.forEach(function(n){ var x = byNo[n]; if(x && !seen[x]){ seen[x] = 1; if(!manual[x]) ids.push(x); } });
    return { no:i + 1, ids:ids, score:0, bonus:0 };
  });
  S.students.forEach(function(s){ if(!seen[s.id]) TB.absent[s.id] = 2; else if(manual[s.id]) TB.absent[s.id] = 1; });
  tbSave(); gbSyn('pop'); renderGB();
}
/* 정해 둔 모둠에서 이 학생의 자리 */
function tbFixedHome(id){
  var s = tbStu(id), fx = tbFixedOf(TB.g, TB.c), i;
  if(!s || !fx || TB.how !== 'fixed') return null;
  for(i=0;i<fx.length;i++) if(fx[i].indexOf(+s.number) >= 0) return tbTeam(i + 1);
  return null;
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
function tbSetN(n){ TB.n = n; TB.how = 'rand'; tbShuffle(true); }
/* 그 모둠으로 다시 짜기 — 정해 둔 모둠이면 표대로, 아니면 섞기 */
function tbRegroup(){ if(TB.how === 'fixed' && tbFixedOf(TB.g, TB.c)) tbUseFixed(); else tbShuffle(true); }
function tbAbsent(id){
  if(TB.absent[id]) delete TB.absent[id]; else TB.absent[id] = 1;
  TB.teams.forEach(function(t){ t.ids = t.ids.filter(function(x){ return x !== id; }); });
  if(!TB.absent[id]){   /* 다시 온 사람은 정해 둔 자리로, 없으면 가장 적은 모둠에 */
    var to = tbFixedHome(id) || TB.teams.slice().sort(function(a, b){ return a.ids.length - b.ids.length; })[0];
    if(to){
      to.ids.push(id);
      to.ids.sort(function(a, b){ return ((tbStu(a) || {}).number || 0) - ((tbStu(b) || {}).number || 0); });
    }
  }
  if(TB.how !== 'fixed') tbBalance();   /* 정해 둔 모둠은 크기를 맞추지 않는다 */
  tbSave(); renderGB();
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
  var fx = tbFixedOf(TB.g, TB.c), fixed = TB.how === 'fixed' && !!fx;
  var h = '<div class="card"><div class="hd"><h3 style="font-size:var(--fs-s)">' + (fixed ? '📋' : '🎲') + ' 모둠 짜기 · ' + TB.g + '학년 ' + TB.c + '반</h3>' +
          '<span class="sub">' + (S.students.length - Object.keys(TB.absent).length) + '명 참가</span></div>' +
          (fx ? '<div class="chips" style="margin-bottom:10px">' +
                '<button class="chip' + (fixed ? ' on' : '') + '" onclick="tbPickHow(\'fixed\')">📋 정해 둔 모둠 (' + fx.length + '모둠)</button>' +
                '<button class="chip' + (fixed ? '' : ' on') + '" onclick="tbPickHow(\'rand\')">🎲 랜덤으로 짜기</button></div>' : '') +
          '<div class="sub">' + (fixed ? '정해 둔 모둠이에요. 오늘 없는 사람만 빼 주세요. 이름 두 개를 차례로 누르면 오늘만 자리를 바꿔요.'
                                      : '오늘 없는 사람을 먼저 빼고 섞어요. 이름 두 개를 차례로 누르면 서로 자리를 바꿔요.') + '</div>';
  if(fixed){
    var off = S.students.filter(function(s){ return TB.absent[s.id] === 2; }).map(function(s){ return s.number; }).filter(Boolean).sort(function(a, b){ return a - b; });
    if(off.length) h += '<div class="sub" style="margin-top:6px;color:var(--ac-d)">정해 둔 모둠에 없는 ' + off.join('·') + '번은 «오늘 안 함»으로 뒀어요 — 오늘 왔으면 아래에서 눌러 넣어요.</div>';
  } else {
    h += '<div class="gbsec"><div class="k">모둠 수</div><div class="chips">';
    [3,4,5,6,7,8].forEach(function(n){
      h += '<button class="chip' + (TB.n === n ? ' on' : '') + '" onclick="tbSetN(' + n + ')">' + n + '모둠</button>';
    });
    var live = S.students.length - Object.keys(TB.absent).length, lo = Math.floor(live / TB.n), hi = Math.ceil(live / TB.n);
    h += '</div><div class="sub" style="margin-top:6px">모둠마다 ' + (lo === hi ? lo : lo + '~' + hi) + '명</div></div>';
  }
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
  h += (fixed ? '<button class="gbbig" style="margin-top:14px" onclick="tbUseFixed()">↺ 정해 둔 대로 되돌리기</button>'
              : '<button class="gbbig" style="margin-top:14px" onclick="tbShuffle(true)">🎲 다시 섞기</button>') +
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
function tbToMake(){
  if(!TB.teams.length){ toast('모둠을 먼저 짜 주세요'); return; }
  TB.phase = 'make';
  TB.code = String(1000 + Math.floor(Math.random() * 9000));
  tbQs();
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
/* 학생 기기에 보내는 것 — 모둠 번호·이모지·출석 번호·낸 문제 수만(이름·문제 내용 없음) */
function tbInfo(){
  return { k:'info', open: !!(TB && TB.phase === 'make'), cls: TB ? TB.g + '-' + TB.c : '', hw: gbHW() ? 1 : 0,
           due: TB && TB.due ? TB.due - Date.now() : 0,
           teams: TB ? TB.teams.map(function(t){
             var n = tbTeamQs(t.no).length;
             return { no:t.no, emo:tbEmo(t.no - 1),
                      nums: t.ids.map(function(id){ return (tbStu(id) || {}).number; }).filter(Boolean),
                      cnt:n, done: n ? 1 : 0 };
           }) : [] };
}
function tbSendInfo(){ tbSend(tbInfo()); }
/* 그 기기가 낸 문제만 상태·피드백과 함께 돌려준다 — 다른 모둠 문제는 보내지 않는다 */
function tbMine(dev){
  return tbQs().filter(function(q){ return q.dev === dev; }).map(function(q){
    return { id:q.id, team:q.team, t:q.t, q:q.q, a:q.a, ch:q.ch || null, ex:q.ex || '', n:q.n || 1,
             st:q.st || 'new', fb:q.fb || null, note:q.note || '', byT:q.byT ? 1 : 0 };
  });
}
function tbSendMine(dev){ if(dev && dev !== 'teacher') tbSend({ k:'mine', dev:dev, list:tbMine(dev) }); }
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
function tbNewId(){ TB.qn = (TB.qn || 0) + 1; return 'q' + TB.qn; }
function tbIn(p){
  if(!TB) return;
  if(p.k === 'hello'){ tbSendInfo(); if(p.dev) tbSendMine(p.dev); return; }
  if(p.k === 'del' && p.dev){          /* 학생이 자기 문제를 지움 — 출제 중에만 */
    var dq = tbQ(p.id);
    if(TB.phase === 'make' && dq && dq.dev === p.dev){
      TB.qs = tbQs().filter(function(x){ return x.id !== p.id; });
      tbSave(); tbSendInfo(); gbRerender();
    }
    tbSendMine(p.dev); return;
  }
  if(p.k !== 'sub' || !p.dev) return;
  var ack = function(ok, msg, extra){ var o = { k:'ack', dev:p.dev, rid:p.rid || '', ok:ok ? 1 : 0, msg:msg || '' }, k; if(extra) for(k in extra) o[k] = extra[k]; tbSend(o); };
  if(TB.phase !== 'make'){ ack(false, '출제 시간이 끝났어요 — 이제 전자칠판을 보세요!'); return; }
  /* 대답을 못 받아 같은 걸 다시 보낸 것 — 한 번만 넣는다 */
  TB.rids = TB.rids || {};
  if(p.rid && TB.rids[p.rid]){ var rq = tbQ(TB.rids[p.rid]); ack(true, '', { id:TB.rids[p.rid], n:rq ? rq.n : 1 }); tbSendMine(p.dev); return; }
  var no = +p.team, t = tbTeam(no);
  if(!t){ ack(false, '모둠 번호를 다시 골라 주세요'); return; }
  var q = tbCleanQ(p.q);
  if(!q){ ack(false, '문제와 정답을 모두 채워 주세요'); return; }
  var old = p.id ? tbQ(p.id) : null, now = Date.now();
  if(old && old.dev !== p.dev){ ack(false, '이 문제는 다른 기기에서 낸 문제라 여기서 고칠 수 없어요.'); return; }
  if(old){                             /* 고쳐 보냄 — 고치기 전 판·피드백은 남겨 둔다 */
    old.prev = tbQBody(old); tbQSet(old, q);
    old.team = no; old.n = (old.n || 1) + 1; old.at = now; old.st = 'new'; old.byT = 0;
    old.note = String(p.note || '').trim().slice(0, 100);
    q = old;
  } else {
    q.id = tbNewId(); q.team = no; q.dev = p.dev; q.at = now; q.n = 1; q.st = 'new';
    tbQs().push(q);
  }
  if(p.rid){
    TB.rids[p.rid] = q.id;
    var ks = Object.keys(TB.rids); if(ks.length > 300) ks.slice(0, ks.length - 300).forEach(function(k){ delete TB.rids[k]; });
  }
  tbSave();
  ack(true, '', { id:q.id, team:no, n:q.n });
  gbSyn('pop'); toast('📨 ' + tbName(t) + (q.n > 1 ? ' — 문제를 고쳐 보냈어요' : ' — 문제 도착!'));
  tbSendInfo(); tbSendMine(p.dev);
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
/* 문제 상태 — new 검토 전 · fix 고치는 중(피드백 보냄) · ok 통과 */
function tbStIco(q){ return q.st === 'ok' ? '✅' : q.st === 'fix' ? '✏️' : (q.n > 1 ? '🔁' : '⏳'); }
function tbStTxt(q){ return q.st === 'ok' ? '통과' : q.st === 'fix' ? '고치는 중' : (q.n > 1 ? '고쳐 옴' : '검토 전'); }
/* 낼 문제 — ✅ 통과한 것만, 또는 검토 전까지(고치는 중인 문제는 늘 뺀다) */
function tbPoolAll(){ var ok = tbQs().filter(function(q){ return q.st === 'ok'; }).length; return TB.pool === 'all' || (TB.pool == null && ok < 2); }
function tbPoolQs(){
  var all = tbPoolAll();
  return tbQs().filter(function(q){ return tbTeam(q.team) && (q.st === 'ok' || (all && q.st === 'new')); });
}
function tbSetPool(v){ TB.pool = v; tbSave(); renderGB(); }
function tbWantN(n){ var w = TB.want || 10; return Math.max(0, Math.min(w === 'all' ? n : w, n)); }
function tbSetWant(v){ TB.want = v; tbSave(); renderGB(); }
function tbMakeUI(){
  var qs = tbQs(), h;
  var nOk = qs.filter(function(q){ return q.st === 'ok'; }).length, nFix = qs.filter(function(q){ return q.st === 'fix'; }).length, nNew = qs.length - nOk - nFix;
  var pool = tbPoolQs(), k = tbWantN(pool.length), firstNew = tbNextNew('');
  h = '<div class="gbs tb-make">' + (gbHW() ? gbHWDeco() : '') +
      '<div class="gbs-top"><span>' + TB.g + '학년 ' + TB.c + '반 · 👥 모둠 골든벨</span><span class="tb-live' + (_tbLiveSt === 'on' ? ' on' : '') + '" id="tbLive">' + tbLiveTxt() + '</span></div>' +
      '<div class="gbs-no">모둠 문제 만들기!</div>' +
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
       '<div class="tb-tips"><b>좋은 문제는</b> 답이 하나로 정해지고 · 10초 안에 종이에 쓸 수 있고 · 우리가 배운 내용이고 · 다른 모둠 절반쯤 맞힐 만한 문제예요 (그래야 <b>보너스 +1</b>) · 문제는 <b>몇 개든</b> 보내도 돼요</div></div>';
  /* 도착한 문제 — 화면에는 상태만, 내용은 📝 검토 창에서만(학생들이 전자칠판을 보고 있으니까) */
  h += '<div class="card"><div class="hd"><h3 style="font-size:var(--fs-s)">📨 도착한 문제 ' + qs.length + '개</h3>' +
       '<span class="sub">✅ 통과 ' + nOk + ' · ⏳ 검토 전 ' + nNew + ' · ✏️ 고치는 중 ' + nFix + '</span></div>' +
       (firstNew ? '<button class="btn" style="background:var(--ac);color:#fff;margin-bottom:10px" onclick="tbReview(\'' + firstNew.id + '\')">📝 검토 전 문제 보기 (' + nNew + ')</button>' : '') +
       '<div class="sub" style="margin-bottom:8px">문제 내용은 📝 검토 창에서만 보여요. ✅ 통과하거나 ✏️ 피드백을 보내면 그 문제를 낸 기기에 바로 떠요.</div>' +
       '<div class="tb-stat">' +
       TB.teams.map(function(t){
         var tq = tbTeamQs(t.no);
         return '<div class="tb-st' + (tq.length ? ' ok' : '') + '"><div class="nm">' + tbName(t) + ' <span class="gbtag">' + tq.length + '개</span></div>' +
                '<div class="tb-qs">' + (tq.length ? tq.map(function(q, i){
                  return '<button class="tbq ' + (q.st || 'new') + '" title="' + tbStTxt(q) + '" onclick="tbReview(\'' + q.id + '\')">' + tbStIco(q) + ' ' + (i + 1) + '</button>';
                }).join('') : '<span class="st">⏳ 만드는 중</span>') + '</div>' +
                '<div class="bt"><button class="gbmini" onclick="tbWrite(' + t.no + ')">✏️ 대신 쓰기</button></div></div>';
       }).join('') + '</div>';
  /* 시작 — 낼 문제와 문항 수를 고르면 모둠마다 고르게 랜덤으로 뽑는다 */
  var all = tbPoolAll(), wants = [3,5,7,10,15,20].filter(function(n){ return n < pool.length; });
  h += '<div class="gbsec"><div class="k">🎯 낼 문제</div><div class="chips">' +
       '<button class="chip sm' + (all ? '' : ' on') + '" onclick="tbSetPool(\'ok\')">✅ 통과한 문제만 (' + nOk + ')</button>' +
       '<button class="chip sm' + (all ? ' on' : '') + '" onclick="tbSetPool(\'all\')">검토 전도 넣기 (' + (nOk + nNew) + ')</button></div>' +
       (nFix ? '<div class="sub" style="margin-top:5px">✏️ 고치는 중인 ' + nFix + '문제는 빠져요 — 고쳐서 다시 오면 넣을 수 있어요</div>' : '') + '</div>' +
       '<div class="gbsec"><div class="k">🔢 문항 수 — 모둠마다 고르게 랜덤으로 뽑아요</div><div class="chips">' +
       wants.map(function(n){ return '<button class="chip sm' + (k === n && TB.want !== 'all' ? ' on' : '') + '" onclick="tbSetWant(' + n + ')">' + n + '문제</button>'; }).join('') +
       (pool.length ? '<button class="chip sm' + (k === pool.length ? ' on' : '') + '" onclick="tbSetWant(\'all\')">전부 (' + pool.length + ')</button>' : '') +
       '</div></div>' +
       '<button class="btn g" style="margin-top:13px' + (k < 2 ? ';opacity:.5' : '') + '" onclick="tbStart()"' + (k < 2 ? ' disabled' : '') + '>🔔 모둠 골든벨 시작 (' + k + '문제 랜덤)</button>' +
       '<div style="display:flex;gap:8px;margin-top:9px"><button class="chip sm" style="flex:1" onclick="tbBackTeams()">← 모둠 다시 짜기</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbQuit()">그만두기</button>' +
       '<button class="chip sm" style="flex:1" onclick="gbFull()">⛶ 전체화면</button></div>' + gbSndBar() + '</div>';
  h += '<div class="card">' + tbHowCard(false) + '</div>';
  return h;
}
function tbBackTeams(){
  if(tbQs().length && !confirm('모둠을 다시 짜면 도착한 문제가 지워져요. 괜찮을까요?')) return;
  tbSend({ k:'info', open:false, teams:[], cls:'' }); tbUnlisten();
  TB.phase = 'teams'; TB.qs = []; TB.due = 0; tbSave(); renderGB();
}
function tbDelQ(id){
  var q = tbQ(id); if(!q || !confirm('이 문제를 지울까요?')) return;
  TB.qs = tbQs().filter(function(x){ return x.id !== id; });
  tbSave(); closeMdl(); tbSendInfo(); tbSendMine(q.dev); renderGB();
}
/* 다음에 볼 «검토 전» 문제 — 먼저 온 것부터 */
function tbNextNew(skip){
  return tbQs().filter(function(q){ return q.st !== 'ok' && q.st !== 'fix' && q.id !== skip; })
               .sort(function(a, b){ return (a.at || 0) - (b.at || 0); })[0] || null;
}

/* 📝 검토 — 문제를 보고 ✅ 통과 또는 ✏️ 피드백(고쳐 볼 점)을 그 기기로 보낸다 */
var TB_FB_CHIPS = ['답이 하나로 정해지게 고쳐 볼까요?', '배운 낱말로 물어보면 더 좋아요', '문장을 더 짧고 분명하게!',
                   '정답이 맞는지 학습지에서 다시 확인해 봐요', '조금 쉬워요 — 한 번 더 생각하게 만들어 볼까요?', '조금 어려워요 — 문제에 힌트를 넣어 볼까요?'];
function tbQView(s){
  var ai = gbAnsIx(s);
  return '<div style="font-size:15px;font-weight:800;line-height:1.5;word-break:keep-all">' + gbTypeTag(s) + ' ' + esc(s.q) + '</div>' +
    (s.ch ? '<div class="sub" style="margin-top:6px">' + s.ch.map(function(c, i){ return GB_CIRC[i] + ' ' + esc(c); }).join('<br>') + '</div>' : '') +
    '<div style="margin-top:8px;font-weight:900;color:var(--ok-d)">정답: ' + esc(s.a) + (ai >= 0 && s.ch[ai] ? ' ' + esc(s.ch[ai]) : '') + '</div>' +
    (s.ex ? '<div class="sub" style="margin-top:3px">' + esc(s.ex) + '</div>' : '');
}
function tbReview(id){
  var q = tbQ(id), t = q && tbTeam(q.team); if(!q || !t) return;
  var paper = q.dev === 'teacher', i = tbTeamQs(q.team).indexOf(q) + 1, left = tbQs().filter(function(x){ return x.st !== 'ok' && x.st !== 'fix' && x.id !== id; }).length;
  var chips = TB_FB_CHIPS.concat(q.t === 'mc' ? ['틀린 보기도 그럴듯하게 만들어 봐요'] : []);
  $('mdlIn').innerHTML = '<h3 style="font-size:var(--fs-m);font-weight:900">📝 ' + tbName(t) + ' · ' + i + '번 문제</h3>' +
    '<div class="sub" style="margin:3px 0 10px">' + tbStIco(q) + ' ' + tbStTxt(q) + (q.n > 1 ? ' · ' + q.n + '번째 판' : '') +
      (q.byT ? ' · 선생님이 고침' : '') + (paper ? ' · 종이로 받아 선생님이 넣은 문제' : '') + (left ? ' · 이 문제 말고 검토 전 ' + left + '개' : '') +
      '<br><b style="color:var(--bad)">학생들이 화면을 보고 있으면 문제가 들켜요!</b></div>' +
    (q.fb && q.fb.t && q.n > (q.fb.n || 1) ? '<div class="tb-fbold"><b>💬 지난 피드백</b> ' + esc(q.fb.t) + '</div>' : '') +
    (q.note ? '<div class="tb-fbold" style="border-color:var(--ok)"><b>🔧 모둠이 고친 점</b> ' + esc(q.note) + '</div>' : '') +
    (q.prev ? '<details class="tb-prev"><summary>고치기 전 문제 보기</summary>' + tbQView(q.prev) + '</details>' : '') +
    '<div class="tb-rq">' + tbQView(q) + '</div>' +
    (paper ? '' :
      '<div class="k" style="margin:12px 0 6px;font-size:12px;font-weight:900;color:var(--ink2)">💬 피드백 — 눌러서 넣고 고쳐 써도 돼요</div>' +
      '<div class="chips">' + chips.map(function(c, k){ return '<button class="chip sm" onclick="tbFbChip(' + k + ')">' + esc(c) + '</button>'; }).join('') + '</div>' +
      '<textarea class="inp" id="tbFbT" rows="2" maxlength="200" style="margin-top:7px" placeholder="고쳐 볼 점이나 칭찬 한마디 (✅ 통과일 때는 비워도 돼요)">' +
        (q.st === 'fix' && q.fb ? esc(q.fb.t) : '') + '</textarea>') +
    '<div style="display:flex;gap:8px;margin-top:12px">' +
      (paper ? '' : '<button class="btn" style="flex:1;background:var(--ac);color:#fff" onclick="tbFb(\'' + id + '\',\'fix\')">✏️ 고쳐 보세요</button>') +
      '<button class="btn g" style="flex:1" onclick="tbFb(\'' + id + '\',\'ok\')">✅ 통과</button></div>' +
    '<div style="display:flex;gap:6px;margin-top:8px;flex-wrap:wrap">' +
      '<button class="chip sm" style="flex:1" onclick="closeMdl();tbWrite(' + q.team + ',\'' + id + '\')">✏️ 내가 고치기</button>' +
      '<button class="chip sm" style="flex:1" onclick="tbDelQ(\'' + id + '\')">🗑 지우기</button>' +
      '<button class="chip sm" style="flex:1" onclick="closeMdl()">닫기</button></div>';
  $('mdl').classList.add('show');
  _tbRvChips = chips;
}
var _tbRvChips = [];
function tbFbChip(k){
  var el = $('tbFbT'), c = _tbRvChips[k]; if(!el || !c) return;
  el.value = el.value.trim() ? el.value.trim() + ' ' + c : c; el.focus();
}
function tbFb(id, st){
  var q = tbQ(id); if(!q) return;
  var txt = (($('tbFbT') || {}).value || '').trim().slice(0, 200);
  if(st === 'fix' && !txt){ toast('무엇을 고쳐 볼지 한 줄 써 주세요'); var el = $('tbFbT'); if(el) el.focus(); return; }
  q.st = st;
  if(txt || st === 'fix' || q.fb) q.fb = { t:txt, st:st, at:Date.now(), n:q.n || 1 };
  tbSave(); tbSendMine(q.dev); tbSendInfo();
  gbSyn(st === 'ok' ? 'ding' : 'pop');
  toast(st === 'ok' ? '✅ 통과!' : '✏️ 피드백을 보냈어요 — 모둠이 고쳐서 다시 보내요');
  var nx = tbNextNew(id);
  if(nx) tbReview(nx.id); else closeMdl();
  renderGB();
}
/* 종이로 받은 문제를 선생님이 대신 넣거나(새 문제), 낸 문제를 직접 손본다(id) */
var _tbWT = 'short', _tbWId = '';
function tbWrite(no, id){
  var s = id ? tbQ(id) : null;
  if(s) no = s.team;
  var t = tbTeam(no); if(!t) return;
  _tbWId = s ? s.id : '';
  _tbWT = s ? s.t : _tbWT;
  tbWriteDraw(no, s ? { q:s.q, a:s.a, c:(s.ch || []).join('\n'), e:s.ex || '' } : null);
  $('mdl').classList.add('show');
}
function tbWriteDraw(no, d){
  var t = tbTeam(no), ty = _tbWT;
  d = d || { q:'', a:'', c:'', e:'' };
  $('mdlIn').innerHTML = '<h3 style="font-size:var(--fs-m);font-weight:900">✏️ ' + tbName(t) + (_tbWId ? ' 문제 고치기' : ' 문제 넣기') + '</h3>' +
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
  var old = _tbWId ? tbQ(_tbWId) : null;
  if(old){                /* 선생님이 고친 문제는 통과로 — 학생 기기에도 «선생님이 고침»으로 보인다 */
    old.prev = tbQBody(old); tbQSet(old, q);
    old.n = (old.n || 1) + 1; old.at = Date.now(); old.st = 'ok'; old.byT = 1;
    tbSendMine(old.dev);
  } else {
    q.id = tbNewId(); q.team = no; q.dev = 'teacher'; q.at = Date.now(); q.n = 1; q.st = 'ok';
    tbQs().push(q);
  }
  _tbWId = '';
  tbSave(); closeMdl(); tbSendInfo(); renderGB();
  toast('✔ ' + no + '모둠 문제를 ' + (old ? '고쳤어요' : '넣었어요'));
}

/* ══ ③ 모둠 골든벨 진행 ══ */
/* 모둠마다 고르게 뽑기 — 아직 안 나온 문제부터(한 판 더 할 때), 같은 단계 안에서는 모둠을 한 바퀴씩 돌며
   하나씩 뽑는다. 다 뽑은 뒤 순서를 다시 섞는다. */
function tbDraw(pool, k){
  var lv = {}, out = [];
  pool.forEach(function(q){ var u = q.used || 0; (lv[u] = lv[u] || []).push(q); });
  Object.keys(lv).map(Number).sort(function(a, b){ return a - b; }).forEach(function(u){
    var by = {}, nos, any = true;
    lv[u].forEach(function(q){ (by[q.team] = by[q.team] || []).push(q); });
    nos = gbShuffle(Object.keys(by));
    nos.forEach(function(no){ gbShuffle(by[no]); });
    while(out.length < k && any){
      any = false;
      nos.forEach(function(no){ if(out.length < k && by[no].length){ out.push(by[no].shift()); any = true; } });
    }
  });
  return gbShuffle(out);
}
function tbStart(){
  var pool = tbPoolQs(), k = tbWantN(pool.length);
  if(k < 2){ toast('낼 수 있는 문제가 두 개 이상 있어야 시작할 수 있어요'); return; }
  var pick = tbDraw(pool, k);
  pick.forEach(function(q){ q.used = (q.used || 0) + 1; });
  TB.order = pick.map(function(q){ return q.id; }); TB.qi = 0; TB.rev = 0; TB.cor = {}; TB.hist = []; TB.awarded = {};
  TB.teams.forEach(function(t){ t.score = 0; t.bonus = 0; });
  TB.phase = 'play'; TB.due = 0;
  tbSave();
  tbSend({ k:'info', open:false, teams:[], cls:TB.g + '-' + TB.c });   /* 학생 기기에 «출제 끝» */
  setTimeout(tbUnlisten, 1500);
  gbTimerStop(); gbPlayBgm(); renderGB(); window.scrollTo(0, 0);
}
/* 지금 문제를 낸 모둠 번호 */
function tbAuthor(){ var s = TB && TB.order ? tbQ(TB.order[TB.qi]) : null; return s ? s.team : 0; }
function tbCurQ(){
  if(!TB || !TB.order) return null;
  var s = tbQ(TB.order[TB.qi]), t = s && tbTeam(s.team);
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
  if(!gbTeamPlaying() || no === tbAuthor() || !tbTeam(no)) return;
  if(TB.cor[no]) delete TB.cor[no]; else { TB.cor[no] = 1; gbSyn('pop'); }
  tbSave(); renderGB();
}
function tbReveal(){ if(!gbTeamPlaying() || TB.rev) return; TB.rev = 1; gbTimerStop(); tbSave(); gbSyn('ding'); renderGB(); }
function tbNext(){
  if(!gbTeamPlaying()) return;
  var author = tbAuthor(), ans = TB.teams.filter(function(t){ return t.no !== author; });
  var cor = ans.filter(function(t){ return TB.cor[t.no]; }).map(function(t){ return t.no; });
  var bonus = cor.length > 0 && cor.length < ans.length;
  TB.hist.push({ a:author, qid:TB.order[TB.qi], cor:cor, b:bonus ? 1 : 0, n:ans.length });
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
  var author = tbAuthor(), q = tbCurQ(), tl = gbTL(), at = tbTeam(author);
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
    var bs = tbQ(best.h.qid), bt = tbTeam(best.h.a);
    h += '<div class="card tb-best"><h3 style="font-size:var(--fs-s)">💡 베스트 문제 — ' + (bt ? tbName(bt) : '') + '</h3>' +
         '<div class="q">' + gbTypeTag(bs) + ' ' + esc(bs ? bs.q : '') + '</div>' +
         '<div class="sub">' + best.h.n + '모둠 중 ' + best.h.cor.length + '모둠이 맞혔어요 — 맞힌 모둠과 틀린 모둠이 가장 고르게 갈린 문제</div>' +
         (bt ? '<div class="sub" style="margin-top:6px">' + bt.ids.map(function(id){ return esc(tbLabel(id)); }).join(' · ') + '</div>' : '') +
         '<button class="btn g" style="margin-top:12px' + (TB.awarded && TB.awarded.best ? ';opacity:.5' : '') + '" onclick="tbAward(\'best\')"' + (TB.awarded && TB.awarded.best ? ' disabled' : '') + '>' +
         (TB.awarded && TB.awarded.best ? '✔ 도장을 찍었어요' : '🏅 베스트 문제 모둠 ' + (bt ? bt.ids.length : 0) + '명에게 도장 찍기') + '</button></div>';
  }

  h += '<div class="card"><h3 style="font-size:var(--fs-s)">📋 문제별 결과</h3><div style="margin-top:6px">' +
       (TB.hist || []).map(function(x, i){
         var s = tbQ(x.qid), t = tbTeam(x.a);
         return '<div class="tb-qr"><b class="n">' + (i + 1) + '</b><span class="tx"><span class="src">' + (t ? tbName(t) : '') + ' 출제</span>' + esc(s ? s.q : '') +
                (s ? ' <b style="color:var(--ok-d)">→ ' + esc(s.a) + '</b>' : '') + '</span>' +
                '<b class="r">' + x.cor.length + '/' + x.n + (x.b ? ' 💡' : '') + '</b></div>';
       }).join('') + '</div>' +
       '<button class="chip" style="margin-top:10px" onclick="tbToMine()">⭐ 모둠 문제 ' + tbMineQs().length + '개를 내 문제에 담기</button>' +
       '<div class="sub" style="margin-top:5px">이번에 낸 문제와 ✅ 통과한 문제를 담아요 — ✋ 골라서 출제에서 다시 쓸 수 있어요</div></div>';

  h += '<div class="card"><h3 style="font-size:var(--fs-s)">📊 점수</h3>' + tbScoreboard(0) + '</div>';
  h += '<div class="card"><div style="display:flex;gap:8px;flex-wrap:wrap">' +
       '<button class="chip sm" style="flex:1" onclick="tbBack()">↩ 마지막 문제로</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbAgain()">🔁 같은 모둠으로 한 판 더</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbNewTeams()">🎲 모둠 새로 짜기</button>' +
       '<button class="chip sm" style="flex:1" onclick="tbQuit()">끝내기</button></div>' + gbSndBar(true) + '</div>';
  return h;
}
/* 한 판 더 — 모둠 문제는 그대로 두고(더 낼 수도 있다) 이번에 안 나온 문제부터 다시 뽑는다 */
function tbAgain(){
  if(!confirm('같은 모둠으로 한 판 더 할까요?\n\n모둠 문제는 그대로 두고(새로 더 낼 수도 있어요) 이번에 안 나온 문제부터 다시 뽑아요. 점수는 0부터예요.')) return;
  TB.teams.forEach(function(t){ t.score = 0; t.bonus = 0; });
  TB.hist = []; TB.order = []; tbToMake();
}
function tbNewTeams(){ if(!confirm('모둠을 새로 짤까요? (이번 판 점수·문제는 지워져요)')) return; TB.phase = 'teams'; TB.qs = []; TB.hist = []; tbSave(); tbRegroup(); }
/* 내 문제에 담을 것 — 이번에 낸 문제 + ✅ 통과한 문제 */
function tbMineQs(){
  var played = {};
  (TB.hist || []).forEach(function(x){ played[x.qid] = 1; });
  return tbQs().filter(function(q){ return played[q.id] || q.st === 'ok'; });
}
function tbToMine(){
  var mine = gbmyAll(), seen = {}, add = 0, day = todayStr().slice(5).replace('-', '/');
  mine.forEach(function(q){ seen[q.q] = 1; });
  tbMineQs().forEach(function(s){
    if(seen[s.q]) return;
    var it = { id:'my-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 5), t:s.t, q:s.q, a:s.a,
               src:'👥 ' + TB.g + '-' + TB.c + ' ' + s.team + '모둠 출제 (' + day + ')', g:TB.g };
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
    bt = tbTeam(best.h.a); bs = tbQ(best.h.qid); if(!bt || !bs) return;
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
    '.tb-qs{display:flex;gap:5px;flex-wrap:wrap;margin:6px 0 8px}',
    '.tbq{padding:5px 10px;border-radius:999px;border:2px solid var(--line);background:#fff;font-size:12.5px;font-weight:900}',
    '.tbq.new{border-color:#e9b949;background:#FFF8E6}',
    '.tbq.fix{border-color:var(--ac);background:#FFF1E4}',
    '.tbq.ok{border-color:var(--ok);background:#E8F7EC;color:var(--ok-d)}',
    '.tb-rq{border:2px solid var(--line);border-radius:14px;padding:12px;background:#fff}',
    '.tb-fbold{border-left:4px solid var(--ac);background:#FFF8EF;border-radius:8px;padding:7px 10px;margin-bottom:8px;font-size:12.5px;font-weight:700;line-height:1.5;word-break:keep-all}',
    '.tb-fbold b{margin-right:4px}',
    '.tb-prev{margin-bottom:8px;font-size:12.5px}',
    '.tb-prev summary{cursor:pointer;font-weight:800;color:var(--ink2)}',
    '.tb-prev>div{opacity:.75}',
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
