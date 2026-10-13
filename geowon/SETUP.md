# 📺 거원중학교 전자칠판 알리미 — 세팅 안내서

안녕하세요, 해누리중학교 조승재입니다. 저희 학교 교실 전자칠판에 띄워 쓰는 알리미를 거원중학교에서도 쓰실 수 있게 준비해 두었습니다.
이 파일 하나에 세팅에 필요한 내용(순서·SQL·코드)이 모두 들어 있습니다.

> ### 🙋 선생님께 — 이 파일 쓰는 법
> 1. ChatGPT · Claude · Gemini 같은 AI 대화창에 **이 파일을 통째로 올리거나 붙여 넣어** 주세요.
> 2. 「**이 안내서대로 처음부터 한 단계씩 같이 세팅해 줘**」라고 말씀하시면 됩니다.
> 3. AI가 묻는 것에 답하시고, 화면에 보이는 것을 알려 주시면 AI가 다음 할 일을 알려 드립니다.
>
> 걸리는 시간은 30~40분 정도입니다. 컴퓨터(크롬 또는 엣지)에서 해 주세요.

---

## 🤖 AI에게 — 진행 규칙 (먼저 읽어 주세요)

당신은 거원중학교 선생님이 이 알리미를 세팅하도록 돕습니다. 선생님은 개발자가 아닙니다.

1. **한 번에 한 단계만** 안내하세요. 누를 메뉴·버튼 이름을 화면에 보이는 영어 그대로 적고, 각 단계 끝의 「✅ 확인」이 되면 다음 단계로 넘어가세요.
2. 시작할 때 **6단계의 A·B 중 어느 쪽인지** 먼저 여쭤 보세요. 모르시면 A를 권하세요.
3. **긴 SQL과 함수 코드는 직접 옮겨 적지 마세요.** 선생님이 아래 주소를 열어 전체 선택(Ctrl+A)·복사(Ctrl+C)하도록 안내하세요. 옮겨 적다 한 줄만 빠져도 보안 규칙이 빠질 수 있습니다.
   - 설치 SQL 1부: `https://scienceisjo.github.io/class-tools/geowon/install-part1.txt` (부록 A-1과 같음)
   - 시간표 함수 코드: `https://scienceisjo.github.io/class-tools/geowon/sync-timetable.txt` (부록 B와 같음)
   AI가 값을 채워 드리는 것은 **부록 A-2(짧은 SQL)** 하나뿐입니다. 고칠 곳 없이 그대로 붙여 넣을 수 있는 완성본으로 드리세요.
4. 선생님께 받을 값은 아래 세 가지입니다. B를 고르시면 깃허브 아이디도 여쭤 보세요.
   - 프로젝트 주소(Project URL, `https://…supabase.co`)
   - 공개 키(`sb_publishable_…` 또는 `eyJ…`로 시작하는 anon 키)
   - 가입 코드(선생님이 정하는 암호, 예: `geowon2026!`)
5. **절대 받지 마세요**: secret 키(`sb_secret_…`), service_role 키, 데이터베이스 비밀번호, 계정 비밀번호. 선생님이 붙여 넣으려 하면 말려 주세요. 이미 붙여 넣으셨다면 Supabase → Project Settings → API Keys에서 그 키를 새로 바꾸도록 안내해 주세요.
6. SQL을 복사하기 전에 **브라우저 자동 번역을 끄도록** 꼭 안내하세요(번역이 SQL 글자를 바꿔 오류가 납니다).
7. Supabase·GitHub 화면은 2026년 기준입니다. 메뉴 위치가 조금 다르면 비슷한 이름을 함께 찾아 주세요.
8. 오류가 나면 아래 「🛠 문제 해결」 표를 먼저 보세요.
9. 이 문서에 없는 기능을 새로 만들거나 화면 파일(html)을 고치지 마세요. 고칠 수 있는 파일은 `school.js`뿐입니다.

---

## 1. 어떤 프로그램인가요

교실 전자칠판에 하루 종일 띄워 두는 학교 알림판입니다.

| 선생님이 올리는 것 (관리 화면) | 저절로 나오는 것 |
|---|---|
| 공지 (전체·학년·반·교과) · 긴급 공지 | 급식 (알레르기 번호, 나이스) |
| 학생 호출 (「○○○ 교무실로」) | 학사일정 (방학·시험·공휴일, 나이스) |
| 수업 장소 변경 | **학급 시간표 + 결보강 변경** (컴시간알리미, 평일 아침 8:30) |
| 디데이 · 수행평가 일정 · 주요 일정 | 지금 몇 교시 · 날씨 · 미세먼지 · 우산 안내 |
| 영상 틀기 · 생일 · 청소당번 · 1인1역 · 분실물 | |

학생은 전자칠판의 **📮 선생님께 말하기**로 선생님께 쪽지를 보낼 수 있습니다(익명 가능). 쪽지는 개인 계정으로 로그인한 선생님만 읽습니다.

### 🔗 거원중학교 주소 (6단계 A를 쓰실 때)

| 화면 | 주소 | 누가 |
|---|---|---|
| 교실 화면 | `https://scienceisjo.github.io/class-tools/geowon/` | 교실 전자칠판 |
| 공지 관리 | `https://scienceisjo.github.io/class-tools/geowon/admin.html` | 선생님 |
| 사용법 | `https://scienceisjo.github.io/class-tools/geowon/guide.html` | 선생님 (공유용 안내서) |
| 학생 쪽지 | `https://scienceisjo.github.io/class-tools/geowon/message.html` | 학생 (휴대폰용) |

- 지금 위 주소를 열면 「**곧 열립니다**」만 보입니다. 아래 세팅이 끝나면 바로 열립니다.
- 6단계 **B**(직접 배포)를 하시면 위 주소 대신 `https://깃허브아이디.github.io/geowon-board/`를 씁니다. 뒤에 붙는 `admin.html`·`guide.html`·`message.html`은 같습니다.

---

## 2. 전체 그림 — 세 부분

| 부분 | 하는 일 | 어디에 |
|---|---|---|
| **화면** | 교실 화면·관리·사용법·쪽지 페이지 | GitHub Pages (A: 조승재 주소 / B: 선생님 주소) |
| **서버** | 공지·선생님 계정·학생 쪽지 저장 | **거원중학교 전용 Supabase** (선생님 계정으로 새로 만듦) |
| **시간표 받기** | 컴시간알리미 → 서버, 평일 아침 8:30 | Supabase의 함수 `sync-timetable` + 예약 실행 |

거원중학교의 공지·선생님 계정·학생 쪽지는 거원중학교 서버에만 저장되고, 해누리중이나 다른 학교와 섞이지 않습니다.

---

## 3. 이미 넣어 둔 거원중학교 정보 (확인만 해 주세요)

| 항목 | 값 |
|---|---|
| 나이스 교육청 · 학교 코드 | B10 · 7130170 (급식·학사일정) |
| 컴시간알리미 학교 코드 | 83839 (시간표·결보강) |
| 학급 | 1학년 6개 반 · 2학년 6개 반 · 3학년 6개 반 (총 18개 반, 컴시간 기준) |
| 날씨 위치 | 위도 37.4937 · 경도 127.1490 |
| 부서 (공지 작성자 표시용) | 교장 · 교감 · 교무실 · 행정실 · 1학년부 · 2학년부 · 3학년부 |
| 특별실 (수업 장소 변경 버튼) | 운동장 · 체육관 · 강당 · 과학실 · 음악실 · 미술실 · 기술실 · 가정실 · 컴퓨터실 · 도서관 |

**종 시간** (화면 위 「지금 ○교시」에 씁니다. 컴시간 일과시간에서 옮겼고, 끝 시각은 45분 수업으로 계산했습니다)

| 시간 | 시각 | |
|---|---|---|
| 조회 | 08:30 ~ 08:40 | |
| 1교시 | 08:50 ~ 09:35 | |
| 2교시 | 09:45 ~ 10:30 | |
| 3교시 | 10:40 ~ 11:25 | |
| 4교시 | 11:35 ~ 12:20 | |
| 점심시간 | 12:20 ~ 13:20 | |
| 5교시 | 13:20 ~ 14:05 | |
| 6교시 | 14:15 ~ 15:00 | |
| 7교시 | 15:10 ~ 15:55 | 화·목요일만 |

> ✋ 확인 부탁드립니다
> - **조회 시각**(08:30~08:40)은 짐작한 값입니다. 다르면 알려 주세요.
> - 컴시간에 **1학년 6반** 시간표가 거의 비어 있습니다(목요일 7교시 스포츠클럽만 있음). 실제로 없는 반이면 반 고르기 화면에서 뺄 수 있습니다.
> - 부서·특별실 목록이 학교와 다르면 알려 주세요.
>
> 고치는 방법: 6단계에서 **A**를 고르셨으면 조승재에게 알려 주시면 되고, **B**를 고르셨으면 `school.js`를 직접 고치시면 됩니다(「7. 학교에 맞게 채우기」 참고).

---

## 4. 세팅 순서 한눈에

- [ ] 1단계 Supabase 프로젝트 만들기
- [ ] 2단계 「이메일 확인」 끄기
- [ ] 3단계 프로젝트 주소·공개 키 복사
- [ ] 4단계 시간표 함수 올리기
- [ ] 5단계 설치 SQL 실행 (1부 그대로 → 2부 값 넣어서)
- [ ] 6단계 화면 연결 — **A** 조승재 주소 그대로 / **B** 직접 배포
- [ ] 7단계 첫 가입 (= 관리 담당자)
- [ ] 8단계 시간표 처음 받아 보기
- [ ] 9단계 교실 전자칠판에 켜기

---

## 5. 세팅

### 1단계 · Supabase 프로젝트 만들기

1. **supabase.com** → **Start your project** → GitHub 계정이나 이메일로 가입·로그인합니다.
2. 처음이면 Organization을 하나 만듭니다(이름은 아무거나, 요금제 **Free**).
3. **New project**를 누르고 아래처럼 채웁니다.
   - Project name: `geowon-board`
   - Database Password: **Generate a password** → 메모장 등에 따로 저장해 두세요(거의 쓸 일 없습니다. **AI에게 알려 주지 마세요**).
   - Region: **Northeast Asia (Seoul)**
   - 「Automatically expose new tables」 같은 칸이 보이면 **기본값 그대로** 두세요. 필요한 권한은 5단계 SQL이 직접 줍니다.
4. **Create new project** → 1~2분 기다립니다.

✅ 확인: 프로젝트 첫 화면(Project Overview)이 열리면 됩니다.
ℹ️ 무료 요금제는 계정 하나에 프로젝트 2개까지 쓸 수 있습니다.

### 2단계 · 「이메일 확인」 끄기

1. 왼쪽 **Authentication** → **Sign In / Providers**를 엽니다.
2. **Confirm email** 스위치를 찾아 **끄고** → **Save**를 누릅니다. 위쪽 「User Signups」 칸에 있거나, 아래 **Email** 항목을 누르면 나옵니다.
   「Allow new users to sign up」은 **켜 둡니다**.

왜 끄나요: 선생님들이 가입하자마자 바로 들어올 수 있게 하려는 것입니다. Supabase의 기본 메일은 보낼 수 있는 양이 아주 적어서, 켜 두면 인증 메일을 못 받는 선생님이 생깁니다. 아무나 들어오는 것은 아닙니다. 가입하려면 **가입 코드**가 필요하고, 관리 담당자가 **승인**해야 글을 쓸 수 있습니다.

✅ 확인: Confirm email 스위치가 꺼져 있으면 됩니다.

### 3단계 · 프로젝트 주소와 공개 키 복사

화면 위쪽의 **Connect** 버튼이나 왼쪽 아래 **Project Settings → API Keys**에서 찾습니다.

| 필요한 것 | 생김새 | 위치 |
|---|---|---|
| Project URL | `https://abcdefgh….supabase.co` | Connect 창 또는 Project Settings → Data API |
| 공개 키 | `sb_publishable_…` | API Keys의 **Publishable key** |
| (공개 키가 없을 때) | `eyJhbGciOi…` | API Keys의 **Legacy API keys** 탭 → **anon public** |

⚠️ **secret 키**(`sb_secret_…`)와 **service_role** 키는 복사하지 않습니다. 서버 전용 키라 밖에 나가면 안 됩니다.
공개 키는 교실 화면 파일 안에 그대로 들어가는 값이라 AI나 조승재에게 알려 주셔도 괜찮습니다. 데이터는 서버의 권한 규칙이 지킵니다.

✅ 확인: 두 값을 AI에게 알려 주세요.

### 4단계 · 시간표 함수 올리기

1. 새 탭에서 `https://scienceisjo.github.io/class-tools/geowon/sync-timetable.txt`를 엽니다. **Ctrl+A**로 전체 선택하고 **Ctrl+C**로 복사합니다.
2. Supabase 왼쪽 **Edge Functions** → **Deploy a new function** → **Via Editor**를 고릅니다.
3. 함수 이름을 정확히 **`sync-timetable`**로 적습니다.
4. 편집기에 들어 있는 예시 코드를 **모두 지우고**, 복사한 코드를 붙여 넣습니다(부록 B와 같은 내용).
5. **Deploy function**을 누릅니다.
6. 다 올라가면 함수 화면의 **Details** 탭에서 **Verify JWT**(「Enforce JWT verification」으로 보일 수도 있음) 스위치를 **끄고** 저장합니다.
   - 이유: 새 공개 키(`sb_publishable_`)는 JWT가 아니라서, 켜 두면 아침 예약 실행이 막힐 수 있습니다. 이 함수는 컴시간 시간표를 받아 오기만 하므로 꺼도 안전합니다.
   - 함수를 다시 Deploy하면 이 스위치가 다시 켜지는 경우가 있으니 그때마다 확인해 주세요.

✅ 확인: Edge Functions 목록에 `sync-timetable`이 보이면 됩니다. 실제로 돌려 보는 것은 8단계에서 합니다.

### 5단계 · 설치 SQL 실행 (두 번에 나눠서)

먼저 **브라우저 자동 번역을 끕니다.**

**① 1부: 그대로 복사해서 실행**
1. 새 탭에서 `https://scienceisjo.github.io/class-tools/geowon/install-part1.txt`를 열고 **Ctrl+A**, **Ctrl+C**로 복사합니다.
   표 20개·권한 규칙·거원중학교 정보가 들어 있고, 고칠 곳이 없습니다(부록 A-1과 같은 내용).
2. Supabase 왼쪽 **SQL Editor** → **New query**(또는 **+**) → 붙여 넣기 → **Run**(Ctrl+Enter)을 누릅니다.
3. 「destructive operation」 같은 경고 창이 뜨면 **Run this query**를 누릅니다. 권한 규칙을 지우고 다시 만드는 부분 때문에 뜨는 경고이고, 새 프로젝트라 지워질 데이터는 없습니다.

✅ 확인: 아래 결과 칸에 **Success**(No rows returned)가 나오면 됩니다.

**② 2부: AI가 값을 넣어 준 짧은 SQL 실행**

> 🤖 AI에게: **부록 A-2**에서 아래 세 곳을 바꾼 완성본을 드리세요. 짧은 SQL이라 통째로 드려도 됩니다.
> - `__SIGNUP_CODE__` → 선생님이 정한 가입 코드 (영문·숫자, 예: `geowon2026!`, 작은따옴표 `'`는 쓰지 않게)
> - `__PROJECT_URL__` → 프로젝트 주소 (끝에 `/` 없이, 예: `https://abcd.supabase.co`)
> - `__ANON_KEY__` → 공개 키 (**두 군데** 모두)

1. SQL Editor에서 **New query**를 하나 더 열고, AI가 준 2부를 붙여 넣어 **Run**합니다.

✅ 확인: 맨 아래 결과 한 줄이 아래와 같으면 성공입니다.
**표_20개면_정상 = 20 · 학교 = 거원중학교 · 권한규칙_수 = 59 · 가입코드_1이면_정상 = 1 · 예약_1이면_정상 = 1**

- 권한규칙_수가 59보다 적으면 1부가 덜 복사된 것입니다. 1부를 다시 복사해서 실행해 주세요.
- 두 부분 모두 여러 번 실행해도 괜찮습니다. 2부를 다시 실행하면 가입 코드가 그 값으로 바뀝니다. 가입 코드는 나중에 관리 화면 ⚙️ 설정에서도 바꿀 수 있습니다.

### 6단계 · 화면 연결 — A 또는 B

#### A. 조승재 주소 그대로 쓰기 (가장 간단)

1. 3단계의 **프로젝트 주소**와 **공개 키** 두 값을 조승재(해누리중)에게 보내 주세요(메신저로 보내셔도 됩니다).
2. 제가 연결하면 몇 분 뒤 `https://scienceisjo.github.io/class-tools/geowon/`가 「곧 열립니다」 대신 **어느 반 화면을 띄우실까요?**로 바뀝니다.
3. 종 시간·요일변경·부서처럼 화면 설정을 바꿀 일이 생기면 저에게 알려 주세요. 공지·계정·쪽지는 모두 거원중학교 서버에 있어서 저는 볼 수 없습니다.

#### B. 직접 배포 (화면까지 거원중학교에서 관리)

1. **파일 받기**: `https://scienceisjo.github.io/class-tools/geowon/geowon-board.zip`를 내려받아 압축을 풉니다(화면 파일과 이 안내서가 들어 있습니다).
2. **github.com**에 가입·로그인 → 오른쪽 위 **+** → **New repository**를 누릅니다.
   - Repository name: `geowon-board`
   - **Public** 선택 → **Create repository**
3. 새 저장소 화면의 **uploading an existing file**을 누르고, 압축 푼 **파일들**(폴더가 아니라 안의 파일 전부)을 끌어다 놓은 뒤 → **Commit changes**를 누릅니다.
4. 저장소에서 **school.js**를 열고 → 연필 모양(**Edit**)을 누릅니다. 아래 네 줄을 고쳐 **Commit changes**를 누릅니다.
   > 🤖 AI에게: 선생님 값으로 바꾼 네 줄을 그대로 보여 드리세요. 따옴표와 줄 끝 쉼표는 그대로 둡니다.

   ```js
   "supabaseUrl": "https://프로젝트주소.supabase.co",
   "supabaseKey": "sb_publishable_공개키",
   "home": "깃허브아이디.github.io/geowon-board/",
   "contact": "홍길동 (정보부)",
   ```
   `contact`는 사용법 페이지의 「문의」에 나오는 이름입니다.
5. 저장소 **Settings** → 왼쪽 **Pages** → Source: **Deploy from a branch** → Branch: **main** / **(root)** → **Save**를 누릅니다.
6. 보통 1~2분, 길면 10분쯤 뒤 Pages 화면 위쪽에 `https://깃허브아이디.github.io/geowon-board/` 주소(**Visit site**)가 나옵니다. 안 보이면 새로 고침해 보세요.

✅ 확인: 그 주소를 열면 「곧 열립니다」가 아니라 **어느 반 화면을 띄우실까요?**가 나오면 됩니다.

- 나중에 설정을 바꿀 때는 `school.js`만 고치면 몇 분 뒤 반영됩니다. 전자칠판은 매일 새벽 4시쯤 저절로 새로 고침됩니다.
- 새 기능이 담긴 묶음을 받으시면 **school.js만 빼고** 나머지 파일을 덮어 올리시면 됩니다.

### 7단계 · 첫 가입 (= 관리 담당자)

1. 관리 화면을 엽니다. A는 `https://scienceisjo.github.io/class-tools/geowon/admin.html`, B는 `내 주소/admin.html`입니다.
2. **가입** 탭에서 이름 · 이메일 · 비밀번호(6자 이상) · **가입 코드**를 넣습니다. 과목 · 부서 · 담임 반은 넣어도 되고 비워 두셔도 됩니다.
3. **이 학교에서 처음 가입한 사람은 자동으로 관리 담당자(👑)가 됩니다.** 세팅하시는 선생님이 꼭 먼저 가입해 주세요.

그다음 다른 선생님들께 관리 주소와 가입 코드를 알려 드립니다.
- 선생님들이 가입하면 「승인 대기」가 됩니다.
- 관리 담당자가 **⚙️ 설정 → 👥 교사 계정 승인**에서 승인하면 그때부터 글을 쓸 수 있습니다.
- 여러 선생님이 함께 쓰는 **공동계정**을 원하시면 **부록 C**를 보세요.

✅ 확인: 로그인 뒤 오른쪽 위에 「○○○ 선생님」이 보이고, ⚙️ 설정 탭에 「👥 교사 계정 승인」 카드가 보이면 됩니다.

### 8단계 · 시간표 처음 받아 보기 (꼭 해 주세요)

예약은 **평일 아침 8:30**에 저절로 돕니다. 함수가 제대로 도는지 지금 한 번 직접 돌려 봅니다.

1. **Edge Functions → sync-timetable** → 오른쪽 위 **Test**(또는 **Invoke**) → **Send request**를 누릅니다.
2. 응답이 `{"ok":true,"rows":90}`처럼 나오면 됩니다. rows는 반 수 × 5일입니다(18개 반 × 5 = 90).
3. SQL Editor에서 아래를 실행해 숫자를 확인합니다.
   ```sql
   SELECT count(*) AS 받은_시간표 FROM timetables;                                         -- 90 이면 정상
   SELECT ok, rows, message, created_at FROM timetable_sync_log ORDER BY id DESC LIMIT 3;   -- 받기 기록
   SELECT jobname, schedule, active FROM cron.job;                                         -- 아침 예약
   ```

✅ 확인: Test 응답이 `"ok":true`이고 **받은_시간표 = 90**이면 성공입니다.
⚠️ 교실 화면만 보고 판단하지 마세요. 교실 화면에는 미리 넣어 둔 시간표가 들어 있어서, 받기가 실패해도 시간표가 보입니다. 이때는 결보강 변경만 나오지 않습니다.

### 9단계 · 교실 전자칠판에 켜기

1. 전자칠판 브라우저에서 교실 화면 주소를 엽니다. A는 `https://scienceisjo.github.io/class-tools/geowon/`, B는 내 주소입니다.
2. **우리 반**을 누르고, 화면 안내대로 **작업 표시줄에 고정**(또는 홈 화면에 추가)합니다. 다음부터는 아이콘 한 번이면 우리 반 화면이 열립니다.
3. 전자칠판은 켜 두기만 하면 됩니다. 아침에 켜는 일은 학생 1인1역으로 맡기셔도 좋습니다.
4. 선생님들께는 **사용법** 페이지(guide.html) 주소를 공유해 주세요.

---

## 6. 🛠 문제 해결

| 증상 | 원인 | 할 일 |
|---|---|---|
| 「곧 열립니다」만 나옴 | 화면에 서버 주소·키가 아직 없음 | 6단계 (A는 조승재에게 연락, B는 `school.js`) |
| 가입하니 「메일 인증」 안내가 나옴 | Confirm email이 켜져 있음 | 2단계 다시 보기. 이미 가입한 사람은 Authentication → Users에서 지우고 다시 가입 |
| 「가입 코드가 올바르지 않습니다」 | 코드가 다름 | SQL Editor에서 `SELECT value FROM display_config WHERE key = 'admin_code';` |
| 가입했는데 글이 안 올라감 · 「row-level security」 오류 | 아직 승인 전 | 관리 담당자가 ⚙️ 설정에서 승인 |
| 관리 담당자가 엉뚱한 사람이 됨 | 다른 사람이 먼저 가입함 | 부록 C의 「관리 담당자 바꾸기」 SQL |
| 시간표 받기 기록(8단계)에 **아무 줄도 없음** | 함수가 아예 안 돌았음 (대부분 Verify JWT가 켜져 있음) | SQL Editor에서 `SELECT status_code, content, created FROM net._http_response ORDER BY id DESC LIMIT 3;` 실행. 401이면 4단계 6번 Verify JWT 끄기. Edge Functions → sync-timetable → **Logs**에서도 보입니다 |
| 받기 기록에 `ok = false`, message에 **permission denied** | 표 권한이 없음 (옛 설치 SQL) | 5단계 1부를 다시 복사해서 실행 |
| 받기 기록에 `ok = false`, message에 **컴시간 응답 오류** | 컴시간 서버 일시 오류 | 잠시 뒤 8단계 Test 다시 |
| 결보강 변경이 화면에 안 나옴 | 시간표 받기가 안 되고 있음 (화면엔 미리 넣은 시간표가 나옴) | 8단계 확인 다시 |
| 급식이 안 나옴 | 나이스 코드 문제이거나 방학 | 학기 중인데도 안 나오면 SQL Editor에서 `SELECT * FROM display_config;`의 neis 값 확인 |
| 오랜만에 열었더니 아무것도 안 나옴 | 무료 프로젝트는 7일 넘게 아무 요청이 없으면 잠듦 (방학 등) | Supabase 대시보드에서 **Resume project** |
| SQL 실행 때 이상한 문법 오류 | 자동 번역이 SQL을 바꿨거나 덜 복사됨 | 번역을 끄고, 주소에서 다시 전체 복사 |

---

## 7. 학교에 맞게 채우기 (자료를 AI에게 주고 하세요)

`school.js`는 **B(직접 배포)** 에서만 직접 고칩니다. **A**에서는 바꿀 내용을 조승재에게 알려 주세요.

### 📅 학사일정 (선택)
나이스 학사일정(방학·시험·공휴일)은 저절로 나옵니다. 학교 자체 행사(창체, 축제, 체험학습, 요일변경 수업 등)를 「주요일정」에 더 넣고 싶으시면 이렇게 하세요.
- 학사일정 파일(한글·PDF·사진)을 AI에게 주고 「**부록 D 양식으로 SQL 만들어 줘**」라고 하신 뒤, SQL Editor에서 실행합니다.
- 하나씩 넣으실 때는 관리 화면의 **📅 주요일정** 탭을 쓰시면 됩니다.

### 🔁 요일변경 수업 (예: 수요일에 금요일 시간표로 수업)
그날 교실 화면이 바뀐 요일의 시간표를 보여 줍니다. `school.js`의 `daySwap`에 날짜와 요일 번호(1=월 2=화 3=수 4=목 5=금)를 넣습니다.
```js
"daySwap": { "2026-11-03": 5, "2027-01-06": 5 },
```

### 🔔 종 시간
`school.js`의 `bell`입니다. 한 줄에 시간 하나이고, `days`는 그 요일에만 있는 교시입니다(2=화, 4=목).
```js
{ "label": "7교시", "s": "15:10", "e": "15:55", "days": [2, 4] }
```

### 🏫 반 목록에서 빼기 (예: 없는 1학년 6반)
반 고르기 화면은 `school.js`의 `ttBase`(미리 넣어 둔 시간표)에서 반 목록을 만듭니다. `ttBase` 안에서 `"1-6": [`로 시작해 짝이 맞는 `]`까지의 덩어리를 통째로 지웁니다. 덩어리 사이 쉼표가 하나만 남도록 주의하세요. 컴시간 시간표 받기는 그대로 둡니다.
> 🤖 AI에게: 선생님이 school.js 내용을 붙여 주시면, 그 반을 뺀 `ttBase` 부분을 정확한 JSON으로 다시 드리세요.

### 🏢 부서 · 🏃 특별실
`school.js`의 `depts`(부서 이름 목록)와 `places`(`["이모지", "장소 이름"]` 목록)입니다.

### 🎂 생일
관리 화면 🎂 생일 탭에 `이름 9월 3일` 또는 `이름 2011-09-03` 형식으로 여러 줄을 붙여 넣으면 됩니다. 태어난 해는 저장하지 않고, 교실 화면에는 이번 달 생일만 나옵니다.

---

## 8. 🔒 보안·개인정보 메모

- 화면 파일에 들어가는 **공개 키**는 원래 공개되는 값입니다. 데이터는 서버의 권한 규칙이 지킵니다.
  - 글쓰기는 **승인된 선생님**만 할 수 있습니다.
  - 학생 쪽지는 **개인 계정 선생님**만 읽습니다(공동계정·교실 화면은 못 읽음).
  - 생일은 교실 화면에 **이번 달 것만** 나옵니다.
  - 가입 코드는 서버가 직접 확인하고, 스스로 승인하거나 관리 담당자로 올리는 것은 막혀 있습니다.
- **secret / service_role 키, 데이터베이스 비밀번호**는 어디에도 붙여 넣지 마세요.
- 학생 이름이 들어가는 기능(호출·생일·청소당번)은 학교 개인정보 지침에 맞게 써 주세요.

---

## 부록 A-1 · 설치 SQL 1부 (고칠 곳 없음 — `https://scienceisjo.github.io/class-tools/geowon/install-part1.txt` 와 같음)

```sql
-- ═══════════════════════════════════════════════════════════════════
-- 📺 전자칠판 알리미 — 새 학교 설치 (한 번에 전부)
-- -------------------------------------------------------------------
-- 새로 만든 Supabase 프로젝트의 SQL Editor 에 통째로 붙여넣고 Run.
-- 여러 번 실행해도 안전합니다.
--
-- 이 파일 하나로:
--   표 20개 · 권한 규칙 · 가입 코드 확인 · 첫 가입자 = 관리 담당자
--   · 컴시간 시간표 매일 08:30 자동 받기 예약까지 끝납니다.
--
-- 🔒 해누리 초기판보다 단단하게:
--   글쓰기·고치기는 "승인된 선생님"만 됩니다(로그인만으로는 안 됨).
--   가입 코드도 서버가 직접 확인하고, 스스로 승인·관리자 권한을
--   올리는 것을 막아 둡니다.
--
-- ⚠️ 붙여넣기 전 브라우저 자동번역을 꺼 주세요 (SQL 글자가 바뀌어 오류가 납니다)
-- ═══════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────
-- 0. 확장 기능 (시간표 예약 실행용)
-- ───────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;


-- ───────────────────────────────────────────────────────────────────
-- 1. 표
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS display_config (
  key        text PRIMARY KEY,
  value      text,
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notice_admins (                 -- 공지 관리 선생님
  auth_id    uuid PRIMARY KEY,
  name       text NOT NULL,
  subject    text,
  dept       text,
  hr_grade   int,                                          -- 담임 학년·반
  hr_class   int,
  approved   boolean DEFAULT false,
  is_owner   boolean DEFAULT false,                        -- 관리 담당자
  is_shared  boolean DEFAULT false,                        -- 공동계정
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notices (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category    text NOT NULL DEFAULT '일반' CHECK (category IN ('긴급','교과','학년','일반')),
  title       text NOT NULL,
  body        text,
  grade       int,
  class_no    int,
  subject     text,
  dept        text,
  link        text,
  pinned      boolean DEFAULT false,
  start_at    date DEFAULT CURRENT_DATE,
  end_at      date,
  author_id   uuid,
  author_name text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS schedules (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title       text NOT NULL,
  start_date  date NOT NULL,
  end_date    date,
  location    text,
  icon        text DEFAULT '📌',
  grade       int,
  class_no    int,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS timetable_changes (             -- 예전 수동 변경(지금은 컴시간 자동)
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  change_date date NOT NULL,
  grade       int,
  class_no    int,
  period      int,
  before_subj text,
  after_subj  text,
  note        text,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ddays (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title       text NOT NULL,
  target_date date NOT NULL,
  type        text NOT NULL DEFAULT '기타' CHECK (type IN ('시험','평가','방학','기타')),
  icon        text DEFAULT '🎯',
  grade       int,
  class_no    int,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS assessments (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  subject     text NOT NULL,
  title       text NOT NULL,
  assess_type text NOT NULL DEFAULT '수행평가' CHECK (assess_type IN ('지필평가','수행평가','기타')),
  assess_date date NOT NULL,
  grade       int,
  class_no    int,
  scope       text,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS calls (                          -- 학생 호출
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_name text NOT NULL,
  grade        int,
  class_no     int,
  student_id   uuid,
  teacher_name text NOT NULL,
  location     text DEFAULT '교무실',
  reason       text,
  status       text NOT NULL DEFAULT 'active' CHECK (status IN ('active','done')),
  author_id    uuid,
  created_at   timestamptz DEFAULT now(),
  done_at      timestamptz
);

CREATE TABLE IF NOT EXISTS cleaning_duties (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grade      int NOT NULL,
  class_no   int NOT NULL,
  area       text NOT NULL,
  members    text NOT NULL,
  note       text,
  sort_order int DEFAULT 0,
  author_id  uuid,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS lost_items (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  item_name   text NOT NULL,
  found_place text,
  keep_place  text DEFAULT '교무실',
  photo_url   text,
  status      text NOT NULL DEFAULT 'active' CHECK (status IN ('active','returned')),
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS class_roles (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grade      int NOT NULL,
  class_no   int NOT NULL,
  role       text NOT NULL,
  member     text NOT NULL,
  icon       text DEFAULT '🙋',
  sort_order int DEFAULT 0,
  author_id  uuid,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS class_locations (               -- 수업 장소
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  loc_date   date NOT NULL DEFAULT CURRENT_DATE,
  grade      int,
  class_no   int,
  period     int,
  subject    text NOT NULL,
  location   text NOT NULL,
  note       text,
  author_id  uuid,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS messages (                       -- 학생 → 선생님 쪽지
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  to_teacher   text,
  to_auth_id   uuid,
  student_name text,
  grade        int,
  class_no     int,
  category     text NOT NULL DEFAULT '하고 싶은 말'
               CHECK (category IN ('하고 싶은 말','질문','건의','고민·상담','도움 요청')),
  body         text NOT NULL CHECK (length(body) BETWEEN 1 AND 1000),
  is_anonymous boolean DEFAULT false,
  status       text NOT NULL DEFAULT 'unread' CHECK (status IN ('unread','read','done')),
  created_at   timestamptz DEFAULT now(),
  read_at      timestamptz
);

CREATE TABLE IF NOT EXISTS message_reads (
  message_id bigint NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  reader_id  uuid   NOT NULL,
  read_at    timestamptz DEFAULT now(),
  PRIMARY KEY (message_id, reader_id)
);

CREATE TABLE IF NOT EXISTS audit_log (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name text,
  action     text,
  row_id     bigint,
  summary    text,
  actor_id   uuid,
  actor_name text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS timetables (                     -- 컴시간에서 받은 시간표
  class_key  text NOT NULL,
  weekday    int  NOT NULL,
  periods    jsonb NOT NULL,
  changed    int[] NOT NULL DEFAULT '{}',
  source     text,
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (class_key, weekday)
);

CREATE TABLE IF NOT EXISTS timetable_sync_log (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ok         boolean,
  rows       int,
  message    text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS videos (
  id          bigserial PRIMARY KEY,
  title       text NOT NULL,
  url         text NOT NULL,
  note        text,
  grade       int,
  class_no    int,
  start_at    date NOT NULL DEFAULT current_date,
  end_at      date,
  sort_order  int  NOT NULL DEFAULT 0,
  author_id   uuid,
  author_name text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS birthdays (
  id         bigserial PRIMARY KEY,
  grade      int  NOT NULL,
  class_no   int  NOT NULL,
  name       text NOT NULL,
  month      int  NOT NULL CHECK (month BETWEEN 1 AND 12),
  day        int  NOT NULL CHECK (day   BETWEEN 1 AND 31),
  author_id  uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (grade, class_no, name, month, day)
);

CREATE TABLE IF NOT EXISTS shared_posters (                 -- 공동계정 「지금 쓰시는 선생님」 명단
  name    text PRIMARY KEY,
  subject text,
  dept    text,
  uses    int NOT NULL DEFAULT 0,
  used_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notices_window   ON notices(start_at, end_at);
CREATE INDEX IF NOT EXISTS idx_notices_created  ON notices(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_schedules_date   ON schedules(start_date);
CREATE INDEX IF NOT EXISTS idx_ttc_date         ON timetable_changes(change_date);
CREATE INDEX IF NOT EXISTS idx_ddays_date       ON ddays(target_date);
CREATE INDEX IF NOT EXISTS idx_assess_date      ON assessments(assess_date);
CREATE INDEX IF NOT EXISTS idx_calls_status     ON calls(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_clean_class      ON cleaning_duties(grade, class_no, sort_order);
CREATE INDEX IF NOT EXISTS idx_lost_status      ON lost_items(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_loc_date         ON class_locations(loc_date);
CREATE INDEX IF NOT EXISTS idx_roles_class      ON class_roles(grade, class_no, sort_order);
CREATE INDEX IF NOT EXISTS idx_msg_status       ON messages(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_msg_to           ON messages(to_auth_id);
CREATE INDEX IF NOT EXISTS idx_audit_created    ON audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tt_updated       ON timetables(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_videos_class     ON videos(grade, class_no);
CREATE INDEX IF NOT EXISTS idx_birthdays_class  ON birthdays(grade, class_no, month, day);


-- ───────────────────────────────────────────────────────────────────
-- 2. 판별 함수 (정책 안에서 표를 직접 보면 무한 반복이 나므로 함수로)
-- ───────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION is_notice_staff()               -- 승인된 선생님인가
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT EXISTS (SELECT 1 FROM notice_admins WHERE auth_id = auth.uid() AND approved);
$fn$;

CREATE OR REPLACE FUNCTION is_notice_owner()               -- 관리 담당자인가
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT EXISTS (SELECT 1 FROM notice_admins WHERE auth_id = auth.uid() AND approved AND is_owner);
$fn$;

CREATE OR REPLACE FUNCTION is_shared_account()             -- 공동계정인가
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT COALESCE((SELECT is_shared FROM notice_admins WHERE auth_id = auth.uid()), false);
$fn$;

CREATE OR REPLACE FUNCTION is_homeroom_of(p_grade int, p_class int)   -- 그 반 담임인가
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT EXISTS (SELECT 1 FROM notice_admins
                 WHERE auth_id = auth.uid() AND approved
                   AND hr_grade = p_grade AND hr_class = p_class);
$fn$;

-- 가입 코드가 맞는지만 대답 (코드 값은 밖으로 안 나감)
CREATE OR REPLACE FUNCTION check_admin_code(code text)
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT EXISTS (SELECT 1 FROM display_config WHERE key = 'admin_code' AND value = code);
$fn$;

-- 선생님 등록 — 서버가 가입 코드를 확인하고 등록. 이 학교 첫 가입자는 관리 담당자.
CREATE OR REPLACE FUNCTION register_notice_admin(
  p_code text, p_name text, p_subject text, p_dept text, p_hr_grade int, p_hr_class int)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $fn$
DECLARE
  v_uid   uuid := auth.uid();
  v_first boolean;
BEGIN
  IF v_uid IS NULL THEN RETURN 'no_session'; END IF;
  IF NOT EXISTS (SELECT 1 FROM display_config WHERE key = 'admin_code' AND value = p_code) THEN
    RETURN 'bad_code';
  END IF;
  IF EXISTS (SELECT 1 FROM notice_admins WHERE auth_id = v_uid) THEN
    RETURN CASE WHEN (SELECT approved FROM notice_admins WHERE auth_id = v_uid) THEN 'approved' ELSE 'pending' END;
  END IF;
  PERFORM pg_advisory_xact_lock(424242);                   -- 첫 가입자 판정이 겹치지 않게
  v_first := NOT EXISTS (SELECT 1 FROM notice_admins WHERE is_owner);
  INSERT INTO notice_admins (auth_id, name, subject, dept, hr_grade, hr_class, approved, is_owner)
  VALUES (v_uid, btrim(p_name), NULLIF(btrim(COALESCE(p_subject, '')), ''), NULLIF(btrim(COALESCE(p_dept, '')), ''),
          CASE WHEN p_hr_grade IS NOT NULL AND p_hr_class IS NOT NULL THEN p_hr_grade END,
          CASE WHEN p_hr_grade IS NOT NULL AND p_hr_class IS NOT NULL THEN p_hr_class END,
          v_first, v_first);
  RETURN CASE WHEN v_first THEN 'owner' ELSE 'pending' END;
END
$fn$;

-- 청소당번 한 반 통째로 바꾸기
CREATE OR REPLACE FUNCTION replace_cleaning(p_grade int, p_class int, p_rows jsonb, p_author uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $fn$
BEGIN
  IF NOT is_notice_staff() THEN RAISE EXCEPTION '승인된 선생님만 바꿀 수 있습니다'; END IF;
  DELETE FROM cleaning_duties WHERE grade = p_grade AND class_no = p_class;
  INSERT INTO cleaning_duties (grade, class_no, area, members, note, sort_order, author_id)
  SELECT p_grade, p_class, COALESCE(r->>'area', ' '), COALESCE(r->>'members', ' '),
         NULLIF(r->>'note', ''), COALESCE((r->>'sort_order')::int, 0), auth.uid()
  FROM jsonb_array_elements(p_rows) r;
END
$fn$;

-- 공동계정 이름 명단에 기록
CREATE OR REPLACE FUNCTION touch_poster(p_name text, p_subject text, p_dept text)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $fn$
  INSERT INTO shared_posters (name, subject, dept, uses, used_at)
  SELECT btrim(p_name), NULLIF(btrim(COALESCE(p_subject, '')), ''), NULLIF(btrim(COALESCE(p_dept, '')), ''), 1, now()
  WHERE is_notice_staff() AND btrim(COALESCE(p_name, '')) <> ''
  ON CONFLICT (name) DO UPDATE
    SET subject = COALESCE(EXCLUDED.subject, shared_posters.subject),
        dept    = COALESCE(EXCLUDED.dept,    shared_posters.dept),
        uses    = shared_posters.uses + 1,
        used_at = now();
$fn$;

REVOKE ALL ON FUNCTION is_notice_staff()                         FROM public;
REVOKE ALL ON FUNCTION is_notice_owner()                         FROM public;
REVOKE ALL ON FUNCTION is_shared_account()                       FROM public;
REVOKE ALL ON FUNCTION is_homeroom_of(int, int)                  FROM public;
REVOKE ALL ON FUNCTION check_admin_code(text)                    FROM public;
REVOKE ALL ON FUNCTION register_notice_admin(text, text, text, text, int, int) FROM public;
REVOKE ALL ON FUNCTION replace_cleaning(int, int, jsonb, uuid)   FROM public;
REVOKE ALL ON FUNCTION touch_poster(text, text, text)            FROM public;
GRANT EXECUTE ON FUNCTION is_notice_staff()                        TO anon, authenticated;
GRANT EXECUTE ON FUNCTION is_notice_owner()                        TO anon, authenticated;
GRANT EXECUTE ON FUNCTION is_shared_account()                      TO anon, authenticated;
GRANT EXECUTE ON FUNCTION is_homeroom_of(int, int)                 TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_admin_code(text)                   TO anon, authenticated;
GRANT EXECUTE ON FUNCTION register_notice_admin(text, text, text, text, int, int) TO authenticated;
GRANT EXECUTE ON FUNCTION replace_cleaning(int, int, jsonb, uuid)  TO authenticated;
GRANT EXECUTE ON FUNCTION touch_poster(text, text, text)           TO authenticated;


-- ───────────────────────────────────────────────────────────────────
-- 3. 자동 처리
-- ───────────────────────────────────────────────────────────────────
-- 긴급 공지는 종료일을 안 넣으면 그날만
CREATE OR REPLACE FUNCTION notices_urgent_default_end()
RETURNS trigger LANGUAGE plpgsql AS $fn$
BEGIN
  IF NEW.category = '긴급' AND NEW.end_at IS NULL THEN NEW.end_at := CURRENT_DATE; END IF;
  RETURN NEW;
END
$fn$;
DROP TRIGGER IF EXISTS trg_urgent_end ON notices;
CREATE TRIGGER trg_urgent_end BEFORE INSERT OR UPDATE ON notices
  FOR EACH ROW EXECUTE FUNCTION notices_urgent_default_end();

-- 시간표를 덮어쓸 때도 갱신 시각 바꾸기
CREATE OR REPLACE FUNCTION touch_timetable_updated()
RETURNS trigger LANGUAGE plpgsql AS $fn$
BEGIN NEW.updated_at := now(); RETURN NEW; END
$fn$;
DROP TRIGGER IF EXISTS trg_timetables_touch ON timetables;
CREATE TRIGGER trg_timetables_touch BEFORE UPDATE ON timetables
  FOR EACH ROW EXECUTE FUNCTION touch_timetable_updated();

-- 스스로 승인·관리자·공동계정 표시를 바꾸지 못하게 (관리 담당자와 SQL 편집기는 가능)
CREATE OR REPLACE FUNCTION notice_admins_guard()
RETURNS trigger LANGUAGE plpgsql AS $fn$
BEGIN
  IF auth.uid() IS NOT NULL AND NOT is_notice_owner() THEN
    NEW.auth_id   := OLD.auth_id;
    NEW.approved  := OLD.approved;
    NEW.is_owner  := OLD.is_owner;
    NEW.is_shared := OLD.is_shared;
  END IF;
  RETURN NEW;
END
$fn$;
DROP TRIGGER IF EXISTS trg_notice_admins_guard ON notice_admins;
CREATE TRIGGER trg_notice_admins_guard BEFORE UPDATE ON notice_admins
  FOR EACH ROW EXECUTE FUNCTION notice_admins_guard();


-- ───────────────────────────────────────────────────────────────────
-- 4. 권한 규칙 (RLS)
--    읽기: 교실 화면(로그인 없음)이 읽어야 하는 것은 누구나
--    쓰기: 승인된 선생님만 / 고치기·지우기: 본인 · 관리 담당자 · 그 반 담임
-- ───────────────────────────────────────────────────────────────────
-- 2026-05-30 이후 새 프로젝트는 표 권한을 저절로 주지 않으므로 직접 줍니다
-- (service_role = 시간표 함수가 쓰는 서버 역할)
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

DO $rls$
DECLARE
  t text;
  pol record;
BEGIN
  -- 이 설치가 다루는 표는 기존 규칙을 모두 지우고 새로 만듭니다 (다시 실행해도 같은 결과)
  FOR pol IN
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public' AND tablename IN (
      'display_config','notice_admins','notices','schedules','timetable_changes','ddays','assessments',
      'calls','cleaning_duties','lost_items','class_roles','class_locations','messages','message_reads',
      'audit_log','timetables','timetable_sync_log','videos','birthdays','shared_posters')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol.policyname, pol.tablename);
  END LOOP;

  FOREACH t IN ARRAY ARRAY[
      'display_config','notice_admins','notices','schedules','timetable_changes','ddays','assessments',
      'calls','cleaning_duties','lost_items','class_roles','class_locations','messages','message_reads',
      'audit_log','timetables','timetable_sync_log','videos','birthdays','shared_posters']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO anon, authenticated, service_role', t);   -- 이 앱 표만
  END LOOP;

  -- 교실 화면이 읽는 표: 누구나 읽기
  FOREACH t IN ARRAY ARRAY['notices','schedules','timetable_changes','ddays','assessments','calls',
                           'cleaning_duties','lost_items','class_roles','class_locations',
                           'timetables','timetable_sync_log','videos']
  LOOP
    EXECUTE format('CREATE POLICY %I ON %I FOR SELECT USING (true)', t || '_read', t);
  END LOOP;

  -- 학년·반이 있는 표: 승인된 선생님이 쓰고, 본인·관리 담당자·그 반 담임이 고치고 지움
  FOREACH t IN ARRAY ARRAY['notices','schedules','ddays','assessments','class_locations','videos']
  LOOP
    EXECUTE format('CREATE POLICY %I ON %I FOR INSERT WITH CHECK (is_notice_staff())', t || '_ins', t);
    EXECUTE format($p$CREATE POLICY %I ON %I FOR UPDATE USING (
        is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()
          OR (grade IS NOT NULL AND class_no IS NOT NULL AND is_homeroom_of(grade, class_no))))$p$, t || '_upd', t);
    EXECUTE format($p$CREATE POLICY %I ON %I FOR DELETE USING (
        is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()
          OR (grade IS NOT NULL AND class_no IS NOT NULL AND is_homeroom_of(grade, class_no))))$p$, t || '_del', t);
  END LOOP;

  -- 학년·반이 없는 표: 본인·관리 담당자
  FOREACH t IN ARRAY ARRAY['timetable_changes','lost_items']
  LOOP
    EXECUTE format('CREATE POLICY %I ON %I FOR INSERT WITH CHECK (is_notice_staff())', t || '_ins', t);
    EXECUTE format($p$CREATE POLICY %I ON %I FOR DELETE USING (
        is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()))$p$, t || '_del', t);
  END LOOP;
  CREATE POLICY timetable_changes_upd ON timetable_changes FOR UPDATE
    USING (is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()));
  CREATE POLICY lost_items_upd ON lost_items FOR UPDATE USING (is_notice_staff());      -- 「찾아감」은 누구나

  -- 반 운영(호출·청소·1인1역)·명단·기록: 승인된 선생님 누구나
  FOREACH t IN ARRAY ARRAY['calls','cleaning_duties','class_roles','shared_posters']
  LOOP
    EXECUTE format('CREATE POLICY %I ON %I FOR ALL USING (is_notice_staff()) WITH CHECK (is_notice_staff())', t || '_staff', t);
  END LOOP;
  CREATE POLICY shared_posters_read ON shared_posters FOR SELECT USING (is_notice_staff());
  CREATE POLICY audit_log_read ON audit_log FOR SELECT USING (is_notice_staff());
  CREATE POLICY audit_log_ins  ON audit_log FOR INSERT WITH CHECK (is_notice_staff());

  -- 🎂 생일: 선생님은 전부, 교실 화면은 이번 달만 (태어난 해는 저장 안 함)
  CREATE POLICY birthdays_read ON birthdays FOR SELECT USING (
    is_notice_staff() OR month = EXTRACT(MONTH FROM (now() AT TIME ZONE 'Asia/Seoul'))::int);
  CREATE POLICY birthdays_ins  ON birthdays FOR INSERT WITH CHECK (is_notice_staff());
  CREATE POLICY birthdays_del  ON birthdays FOR DELETE USING (
    is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()
      OR is_homeroom_of(grade, class_no)));

  -- 📮 쪽지: 학생은 보내기만, 읽기는 승인된 개인 계정 선생님만 (공동계정·교실 화면 X)
  CREATE POLICY messages_send ON messages FOR INSERT WITH CHECK (true);
  CREATE POLICY messages_read ON messages FOR SELECT USING (is_notice_staff() AND NOT is_shared_account());
  CREATE POLICY messages_upd  ON messages FOR UPDATE USING (is_notice_staff() AND NOT is_shared_account());
  CREATE POLICY messages_del  ON messages FOR DELETE USING (is_notice_staff() AND NOT is_shared_account());
  CREATE POLICY message_reads_self ON message_reads FOR ALL
    USING (auth.uid() = reader_id) WITH CHECK (auth.uid() = reader_id);

  -- 🔑 선생님 명단: 본인 것만 보이고, 관리 담당자는 전부 (등록은 register_notice_admin 함수로만)
  CREATE POLICY notice_admins_self_read  ON notice_admins FOR SELECT USING (auth.uid() = auth_id);
  CREATE POLICY notice_admins_owner_read ON notice_admins FOR SELECT USING (is_notice_owner());
  CREATE POLICY notice_admins_self_upd   ON notice_admins FOR UPDATE USING (auth.uid() = auth_id);
  CREATE POLICY notice_admins_owner_upd  ON notice_admins FOR UPDATE USING (is_notice_owner());

  -- ⚙️ 설정: 가입 코드는 선생님만 보고, 바꾸기는 관리 담당자만
  --          (반마다 쓰는 조 편성·역할 목록은 승인된 선생님 누구나)
  CREATE POLICY display_config_read  ON display_config FOR SELECT USING (key <> 'admin_code' OR is_notice_staff());
  CREATE POLICY display_config_write ON display_config FOR ALL
    USING (is_notice_owner()) WITH CHECK (is_notice_owner());
  CREATE POLICY display_config_class ON display_config FOR ALL
    USING      (is_notice_staff() AND (key LIKE 'clean\_squad\_%' OR key LIKE 'roles\_%'))
    WITH CHECK (is_notice_staff() AND (key LIKE 'clean\_squad\_%' OR key LIKE 'roles\_%'));
END
$rls$;


-- ───────────────────────────────────────────────────────────────────
-- 5. 사진 보관함 (분실물 사진)
-- ───────────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public) VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;
DROP POLICY IF EXISTS "attachments_read"   ON storage.objects;
DROP POLICY IF EXISTS "attachments_upload" ON storage.objects;
CREATE POLICY "attachments_read"   ON storage.objects FOR SELECT USING (bucket_id = 'attachments');
CREATE POLICY "attachments_upload" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'attachments' AND public.is_notice_staff());


-- ───────────────────────────────────────────────────────────────────
-- 6. 실시간 반영 (공지를 올리면 교실 화면에 바로)
-- ───────────────────────────────────────────────────────────────────
DO $rt$
DECLARE t text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
  FOREACH t IN ARRAY ARRAY['notices','schedules','timetable_changes','display_config','ddays','assessments',
                           'calls','cleaning_duties','lost_items','class_locations','class_roles','messages','videos']
  LOOP
    BEGIN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %I', t);
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END LOOP;
END
$rt$;


-- ───────────────────────────────────────────────────────────────────
-- 7. 학교 정보 (처음 한 번만 들어감 — 나중에는 관리 화면 ⚙️ 설정에서 바꿈)
-- ───────────────────────────────────────────────────────────────────
INSERT INTO display_config (key, value) VALUES
  ('school_name',   '거원중학교'),
  ('slide_seconds', '12'),
  ('neis_atpt',     'B10'),
  ('neis_school',   '7130170'),
  ('weather_lat',   '37.4937'),
  ('weather_lon',   '127.1490'),
  ('comcigan_code', '83839')
ON CONFLICT (key) DO NOTHING;
```

---

## 부록 A-2 · 설치 SQL 2부 (AI가 값 세 개를 넣어 완성: `__SIGNUP_CODE__` · `__PROJECT_URL__` · `__ANON_KEY__`)

```sql
-- ═══════════════════════════════════════════════════════════════════
-- ▼ 학교마다 다른 값 — 가입 코드 · 프로젝트 주소 · 공개 키 (여기부터 끝까지)
-- ═══════════════════════════════════════════════════════════════════

-- 8. 선생님 가입 코드 (다시 실행하면 이 값으로 바뀝니다)
INSERT INTO display_config (key, value) VALUES ('admin_code', '__SIGNUP_CODE__')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 9. 컴시간 시간표 매일 아침 8시 30분(한국시간) 자동 받기
--    (sync-timetable 함수를 먼저 올려 두어야 실제로 받아집니다)
DO $cron$
BEGIN
  PERFORM cron.unschedule('sync-timetable-daily');
EXCEPTION WHEN OTHERS THEN NULL;
END
$cron$;
SELECT cron.schedule(
  'sync-timetable-daily',
  '30 23 * * 0-4',                                         -- 23:30 UTC = 다음날 08:30 / 월~금
  $job$
  SELECT net.http_post(
    url     := '__PROJECT_URL__/functions/v1/sync-timetable',
    headers := '{"Content-Type":"application/json","apikey":"__ANON_KEY__","Authorization":"Bearer __ANON_KEY__"}'::jsonb,
    body    := '{}'::jsonb
  );
  $job$
);


-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT
  (SELECT count(*) FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name IN (
      'display_config','notice_admins','notices','schedules','timetable_changes','ddays','assessments',
      'calls','cleaning_duties','lost_items','class_roles','class_locations','messages','message_reads',
      'audit_log','timetables','timetable_sync_log','videos','birthdays','shared_posters')) AS 표_20개면_정상,
  (SELECT value FROM display_config WHERE key = 'school_name')                          AS 학교,
  (SELECT count(*) FROM pg_policies WHERE schemaname = 'public')                        AS 권한규칙_수,
  (SELECT count(*) FROM display_config WHERE key = 'admin_code' AND value <> ''
     AND value NOT LIKE '%SIGNUP_CODE%')                                                AS 가입코드_1이면_정상,
  (SELECT count(*) FROM cron.job WHERE jobname = 'sync-timetable-daily')               AS 예약_1이면_정상;
```

---

## 부록 B · 시간표 함수 `sync-timetable` (`https://scienceisjo.github.io/class-tools/geowon/sync-timetable.txt` 와 같음)

```ts
// ═══════════════════════════════════════════════════════════════════
// ⏰ sync-timetable — 컴시간알리미에서 학교 시간표를 받아 Supabase 에 저장
// ───────────────────────────────────────────────────────────────────
// Supabase Edge Function (Deno)
// 매일 아침 8:30(KST) 자동 실행되어 그날의 변경까지 반영합니다.
//
// 왜 서버에서 하나:
//   컴시간은 http 전용이고 CORS 를 허용하지 않아 브라우저에서 직접 못 부릅니다.
//   서버(Deno)는 그 제약이 없습니다.
// ═══════════════════════════════════════════════════════════════════

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// 컴시간 학교 코드 — 설정표(display_config)의 comcigan_code 를 먼저 쓰고, 없으면 이 값
// (같은 코드를 다른 학교 Supabase 에 그대로 올려도 되게)
const DEFAULT_SCHOOL_CODE = "90186";   // 해누리중학교
const COMCI_HOST  = "comci.net";
const COMCI_PORT  = 4082;

// 컴시간 조회 규칙 — 학교 페이지의 스크립트에서 확인한 값
const QUERY_PREFIX = "73629_";
const QUERY_PATH   = "36179";

async function fetchComcigan(schoolCode: string) {
  const q = btoa(`${QUERY_PREFIX}${schoolCode}_0_1`);
  const url = `http://${COMCI_HOST}:${COMCI_PORT}/${QUERY_PATH}?${q}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`컴시간 응답 오류 ${res.status}`);
  const text = new TextDecoder("utf-8").decode(await res.arrayBuffer());
  const json = text.slice(0, text.lastIndexOf("}") + 1);
  return JSON.parse(json);
}

// 컴시간은 "바뀐 교시"를 ">6011" 처럼 앞에 기호를 붙인 문자열로 알려준다.
// 그대로 나누면 숫자가 아니라서 과목이 빈칸이 되므로, 숫자만 뽑아낸다.
function codeOf(v: unknown): number {
  if (typeof v === "number") return v;
  if (typeof v === "string") return Number(v.replace(/[^0-9]/g, "")) || 0;
  return 0;
}

// 코드값 → 과목명  (분리값으로 나눈 몫이 과목, 나머지가 교사)
function subjectOf(v: unknown, subjects: string[], sep: number) {
  const code = codeOf(v);
  if (!code) return "";
  return subjects[Math.floor(code / sep)] ?? "";
}

function buildRows(d: any) {
  const subjects: string[] = d["자료492"];
  const sep: number        = d["분리"];
  const base               = d["자료481"];   // 원래 시간표
  const changed            = d["자료147"];   // 이번 주 변경 반영본
  const rows: any[] = [];

  const gradeCount = base[0];
  for (let g = 1; g <= gradeCount; g++) {
    const classCount = base[g][0];
    for (let c = 1; c <= classCount; c++) {
      for (let dy = 1; dy <= 5; dy++) {
        // 변경본이 비어 있지 않으면 그것을, 아니면 원래 표를 쓴다
        const chgDay  = changed?.[g]?.[c]?.[dy];
        const baseDay = base[g][c][dy];
        const day = (chgDay && chgDay[0] > 0) ? chgDay : baseDay;
        if (!day || !day[0]) continue;

        const periods: string[] = [];
        const chgList: number[] = [];   // 과목이 실제로 바뀐 교시
        for (let p = 1; p <= day[0]; p++) {
          const now = subjectOf(day[p], subjects, sep);
          periods.push(now);
          if (day === chgDay) {
            const was = subjectOf(baseDay?.[p], subjects, sep);
            // 교사만 바뀐 보강은 빼고, 과목이 달라진 교시만 알린다
            if (was && now && was !== now) chgList.push(p);
          }
        }
        rows.push({
          class_key: `${g}-${c}`,
          weekday: dy,
          periods,
          changed: chgList,
          source: (chgDay && chgDay[0] > 0) ? "comcigan(변경반영)" : "comcigan",
          // DEFAULT now() 는 새로 넣을 때만 적용되므로, 갱신 시각을 직접 넣는다
          updated_at: new Date().toISOString(),
        });
      }
    }
  }
  return rows;
}

// 서버 전용 키 — 예전 프로젝트는 SUPABASE_SERVICE_ROLE_KEY,
// 새 키(sb_secret_)만 있는 프로젝트는 SUPABASE_SECRET_KEYS(JSON) 의 default
function serverKey(): string {
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (legacy) return legacy;
  try {
    const keys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") || "{}");
    return keys.default || Object.values(keys)[0] as string;
  } catch {
    return "";
  }
}

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serverKey(),                                  // RLS 우회 (서버 전용 키)
  );

  try {
    const { data: cfg } = await supabase.from("display_config")
      .select("value").eq("key", "comcigan_code").maybeSingle();
    const code = (cfg?.value || "").trim() || DEFAULT_SCHOOL_CODE;
    const data = await fetchComcigan(code);
    const rows = buildRows(data);
    if (!rows.length) throw new Error("시간표를 한 건도 읽지 못했습니다");

    const { error } = await supabase
      .from("timetables")
      .upsert(rows, { onConflict: "class_key,weekday" });
    if (error) throw error;

    await supabase.from("timetable_sync_log").insert({
      ok: true, rows: rows.length,
      message: `갱신 완료 (컴시간 최종수정 ${data["자료244"] ?? "?"})`,
    });

    return new Response(
      JSON.stringify({ ok: true, rows: rows.length }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    await supabase.from("timetable_sync_log")
      .insert({ ok: false, rows: 0, message: msg });
    return new Response(
      JSON.stringify({ ok: false, error: msg }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
```

---

## 부록 C · 계정 관리 SQL (필요할 때만)

**공동계정 만들기.** 먼저 관리 화면에서 공동계정용 이메일로 **가입**합니다(이름은 「공동계정」). 그다음 아래 SQL의 이메일을 바꿔 실행합니다.
공동계정은 공지·호출 등은 쓸 수 있지만 **학생 쪽지는 볼 수 없고**, 글을 올릴 때마다 「지금 쓰시는 선생님」 이름을 고르게 됩니다.

```sql
DO $$
DECLARE v uuid := (SELECT id FROM auth.users WHERE lower(email) = lower('공동계정이메일@example.com'));
BEGIN
  IF v IS NULL OR NOT EXISTS (SELECT 1 FROM notice_admins WHERE auth_id = v) THEN
    RAISE EXCEPTION '그 이메일로 가입한 계정이 없습니다. 먼저 관리 화면에서 가입한 뒤 다시 실행하세요';
  END IF;
  UPDATE notice_admins SET approved = true, is_shared = true, is_owner = false, name = '공동계정'
   WHERE auth_id = v;
END $$;
SELECT u.email, na.name, na.approved, na.is_shared, na.is_owner
  FROM notice_admins na JOIN auth.users u ON u.id = na.auth_id;
```

**관리 담당자 바꾸기.** 다른 사람이 먼저 가입해 관리 담당자가 됐을 때 씁니다. 새 관리 담당자가 먼저 관리 화면에서 **가입**해 있어야 합니다(승인 대기여도 됩니다).

```sql
DO $$
DECLARE v uuid := (SELECT id FROM auth.users WHERE lower(email) = lower('관리담당자이메일@example.com'));
BEGIN
  IF v IS NULL OR NOT EXISTS (SELECT 1 FROM notice_admins WHERE auth_id = v) THEN
    RAISE EXCEPTION '그 이메일로 가입한 선생님이 없습니다. 먼저 관리 화면에서 가입한 뒤 다시 실행하세요';
  END IF;
  UPDATE notice_admins SET is_owner = (auth_id = v), approved = (approved OR auth_id = v);
END $$;
SELECT u.email, na.name, na.approved, na.is_owner
  FROM notice_admins na JOIN auth.users u ON u.id = na.auth_id;
```

---

## 부록 D · 학사일정 SQL 양식 (AI가 학사일정 파일을 보고 채움)

> 🤖 AI에게: 선생님이 준 학사일정에서 **학교 자체 행사만** 골라 아래 형식으로 만드세요.
> - 나이스에서 저절로 나오는 **개학·방학·지필고사·공휴일은 넣지 마세요**(교실 화면에 두 번 나옵니다).
> - 날짜는 `YYYY-MM-DD`이고, 하루짜리는 `end_date`를 `NULL`로 둡니다. 학년 행사는 제목에 「(1학년)」처럼 적습니다.
> - 아이콘은 아래 표에서 고릅니다.
> - 맨 위 `DELETE`는 다시 실행해도 겹치지 않게 하는 줄이니 그대로 두세요. **예전에 SQL로 넣은 줄만** 지우고, 선생님들이 관리 화면에서 넣은 일정은 지우지 않습니다.

| 아이콘 | 쓰임 |
|---|---|
| 🎓 | 창체·입학식·졸업식 |
| 🎨 | 체험학습·현장학습 |
| 🔁 | 요일변경 수업 |
| 🎤 | 축제·발표회·대회 |
| ✏️ | 단축수업·기타 |
| 🏫 | 학교 행사 (전체) |

```sql
DELETE FROM schedules
 WHERE author_id IS NULL AND icon IN ('🏫','🎓','🎨','🔁','🎤','✏️');

INSERT INTO schedules (title, start_date, end_date, icon) VALUES
  ('창체 · 동아리 발표',      '2026-11-06', NULL,         '🎓'),
  ('금요일 수업 (화요일)',    '2026-11-03', NULL,         '🔁'),
  ('현장체험학습 (2학년)',    '2026-11-12', NULL,         '🎨'),
  ('학교 축제',               '2026-12-30', NULL,         '🎤');

SELECT title, start_date, end_date, icon FROM schedules ORDER BY start_date;
```
(위 네 줄은 형식 예시입니다. 거원중학교 학사일정으로 바꿔 주세요.)
