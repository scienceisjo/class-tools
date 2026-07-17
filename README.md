# class-tools

이삼한 친구들 · 학급 운영에 바로 쓰는 웹 도구 모음입니다.
모두 설치 없이 브라우저에서 여는 단일 HTML 파일이며, 전자칠판에서 사용하기 좋게 만들었습니다.

## 🔗 바로 열기

- **허브(전체 목록):** https://scienceisjo.github.io/class-tools/
- **🗳️ 학급 임원 선거:** https://scienceisjo.github.io/class-tools/election/
- **💌 롤링페이퍼:** https://scienceisjo.github.io/class-tools/rolling-paper/
- **🌲 이삼한 친구들의 숲:** https://scienceisjo.github.io/class-tools/memory-village/
- **📄 PDF 만능 도구:** https://scienceisjo.github.io/class-tools/pdf-tool/

## 도구 목록

| 도구 | 설명 | 링크 |
|------|------|------|
| 학급 임원 선거 | 유의사항·규칙·후보자를 입력하면 PPT 없이 선거를 진행. 소견발표 타이머(제한시간·제한없음·끄기), 개표 그래프, 당선자 발표까지. | [election/](election/) |
| 롤링페이퍼 | 전학·졸업 가는 친구에게. QR로 반 친구들이 메시지를 남기면 전시 화면에 모여요. 배경 사진·콜라주 꾸미기와 PDF 저장까지. | [rolling-paper/](rolling-paper/) |
| 이삼한 친구들의 숲 | 진짜 3D 숲을 캐릭터로 걸어다니는 학급 추억 공간. 다짐·명장면·행사·응원·1인1역 + ❤️공감 + 교사 공지 알림·사진 갤러리. Supabase 실시간(방 코드 `?room=`)·발표 모드. | [memory-village/](memory-village/) |
| PDF 만능 도구 | 병합·분할(썸네일 갤러리·가위·용량분할)·압축·이미지↔PDF·페이지 정리·쪽번호·워터마크·모아찍기/소책자·텍스트 추출·OCR(한국어) 11가지. 워터마크·쪽번호 등 실시간 미리보기. 모든 처리를 브라우저 안에서 해서 파일이 서버로 가지 않고, 앱(PWA)으로 설치하면 인터넷 없이도 동작. | [pdf-tool/](pdf-tool/) |

## 새 도구 추가하는 법

1. 루트에 `도구이름/` 폴더를 만들고 그 안에 `index.html`을 넣습니다.
2. `index.html`(허브)의 카드 목록에 링크를 추가합니다.
3. 커밋 후 푸시하면 GitHub Pages가 자동으로 반영합니다.

---
made with Claude Code
