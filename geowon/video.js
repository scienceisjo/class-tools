/* ═══════════════════════════════════════════════════════════════
   🎬 영상 주소 읽기 — 관리 화면과 교실 화면이 함께 씁니다
   ---------------------------------------------------------------
   붙여넣으신 주소가 어떤 영상인지 알아내서, 화면 안에서 바로
   재생할 수 있는 주소로 바꿔 줍니다.

   아무 주소나 화면에 띄우지는 않습니다. 학교 화면이니만큼
   아래 목록에 있는 곳만 받습니다.
     · 유튜브 (youtube.com, youtu.be, 쇼츠, 라이브 포함)
     · 비메오 (vimeo.com)
     · 영상 파일 주소 (.mp4 / .webm / .ogv)
   ═══════════════════════════════════════════════════════════════ */
(function (global) {

  function ytStart(u) {
    // 12m30s / 750 처럼 적힌 시작 시각을 초로 바꿉니다
    var t = u.searchParams.get('t') || u.searchParams.get('start') || '';
    if (!t) return 0;
    if (/^\d+$/.test(t)) return parseInt(t, 10);
    var m = t.match(/(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?/);
    if (!m) return 0;
    return (+(m[1] || 0)) * 3600 + (+(m[2] || 0)) * 60 + (+(m[3] || 0));
  }

  function parseVideo(raw) {
    var s = (raw || '').trim();
    if (!s) return null;
    if (!/^https?:\/\//i.test(s)) s = 'https://' + s;

    var u;
    try { u = new URL(s); } catch (e) { return null; }
    var host = u.hostname.replace(/^www\./, '').toLowerCase();

    /* ── 유튜브 ── */
    if (host === 'youtu.be' || host.endsWith('youtube.com') || host.endsWith('youtube-nocookie.com')) {
      var id = '';
      if (host === 'youtu.be') id = u.pathname.slice(1).split('/')[0];
      else if (u.pathname === '/watch') id = u.searchParams.get('v') || '';
      else {
        var m = u.pathname.match(/^\/(embed|shorts|live|v)\/([^/?#]+)/);
        if (m) id = m[2];
      }
      if (!/^[A-Za-z0-9_-]{6,20}$/.test(id)) return null;

      var st = ytStart(u);
      // youtube-nocookie 는 시청 기록을 남기지 않는 주소입니다 (학교 화면에 적합)
      var q = 'rel=0&modestbranding=1&playsinline=1' + (st ? '&start=' + st : '');
      return {
        kind: 'youtube', id: id,
        embed: 'https://www.youtube-nocookie.com/embed/' + id + '?' + q,
        watch: 'https://www.youtube.com/watch?v=' + id + (st ? '&t=' + st : ''),
        thumb: 'https://i.ytimg.com/vi/' + id + '/hqdefault.jpg',
        label: '유튜브'
      };
    }

    /* ── 비메오 ── */
    if (host.endsWith('vimeo.com')) {
      var vm = u.pathname.match(/\/(\d{6,})/);
      if (!vm) return null;
      return {
        kind: 'vimeo', id: vm[1],
        embed: 'https://player.vimeo.com/video/' + vm[1],
        watch: 'https://vimeo.com/' + vm[1],
        thumb: '', label: '비메오'
      };
    }

    /* ── 영상 파일 주소 ── */
    if (/\.(mp4|webm|ogv)(\?|#|$)/i.test(u.pathname)) {
      return { kind: 'file', id: '', embed: u.href, watch: u.href, thumb: '', label: '영상 파일' };
    }

    return null;
  }

  global.parseVideo = parseVideo;
})(window);
