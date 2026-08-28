# AI 에이전트 개발환경 자동 설치

Orca ADE + Claude Code + Hermes 를 원라이너 하나로 설치합니다.

## 설치 항목

| 도구 | 역할 |
|------|------|
| Git + GitHub CLI | 버전관리, 협업 |
| Orca ADE | AI 에이전트 병렬 실행 환경 |
| Node.js | Claude Code 런타임 |
| Claude Code | Anthropic AI 코딩 에이전트 |
| Hermes | AI 오케스트레이터 (멀티 에이전트 허브) |

---

## 맥북 (macOS) - 터미널에서 실행

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/setup-mac.sh | bash
```

또는 로컬 파일 실행:

```bash
bash setup-mac.sh
```

---

## 그램 (Windows) - PowerShell에서 실행

```powershell
iex (irm https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/setup-win.ps1)
```

또는 로컬 파일 실행:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup-win.ps1
```

---

## 사전 준비

- **Anthropic API 키**: https://console.anthropic.com → API Keys → Create Key
- **맥북**: 관리자 비밀번호 (Homebrew 설치 시 필요)
- **그램**: 인터넷 연결 (winget 자동 다운로드)

---

## 설치 후 첫 실행 순서

```
1. 터미널 재시작 (PATH 적용)
2. hermes setup          <- Hermes 초기 설정 (모델, API 키)
3. Orca ADE 실행         <- Launchpad (맥) / 시작메뉴 (윈도우)
4. claude --version      <- Claude Code 확인
```

---

## 트러블슈팅

### 맥북: brew 명령어 없음 (Apple Silicon)
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 맥북: claude 명령어 없음
```bash
export PATH="$HOME/.npm-global/bin:$PATH"
source ~/.zshrc
```

### Windows: 실행 정책 오류
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### hermes 명령어 없음
```bash
# macOS/Linux
export PATH="$HOME/.hermes/bin:$PATH"
source ~/.zshrc

# Windows: 새 PowerShell 창 열기
```

---

## 문의

설치 중 문제가 생기면 Hermes에게 물어보세요:
```
hermes "설치 중에 이런 오류가 났어: [오류 메시지]"
```
