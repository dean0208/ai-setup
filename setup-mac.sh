#!/usr/bin/env bash
# =============================================================================
#  AI 개발환경 자동 설치 스크립트 - macOS
#  설치 항목: Homebrew, Git, Orca ADE, Node.js, Claude Code, Hermes, gh CLI
#  사용법: curl -fsSL <URL>/setup-mac.sh | bash
#          또는 로컬 실행: bash setup-mac.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()    { echo -e "${BLUE}[*]${RESET} $1"; }
ok()     { echo -e "${GREEN}[✓]${RESET} $1"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $1"; }
error()  { echo -e "${RED}[✗]${RESET} $1"; exit 1; }
section(){ echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${RESET}"; }

echo ""
echo -e "${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║   AI 에이전트 개발환경 자동 설치 (macOS)     ║"
echo "  ║   Orca ADE + Claude Code + Hermes             ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  이 스크립트는 다음 항목을 자동 설치합니다:"
echo "  • Homebrew (패키지 매니저)"
echo "  • Git + GitHub CLI (gh)"
echo "  • Orca ADE (AI 에이전트 개발환경)"
echo "  • Node.js"
echo "  • Claude Code (Anthropic AI 코딩 에이전트)"
echo "  • Hermes (AI 오케스트레이터)"
echo ""
read -rp "  계속 진행할까요? (y/N) " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "취소됨."; exit 0; }

# ─────────────────────────────────────────────
section "1/7  Homebrew"
# ─────────────────────────────────────────────
if command -v brew &>/dev/null; then
  ok "Homebrew 이미 설치됨 ($(brew --version | head -1))"
else
  log "Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon PATH 처리
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
  ok "Homebrew 설치 완료"
fi

# ─────────────────────────────────────────────
section "2/7  Git"
# ─────────────────────────────────────────────
if command -v git &>/dev/null; then
  ok "Git 이미 설치됨 ($(git --version))"
else
  log "Git 설치 중..."
  brew install git
  ok "Git 설치 완료"
fi

# ─────────────────────────────────────────────
section "3/7  GitHub CLI (gh)"
# ─────────────────────────────────────────────
if command -v gh &>/dev/null; then
  ok "GitHub CLI 이미 설치됨 ($(gh --version | head -1))"
else
  log "GitHub CLI 설치 중..."
  brew install gh
  ok "GitHub CLI 설치 완료"
fi

echo ""
if gh auth status &>/dev/null; then
  ok "GitHub 이미 로그인됨"
else
  echo "  GitHub Personal Access Token(PAT)이 필요합니다."
  echo ""
  echo "  ① 아래 주소를 브라우저에서 열어주세요:"
  echo "     https://github.com/settings/tokens/new"
  echo ""
  echo "  ② Note 칸에 아무 이름 입력 → 맨 아래 [Generate token] 클릭"
  echo "  ③ 생성된 토큰(ghp_...) 복사"
  echo ""
  read -rsp "  여기에 토큰 붙여넣기 (입력해도 화면에 안 보임): " gh_token
  echo ""
  if [[ -n "$gh_token" ]]; then
    echo "$gh_token" | gh auth login --with-token
    ok "GitHub 로그인 완료"
  else
    warn "토큰 없이 건너뜀. 나중에 직접 실행: gh auth login"
  fi
fi

# ─────────────────────────────────────────────
section "4/7  Orca ADE"
# ─────────────────────────────────────────────
if [[ -d "/Applications/Orca.app" ]]; then
  ok "Orca ADE 이미 설치됨"
else
  log "Orca ADE 설치 중..."
  brew install --cask stablyai/orca/orca
  ok "Orca ADE 설치 완료"
fi

# ─────────────────────────────────────────────
section "5/7  Node.js"
# ─────────────────────────────────────────────
if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  ok "Node.js 이미 설치됨 ($NODE_VER)"
  # 버전 체크 (18+ 필요)
  MAJOR=$(echo "$NODE_VER" | cut -d. -f1 | tr -d 'v')
  if [[ "$MAJOR" -lt 18 ]]; then
    warn "Node.js 버전이 너무 낮음 ($NODE_VER). 업그레이드 중..."
    brew upgrade node
  fi
else
  log "Node.js 설치 중..."
  brew install node
  ok "Node.js 설치 완료"
fi

# npm global prefix 설정 (sudo 없이 설치되게)
NPM_PREFIX="$HOME/.npm-global"
if [[ ! -d "$NPM_PREFIX" ]]; then
  mkdir -p "$NPM_PREFIX"
  npm config set prefix "$NPM_PREFIX"
fi
SHELL_RC="$HOME/.zshrc"
[[ "$SHELL" == *bash* ]] && SHELL_RC="$HOME/.bashrc"
if ! grep -q "npm-global" "$SHELL_RC" 2>/dev/null; then
  echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$SHELL_RC"
fi
export PATH="$NPM_PREFIX/bin:$PATH"

# ─────────────────────────────────────────────
section "6/7  Claude Code"
# ─────────────────────────────────────────────
if command -v claude &>/dev/null; then
  ok "Claude Code 이미 설치됨 ($(claude --version 2>/dev/null || echo '버전 확인 불가'))"
else
  log "Claude Code 설치 중..."
  npm install -g @anthropic-ai/claude-code
  ok "Claude Code 설치 완료"
fi

# ─────────────────────────────────────────────
section "7/7  Hermes (AI 오케스트레이터)"
# ─────────────────────────────────────────────
if command -v hermes &>/dev/null; then
  ok "Hermes 이미 설치됨"
else
  log "Hermes 설치 중 (약 1-3분 소요)..."
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup
  # PATH 재로드
  export PATH="$HOME/.hermes/bin:$PATH"
  ok "Hermes 설치 완료"
fi

# ─────────────────────────────────────────────
#  완료 요약
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║       ✓ 설치 완료!                    ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${RESET}"
echo "  설치된 도구:"
command -v brew   &>/dev/null && echo "  ✓ Homebrew   $(brew --version | head -1)"
command -v git    &>/dev/null && echo "  ✓ Git        $(git --version)"
command -v gh     &>/dev/null && echo "  ✓ GitHub CLI $(gh --version | head -1)"
[[ -d /Applications/Orca.app ]] && echo "  ✓ Orca ADE   (Launchpad에서 실행)"
command -v node   &>/dev/null && echo "  ✓ Node.js    $(node --version)"
command -v claude &>/dev/null && echo "  ✓ Claude Code"
command -v hermes &>/dev/null && echo "  ✓ Hermes"
echo ""
echo "  다음 단계:"
echo "  1. 터미널을 재시작하거나:  source $SHELL_RC"
echo "  2. Hermes 초기 설정:       hermes setup"
echo "  3. Orca ADE 실행:          Launchpad → Orca"
echo "  4. Claude Code 테스트:     claude --version"
echo ""
