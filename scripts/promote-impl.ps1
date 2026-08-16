#requires -Version 5.1
<#
    promote-impl.ps1 - 沿提升线把一个分支合并进它的下游分支。

    两条彼此独立的提升线（从不互相合并，权威见 rules/Context.md）：
      game    : game-feature    -> game-testing    -> game-production
      backend : backend-feature -> backend-testing -> backend-production

    合并**在目标分支自己的检出目录里**进行（例如 -To testing 就在
    game-testing-branch/ 里跑），这样不需要切分支，也不动 feature 目录。

    纪律（不可协商）：
      · 目标工作区不干净就拒绝执行 —— 只读快照目录里的意外改动必须先由人处理。
      · 一律 --no-ff 留下一个合并提交 —— 提升是一个事件，要在历史里看得见。
      · **绝不 force-push、绝不改写历史。** 冲突就停下来交给人，不自作主张。

    unrelated histories：backend 三个分支曾是三段各自独立的单提交历史，
    彼此没有共同祖先，普通 merge 会直接报 "refusing to merge unrelated
    histories"。此时需**一次性**加 -AllowUnrelated 打通；打通后这三条线
    就有了共同祖先，之后的常规提升不再需要该开关。

    用法（经由 promote.cmd 调用，绕过执行策略）：
      .\promote.cmd -Line game -To testing            # game-feature    -> game-testing
      .\promote.cmd -Line game -To production         # game-testing    -> game-production
      .\promote.cmd -Line backend -To testing -DryRun # 只打印将执行的操作
      .\promote.cmd -Line backend -To testing -AllowUnrelated
#>
[CmdletBinding()]
param(
    # 提升线：game（Godot 客户端）或 backend（云端后端）。
    [Parameter(Mandatory = $true)]
    [ValidateSet('game', 'backend')]
    [string]$Line,

    # 目标环境：testing（源 = feature）或 production（源 = testing）。
    [Parameter(Mandatory = $true)]
    [ValidateSet('testing', 'production')]
    [string]$To,

    # 只打印将执行的操作，不 fetch/merge/push。
    [switch]$DryRun,

    # 允许合并没有共同祖先的两段历史（--allow-unrelated-histories）。
    # 一次性用于打通 backend 三段独立历史；常规提升不要加。
    [switch]$AllowUnrelated,

    # 覆盖合并提交信息。默认自动生成。
    [string]$Message,

    # push 失败时的总尝试次数（到 github.com 的连接偶发超时）。
    [int]$PushRetries = 3,

    # 两次 push 尝试之间的等待秒数。
    [int]$RetryDelaySeconds = 5
)

$ErrorActionPreference = 'Stop'

# 仓库根 = 本脚本上溯两级 (.claude\scripts -> .claude -> 根)。
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# 源环境由目标推出：testing 收 feature，production 收 testing。
$from = if ($To -eq 'testing') { 'feature' } else { 'testing' }

$sourceBranch = "$Line-$from"
$targetBranch = "$Line-$To"
$targetDir    = Join-Path $root "$Line-$To-branch"

Write-Host "===== promote: $sourceBranch -> $targetBranch =====" -ForegroundColor Cyan
Write-Host "目标目录: $targetDir"
if ($DryRun) { Write-Host "(DryRun：不会实际改动)" -ForegroundColor Yellow }
if ($AllowUnrelated) { Write-Host "(已允许合并无关历史 --allow-unrelated-histories)" -ForegroundColor Yellow }
Write-Host ""

# ── 前置检查 ────────────────────────────────────────────────────────
if (-not (Test-Path $targetDir)) {
    Write-Host "目标目录不存在: $targetDir" -ForegroundColor Red
    exit 1
}
# 注意：worktree 的 .git 是**文件**不是目录，故用 rev-parse 判定而非 Test-Path。
git -C $targetDir rev-parse --git-dir *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "目标目录不是 git 工作区: $targetDir" -ForegroundColor Red
    exit 1
}

$actualBranch = (git -C $targetDir rev-parse --abbrev-ref HEAD).Trim()
if ($actualBranch -ne $targetBranch) {
    Write-Host "目标目录当前在分支 '$actualBranch'，期望 '$targetBranch' —— 已中止" -ForegroundColor Red
    exit 1
}

# 工作区必须干净：只读快照目录里的意外改动要先由人处理，不能被合并盖掉。
$dirty = git -C $targetDir status --porcelain
if ($dirty) {
    Write-Host "目标工作区不干净，已中止。请先提交或还原以下改动：" -ForegroundColor Red
    $dirty | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    exit 1
}
Write-Host "目标工作区干净 ✓" -ForegroundColor Green

# ── fetch ───────────────────────────────────────────────────────────
if ($DryRun) {
    Write-Host "将 fetch --prune origin"
} else {
    git -C $targetDir fetch --prune origin
    if ($LASTEXITCODE -ne 0) { Write-Host "fetch 失败，已中止" -ForegroundColor Red; exit 1 }
    Write-Host "已 fetch origin ✓" -ForegroundColor Green
}

$sourceRef = "origin/$sourceBranch"
git -C $targetDir rev-parse --verify --quiet "$sourceRef^{commit}" *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "找不到源引用 $sourceRef（该分支尚未推送？）—— 已中止" -ForegroundColor Red
    exit 1
}

$sourceSha = (git -C $targetDir rev-parse --short $sourceRef).Trim()
$targetSha = (git -C $targetDir rev-parse --short HEAD).Trim()
Write-Host "源 $sourceRef = $sourceSha ; 目标 $targetBranch = $targetSha"

# ── 已是最新？ ──────────────────────────────────────────────────────
git -C $targetDir merge-base --is-ancestor $sourceRef HEAD *> $null
$alreadyIn = ($LASTEXITCODE -eq 0)
if ($alreadyIn) {
    Write-Host "$sourceRef 已包含在 $targetBranch 中 —— 无需合并（no-op）" -ForegroundColor DarkGray
}

# ── 无关历史探测 ────────────────────────────────────────────────────
$mergeBase = (git -C $targetDir merge-base $sourceRef HEAD 2>$null)
$unrelated = ($LASTEXITCODE -ne 0 -or -not $mergeBase)
if ($unrelated) {
    Write-Host "检测到**无共同祖先**（unrelated histories）" -ForegroundColor Yellow
    if (-not $AllowUnrelated) {
        Write-Host ""
        Write-Host "$sourceBranch 与 $targetBranch 是两段彼此独立的历史，普通 merge 会被 git 拒绝。" -ForegroundColor Red
        Write-Host "确认要把它们打通，请加 -AllowUnrelated 重跑（这是一次性操作，之后两条线即有共同祖先）：" -ForegroundColor Red
        Write-Host "    .\promote.cmd -Line $Line -To $To -AllowUnrelated" -ForegroundColor Red
        exit 1
    }
} elseif (-not $alreadyIn) {
    Write-Host "共同祖先: $($mergeBase.Trim().Substring(0,7))"
}

if (-not $Message) {
    $Message = "promote: $sourceBranch -> $targetBranch ($sourceSha) [$(Get-Date -Format 'yyyy-MM-dd')]"
}

# ── 合并 ────────────────────────────────────────────────────────────
if ($DryRun) {
    $flags = '--no-ff'
    if ($AllowUnrelated) { $flags += ' --allow-unrelated-histories' }
    if ($alreadyIn) {
        Write-Host "将跳过 merge（已是最新）；仍会 push origin $targetBranch"
    } else {
        Write-Host "将 merge $flags $sourceRef -m '$Message'"
    }
    Write-Host "将 push origin $targetBranch（绝不 --force）"
    Write-Host ""
    Write-Host "===== 汇总（DryRun）=====" -ForegroundColor Cyan
    Write-Host ("  {0} -> {1} : {2}" -f $sourceBranch, $targetBranch,
        $(if ($alreadyIn) { '无需合并' } elseif ($unrelated) { '将合并（无关历史）' } else { '将合并' }))
    exit 0
}

$merged = $false
if (-not $alreadyIn) {
    $mergeArgs = @('-C', $targetDir, 'merge', '--no-ff', '--no-edit', '-m', $Message)
    if ($AllowUnrelated) { $mergeArgs += '--allow-unrelated-histories' }
    $mergeArgs += $sourceRef

    & git @mergeArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "合并出现冲突或失败，**合并已留在进行中的状态**，未提交、未推送。" -ForegroundColor Red
        $conflicts = git -C $targetDir diff --name-only --diff-filter=U
        if ($conflicts) {
            Write-Host "冲突文件：" -ForegroundColor Red
            $conflicts | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        }
        Write-Host ""
        Write-Host "请在 $targetDir 中手工处理，然后二选一：" -ForegroundColor Yellow
        Write-Host "    git -C `"$targetDir`" add <files> ; git -C `"$targetDir`" commit   # 解决后完成合并" -ForegroundColor Yellow
        Write-Host "    git -C `"$targetDir`" merge --abort                                # 放弃本次提升" -ForegroundColor Yellow
        exit 1
    }
    $merged = $true
    Write-Host "已合并 ✓" -ForegroundColor Green
}

# ── push（带重试；绝不 --force）──────────────────────────────────────
$pushed = $false
for ($attempt = 1; $attempt -le $PushRetries; $attempt++) {
    git -C $targetDir push origin $targetBranch
    if ($LASTEXITCODE -eq 0) { $pushed = $true; break }
    if ($attempt -lt $PushRetries) {
        Write-Host "push 失败 (exit $LASTEXITCODE)，${RetryDelaySeconds}s 后重试 ($attempt/$PushRetries)" -ForegroundColor Yellow
        Start-Sleep -Seconds $RetryDelaySeconds
    }
}
if (-not $pushed) {
    Write-Host "push 失败，已重试 $PushRetries 次。合并提交仍在本地，可稍后手动 push。" -ForegroundColor Red
    exit 1
}

$newSha = (git -C $targetDir rev-parse --short HEAD).Trim()

Write-Host ""
Write-Host "===== 汇总 =====" -ForegroundColor Cyan
Write-Host "  提升线   : $Line"
Write-Host "  源       : $sourceBranch @ $sourceSha"
Write-Host "  目标     : $targetBranch @ $targetSha -> $newSha"
Write-Host ("  合并     : {0}" -f $(if ($merged) { if ($AllowUnrelated) { '是（--allow-unrelated-histories）' } else { '是（--no-ff 合并提交）' } } else { '否（已是最新）' }))
Write-Host "  推送     : origin/$targetBranch ✓" -ForegroundColor Green
