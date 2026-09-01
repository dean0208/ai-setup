# =============================================================================
#  AI 개발환경 자동 설치 스크립트 - Windows (PowerShell)
#  설치 항목: Git, Node.js, Orca ADE, Claude Code, Hermes, GitHub CLI
#  사용법 (PowerShell 관리자 권한):
#    iex (irm https://raw.githubusercontent.com/YOUR_ORG/setup/main/setup-win.ps1)
#  또는 로컬 실행:
#    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#    .\setup-win.ps1
# =============================================================================

# 실행 정책을 현재 프로세스에만 Bypass로 설정 (시스템 영구 변경 없음, 관리자 권한 불필요)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ErrorActionPreference = "Stop"

function Write-Step  { param($msg) Write-Host "`n[*] $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "[✓] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "[✗] $msg" -ForegroundColor Red; exit 1 }

function Test-Command { param($cmd) return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Add-ToUserPath {
    param($newPath)
    $current = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($current -notlike "*$newPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$current;$newPath", "User")
        $env:PATH += ";$newPath"
    }
}

Clear-Host
Write-Host @"

  ╔═══════════════════════════════════════════════╗
  ║   AI 에이전트 개발환경 자동 설치 (Windows)   ║
  ║   Orca ADE + Claude Code + Hermes             ║
  ╚═══════════════════════════════════════════════╝

  이 스크립트는 다음 항목을 자동 설치합니다:
  • winget (Windows 패키지 매니저, 보통 이미 설치됨)
  • Git + GitHub CLI (gh)
  • Orca ADE (AI 에이전트 개발환경)
  • Node.js
  • Claude Code (Anthropic AI 코딩 에이전트)
  • Hermes (AI 오케스트레이터)

"@ -ForegroundColor Cyan

$confirm = Read-Host "  계속 진행할까요? (y/N)"
if ($confirm -notmatch '^[Yy]$') { Write-Host "취소됨."; exit 0 }

# ─────────────────────────────────────────────
Write-Step "1/7  winget 확인"
# ─────────────────────────────────────────────
if (Test-Command "winget") {
    Write-Ok "winget 사용 가능"
} else {
    Write-Warn "winget을 찾을 수 없습니다. Microsoft Store에서 'App Installer'를 설치해주세요."
    Write-Host "  https://aka.ms/getwinget" -ForegroundColor Yellow
    Read-Host "설치 후 Enter를 눌러 계속"
}

# ─────────────────────────────────────────────
Write-Step "2/7  Git"
# ─────────────────────────────────────────────
if (Test-Command "git") {
    Write-Ok "Git 이미 설치됨 ($(git --version))"
} else {
    Write-Host "    Git 설치 중..." -ForegroundColor Gray
    winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements
    # PATH 갱신
    $gitPath = "$env:ProgramFiles\Git\cmd"
    Add-ToUserPath $gitPath
    $env:PATH += ";$gitPath"
    Write-Ok "Git 설치 완료"
}

# ─────────────────────────────────────────────
Write-Step "3/7  GitHub CLI (gh)"
# ─────────────────────────────────────────────
if (Test-Command "gh") {
    Write-Ok "GitHub CLI 이미 설치됨"
} else {
    Write-Host "    GitHub CLI 설치 중..." -ForegroundColor Gray
    winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements
    $ghPath = "$env:ProgramFiles\GitHub CLI"
    Add-ToUserPath $ghPath
    Write-Ok "GitHub CLI 설치 완료"
}

Write-Host ""
try {
    $ghStatus = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "GitHub 이미 로그인됨"
    } else {
        Write-Host "  GitHub Personal Access Token(PAT)이 필요합니다." -ForegroundColor White
        Write-Host ""
        Write-Host "  ① 아래 주소를 브라우저에서 열어주세요:" -ForegroundColor White
        Write-Host "     https://github.com/settings/tokens/new" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  ② Note 칸에 아무 이름 입력 → 맨 아래 [Generate token] 클릭" -ForegroundColor White
        Write-Host "  ③ 생성된 토큰(ghp_...) 복사" -ForegroundColor White
        Write-Host ""
        $secureToken = Read-Host "  여기에 토큰 붙여넣기" -AsSecureString
        $ghToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        )
        if ($ghToken) {
            $ghToken | gh auth login --with-token
            Write-Ok "GitHub 로그인 완료"
        } else {
            Write-Warn "토큰 없이 건너뜀. 나중에 직접 실행: gh auth login"
        }
    }
} catch {
    Write-Warn "GitHub 로그인을 나중에 직접 실행하세요: gh auth login"
}

# ─────────────────────────────────────────────
Write-Step "4/7  Node.js"
# ─────────────────────────────────────────────
if (Test-Command "node") {
    $nodeVer = node --version
    Write-Ok "Node.js 이미 설치됨 ($nodeVer)"
    $major = [int]($nodeVer -replace 'v(\d+)\..*','$1')
    if ($major -lt 18) {
        Write-Warn "Node.js 버전 낮음. 업그레이드 중..."
        winget upgrade --id OpenJS.NodeJS.LTS --silent --accept-package-agreements
    }
} else {
    Write-Host "    Node.js 설치 중..." -ForegroundColor Gray
    winget install --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
    $nodePath = "$env:ProgramFiles\nodejs"
    Add-ToUserPath $nodePath
    $env:PATH += ";$nodePath"
    Write-Ok "Node.js 설치 완료"
}

# ─────────────────────────────────────────────
Write-Step "5/7  Orca ADE"
# ─────────────────────────────────────────────
$orcaPath = "$env:LOCALAPPDATA\Programs\Orca"
$orcaExe  = Get-ChildItem "$env:LOCALAPPDATA\Programs" -Recurse -Filter "Orca.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($orcaExe) {
    Write-Ok "Orca ADE 이미 설치됨"
} else {
    Write-Host "    Orca ADE 다운로드 중..." -ForegroundColor Gray
    $orcaInstaller = "$env:TEMP\OrcaSetup.exe"
    try {
        # winget으로 시도
        winget install --id StablyAI.Orca --silent --accept-package-agreements --accept-source-agreements 2>$null
        Write-Ok "Orca ADE 설치 완료 (winget)"
    } catch {
        # 직접 다운로드 fallback
        Write-Host "    공식 사이트에서 다운로드 중..." -ForegroundColor Gray
        $downloadUrl = "https://github.com/stablyai/orca/releases/latest/download/Orca-Setup-Windows.exe"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $orcaInstaller -UseBasicParsing
        Write-Host "    설치 프로그램 실행 중..." -ForegroundColor Gray
        Start-Process -FilePath $orcaInstaller -ArgumentList "/S" -Wait
        Remove-Item $orcaInstaller -ErrorAction SilentlyContinue
        Write-Ok "Orca ADE 설치 완료"
    }
}

# ─────────────────────────────────────────────
Write-Step "6/7  Claude Code"
# ─────────────────────────────────────────────
if (Test-Command "claude") {
    Write-Ok "Claude Code 이미 설치됨"
} else {
    Write-Host "    Claude Code 설치 중..." -ForegroundColor Gray
    npm install -g @anthropic-ai/claude-code
    Write-Ok "Claude Code 설치 완료"
}

# ─────────────────────────────────────────────
Write-Step "7/7  Hermes (AI 오케스트레이터)"
# ─────────────────────────────────────────────
if (Test-Command "hermes") {
    Write-Ok "Hermes 이미 설치됨"
} else {
    Write-Host "    Hermes 설치 중 (약 1-3분 소요)..." -ForegroundColor Gray
    iex (irm https://hermes-agent.nousresearch.com/install.ps1)
    Write-Ok "Hermes 설치 완료"
}

# ─────────────────────────────────────────────
#  API 키 설정
# ─────────────────────────────────────────────
#  완료 요약
# ─────────────────────────────────────────────
Write-Host @"

  ╔═══════════════════════════════════════╗
  ║       ✓ 설치 완료!                    ║
  ╚═══════════════════════════════════════╝
"@ -ForegroundColor Green

Write-Host "  설치된 도구:" -ForegroundColor White
if (Test-Command "git")    { Write-Ok "Git        $(git --version)" }
if (Test-Command "gh")     { Write-Ok "GitHub CLI" }
if (Test-Command "node")   { Write-Ok "Node.js    $(node --version)" }
if (Test-Command "claude") { Write-Ok "Claude Code" }
if (Test-Command "hermes") { Write-Ok "Hermes" }
if ($orcaExe -or (Get-Command "orca" -ErrorAction SilentlyContinue)) { Write-Ok "Orca ADE" }

Write-Host @"

  다음 단계:
  1. PowerShell을 재시작하세요 (PATH 적용)
  2. Hermes 초기 설정:  hermes setup
  3. Orca ADE 실행:     시작 메뉴 -> Orca
  4. Claude Code 테스트: claude --version

"@ -ForegroundColor White
