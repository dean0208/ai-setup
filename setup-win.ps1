# =============================================================================
#  AI 개발환경 자동 설치 스크립트 - Windows (PowerShell)
#  사용법:
#    powershell -ExecutionPolicy Bypass -Command "iex (irm https://tinyurl.com/2c77hu2w)"
# =============================================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 관리자 권한 자동 재실행
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] 관리자 권한으로 재실행 중..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command `"iex (irm 'https://tinyurl.com/2c77hu2w')`"" -Wait
    exit
}

$ErrorActionPreference = "Stop"

function Write-Ok   { param($msg) Write-Host "[v] $msg" -ForegroundColor Green }
function Write-Log  { param($msg) Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Warn { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Sect { param($msg) Write-Host "`n--- $msg ---" -ForegroundColor Cyan }
function Test-Cmd   { param($cmd) return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Add-ToPath {
    param($newPath)
    if (-not (Test-Path $newPath)) { return }
    $current = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($current -notlike "*$newPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$current;$newPath", "Machine")
    }
    if ($env:PATH -notlike "*$newPath*") { $env:PATH += ";$newPath" }
}

Clear-Host
Write-Host @"

  ╔═══════════════════════════════════════════════╗
  ║   AI 에이전트 개발환경 자동 설치 (Windows)   ║
  ║   Orca ADE + Claude Code + Hermes             ║
  ╚═══════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$confirm = Read-Host "  계속 진행할까요? (y/N)"
if ($confirm -notmatch '^[Yy]$') { Write-Host "취소됨."; exit 0 }

# ─────────────────────────────────────────────
Write-Sect "1/8  winget"
# ─────────────────────────────────────────────
if (Test-Cmd "winget") {
    Write-Ok "winget 사용 가능"
} else {
    Write-Warn "winget 없음. https://aka.ms/getwinget 에서 설치 후 다시 실행하세요."
    Read-Host "설치 후 Enter"
}

# ─────────────────────────────────────────────
Write-Sect "2/8  Git"
# ─────────────────────────────────────────────
if (Test-Cmd "git") {
    Write-Ok "Git 이미 설치됨 ($(git --version))"
} else {
    Write-Log "Git 설치 중..."
    winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements
    Add-ToPath "$env:ProgramFiles\Git\cmd"
    Write-Ok "Git 설치 완료"
}

# ─────────────────────────────────────────────
Write-Sect "3/8  GitHub CLI + 로그인 + git config"
# ─────────────────────────────────────────────
if (-not (Test-Cmd "gh")) {
    Write-Log "GitHub CLI 설치 중..."
    winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements
    Add-ToPath "$env:ProgramFiles\GitHub CLI"
    Write-Ok "GitHub CLI 설치 완료"
} else {
    Write-Ok "GitHub CLI 이미 설치됨"
}

$ghLoggedIn = $false
try {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Ok "GitHub 이미 로그인됨"; $ghLoggedIn = $true }
} catch {}

if (-not $ghLoggedIn) {
    Write-Host ""
    Write-Host "  [1] 브라우저: https://github.com/settings/tokens/new" -ForegroundColor White
    Write-Host "  [2] Note 입력 -> Generate token 클릭" -ForegroundColor White
    Write-Host "  [3] 토큰(ghp_...) 복사" -ForegroundColor White
    Write-Host ""
    $secureToken = Read-Host "  토큰 붙여넣기" -AsSecureString
    $ghToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    )
    if ($ghToken) {
        $ghToken | gh auth login --with-token
        Write-Ok "GitHub 로그인 완료"
        $ghLoggedIn = $true
    } else {
        Write-Warn "건너뜀. 나중에: gh auth login"
    }
}

# git config (Orca ADE 필수)
$gitName  = git config --global user.name  2>$null
$gitEmail = git config --global user.email 2>$null
if (-not $gitName -or -not $gitEmail) {
    Write-Log "Git 사용자 정보 설정 중..."
    $ghUser = ""; $ghEmail = ""
    if ($ghLoggedIn) {
        try { $ghUser  = (gh api user --jq '.name // .login' 2>$null).Trim() } catch {}
        try { $ghEmail = (gh api user/emails --jq '[.[] | select(.primary==true)] | .[0].email' 2>$null).Trim() } catch {}
    }
    if ($ghUser -and $ghEmail) {
        git config --global user.name $ghUser
        git config --global user.email $ghEmail
        Write-Ok "Git 자동 설정: $ghUser <$ghEmail>"
    } else {
        $gitName  = Read-Host "  이름 (예: 홍길동)"
        $gitEmail = Read-Host "  이메일 (예: hong@company.com)"
        git config --global user.name $gitName
        git config --global user.email $gitEmail
        Write-Ok "Git 사용자 정보 설정 완료"
    }
} else {
    Write-Ok "Git 사용자 정보 이미 설정됨 ($gitName)"
}

# ─────────────────────────────────────────────
Write-Sect "4/8  Python 3.11"
# ─────────────────────────────────────────────
$pyVer = try { python --version 2>&1 } catch { "" }
if ($pyVer -match "3\.11") {
    Write-Ok "Python 3.11 이미 설치됨"
} else {
    Write-Log "Python 3.11 설치 중..."
    winget install --id Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements
    Add-ToPath "$env:LOCALAPPDATA\Programs\Python\Python311"
    Add-ToPath "$env:LOCALAPPDATA\Programs\Python\Python311\Scripts"
    Write-Ok "Python 3.11 설치 완료"
}

# ─────────────────────────────────────────────
Write-Sect "5/8  Node.js"
# ─────────────────────────────────────────────
if (Test-Cmd "node") {
    $nodeVer = node --version
    $major = [int]($nodeVer -replace 'v(\d+)\..*','$1')
    if ($major -lt 18) {
        Write-Warn "Node.js 버전 낮음 ($nodeVer). 업그레이드 중..."
        winget upgrade --id OpenJS.NodeJS.LTS --silent --accept-package-agreements
    } else {
        Write-Ok "Node.js 이미 설치됨 ($nodeVer)"
    }
} else {
    Write-Log "Node.js 설치 중..."
    winget install --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
    Add-ToPath "$env:ProgramFiles\nodejs"
    Write-Ok "Node.js 설치 완료"
}

# ─────────────────────────────────────────────
Write-Sect "6/8  Orca ADE"
# ─────────────────────────────────────────────
$orcaExe = Get-ChildItem "$env:LOCALAPPDATA\Programs" -Recurse -Filter "Orca.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($orcaExe) {
    Write-Ok "Orca ADE 이미 설치됨"
} else {
    Write-Log "Orca ADE 설치 중..."
    try {
        winget install --id StablyAI.Orca --silent --accept-package-agreements --accept-source-agreements
        Write-Ok "Orca ADE 설치 완료"
    } catch {
        $installer = "$env:TEMP\OrcaSetup.exe"
        Invoke-WebRequest -Uri "https://github.com/stablyai/orca/releases/latest/download/Orca-Setup-Windows.exe" -OutFile $installer -UseBasicParsing
        Start-Process -FilePath $installer -ArgumentList "/S" -Wait
        Remove-Item $installer -ErrorAction SilentlyContinue
        Write-Ok "Orca ADE 설치 완료"
    }
}

# ─────────────────────────────────────────────
Write-Sect "7/8  Claude Code"
# ─────────────────────────────────────────────
if (Test-Cmd "claude") {
    Write-Ok "Claude Code 이미 설치됨"
} else {
    Write-Log "Claude Code 설치 중..."
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    npm install -g @anthropic-ai/claude-code
    Write-Ok "Claude Code 설치 완료"
}

# ─────────────────────────────────────────────
Write-Sect "8/8  Hermes"
# ─────────────────────────────────────────────
if (Test-Cmd "hermes") {
    Write-Ok "Hermes 이미 설치됨"
} else {
    Write-Log "Hermes 설치 중 (1~3분)..."
    # 이전 실패 잔재 제거
    $hermesTmp = "$env:LOCALAPPDATA\hermes\hermes-agent\.hermes-runtime\python\.temp"
    if (Test-Path $hermesTmp) {
        Remove-Item $hermesTmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    # 회사 방화벽 SSL 대응
    $env:UV_SYSTEM_CERTS = "1"
    iex (irm https://hermes-agent.nousresearch.com/install.ps1)
    Add-ToPath "$env:LOCALAPPDATA\hermes\bin"
    Write-Ok "Hermes 설치 완료"
}

# ─────────────────────────────────────────────
Write-Sect "완료"
# ─────────────────────────────────────────────
Write-Host ""
if (Test-Cmd "git")    { Write-Ok "Git        $(git --version)" }
if (Test-Cmd "gh")     { Write-Ok "GitHub CLI" }
if (Test-Cmd "node")   { Write-Ok "Node.js    $(node --version)" }
if (Test-Cmd "claude") { Write-Ok "Claude Code" }
if (Test-Path "$env:LOCALAPPDATA\hermes\bin") { Write-Ok "Hermes" }

Write-Host @"

  다음 단계:
  1. PowerShell 새 창 열기 (PATH 적용)
  2. hermes setup
  3. 시작 메뉴 -> Orca

"@ -ForegroundColor White
