#requires -Version 5.1
<#
    push-all-impl.ps1 - 批量提交并推送 MyCardGame 下的所有分支检出目录。

    每个 .claude / game-* / backend-* / main 目录都是同一个远程仓库
    (g1904/my-card-game) 的一份工作区，各自处于不同分支。本脚本对每个目录执行
    git add -A -> 若有改动则 commit -> push origin <当前分支>。

    尚未初始化为 git 工作区的目录会被跳过并在汇总中标注 —— 某些分支尚未创建时，
    直接运行本脚本是安全的。

    三条纪律：
      1. 先 fetch 后判断 —— 每个唯一的 git 仓库（common dir）只 fetch --prune 一次；
         随后逐目录比对本地分支与上游的 ahead/behind：
           · 分叉（既领先又落后）      -> 报告并跳过，不做盲推
           · 纯落后（ahead=0）         -> 尝试 merge --ff-only；失败即跳过
      2. 四个只读快照目录（game-testing / game-production / backend-testing /
         backend-production）是 **push-only**：绝不在其中 add/commit，只推送既有提交。
      3. 未给 -Message 时按目录**自动生成**信息性提交信息（作用域 + 改动最多的
         顶层目录 + 文件数），而非裸日期。给了 -Message 则整体覆盖。

    用法（经由 push-all.cmd 调用，绕过执行策略）：
      .\push-all.cmd                       # 每个目录自动生成提交信息
      .\push-all.cmd -Message "修复抽卡bug"  # 覆盖提交信息（所有目录同一条）
      .\push-all.cmd -DryRun               # 只打印将执行的操作，不改动
      .\push-all.cmd -PushRetries 5        # 网络差时多重试几次（默认 3 次，间隔 5s）

    push 使用 -u，因此新分支首次推送即建立上游跟踪。
#>
[CmdletBinding()]
param(
    # 提交信息。留空则逐目录自动生成（见 New-AutoMessage）。
    [string]$Message,

    # 只打印计划的操作，不实际 fetch/add/commit/push。
    [switch]$DryRun,

    # push 失败时的总尝试次数（到 github.com 的连接偶发超时）。
    [int]$PushRetries = 3,

    # 两次 push 尝试之间的等待秒数。
    [int]$RetryDelaySeconds = 5
)

$ErrorActionPreference = 'Stop'

# 仓库根 = 本脚本上溯两级 (.claude\scripts -> .claude -> 根)。
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# 需要处理的目录（各自是一份独立分支的 git 工作区）。
$branchDirs = @(
    '.claude',
    'game-design-documents',
    'game-feature-branch',
    'game-production-branch',
    'game-testing-branch',
    'backend-design-documents',
    'backend-feature-branch',
    'backend-production-branch',
    'backend-testing-branch',
    'main'
)

# 只读快照目录：push-only，绝不 add/commit（纪律来源 rules/Context.md）。
$readOnlyDirs = @(
    'game-testing-branch',
    'game-production-branch',
    'backend-testing-branch',
    'backend-production-branch'
)

# 目录 -> 提交信息作用域标签。自动生成的信息用它开头。
function Get-ScopeLabel([string]$dir) {
    switch -Wildcard ($dir) {
        '.claude'              { 'config' ; break }
        '*-design-documents'   { 'design' ; break }
        '*-feature-branch'     { 'feature'; break }
        'main'                 { 'main'   ; break }
        default                { $dir     }
    }
}

<#
    由已暂存的改动生成一条信息性提交信息，形如：
      2026-08-16 design: systems/services, open-questions (+12 files)
    取法：把每个改动文件归到它的顶层分区（深度 >= 2 取前两段，如 systems/services；
    根级文件取文件名），按文件数降序取前三个，再附上总文件数。
#>
function New-AutoMessage([string]$path, [string]$dir, [string]$date) {
    $files = @(git -C $path diff --cached --name-only | Where-Object { $_ })
    $scope = Get-ScopeLabel $dir
    if ($files.Count -eq 0) { return "$date $scope`: (无改动)" }

    $buckets = @{}
    foreach ($f in $files) {
        $parts = $f -split '/'
        if ($parts.Count -ge 3)    { $key = "$($parts[0])/$($parts[1])" }
        elseif ($parts.Count -eq 2) { $key = $parts[0] }
        else                        { $key = $parts[0] }
        if ($buckets.ContainsKey($key)) { $buckets[$key]++ } else { $buckets[$key] = 1 }
    }

    $top = $buckets.GetEnumerator() |
        Sort-Object -Property @{Expression = 'Value'; Descending = $true}, @{Expression = 'Name'} |
        Select-Object -First 3 -ExpandProperty Name
    $summary = ($top -join ', ')
    if ($buckets.Count -gt 3) { $summary += ', …' }

    return "$date $scope`: $summary (+$($files.Count) files)"
}

# 解析本地分支相对上游的 ahead/behind。无上游时返回 $null。
function Get-AheadBehind([string]$path, [string]$branch) {
    $upstream = (git -C $path rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $upstream) { return $null }
    $counts = (git -C $path rev-list --left-right --count "$upstream...HEAD" 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $counts) { return $null }
    $pair = $counts.Trim() -split '\s+'
    return [pscustomobject]@{
        Upstream = $upstream.Trim()
        Behind   = [int]$pair[0]
        Ahead    = [int]$pair[1]
    }
}

$today = Get-Date -Format 'yyyy-MM-dd'
if ($Message) { Write-Host "提交信息（覆盖）: $Message" -ForegroundColor Cyan }
else          { Write-Host "提交信息: 逐目录自动生成（日期 $today）" -ForegroundColor Cyan }
if ($DryRun) { Write-Host "(DryRun：不会实际改动)" -ForegroundColor Yellow }
Write-Host ""

# ── 阶段一：每个唯一仓库 fetch --prune 一次 ──────────────────────────
# 十个目录若是同一个 hub 的 worktree，则共享一份 fetch 状态，只需 fetch 一次。
Write-Host "===== fetch --prune =====" -ForegroundColor Cyan
$fetched = @{}
foreach ($dir in $branchDirs) {
    $path = Join-Path $root $dir
    if (-not (Test-Path $path)) { continue }
    # 注意：worktree 的 .git 是**文件**不是目录，故用 rev-parse 而非 Test-Path 判定。
    $commonDir = (git -C $path rev-parse --path-format=absolute --git-common-dir 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $commonDir) { continue }
    $commonDir = $commonDir.Trim()
    if ($fetched.ContainsKey($commonDir)) { continue }
    $fetched[$commonDir] = $true
    if ($DryRun) {
        Write-Host "  将 fetch --prune ($dir -> $commonDir)" -ForegroundColor DarkGray
    } else {
        Write-Host "  fetch --prune ($dir)" -ForegroundColor DarkGray
        git -C $path fetch --prune origin
        if ($LASTEXITCODE -ne 0) { Write-Host "  fetch 失败（继续，后续判断可能基于陈旧状态）" -ForegroundColor Yellow }
    }
}
Write-Host ""

$results = @()

foreach ($dir in $branchDirs) {
    $path = Join-Path $root $dir
    $isReadOnly = $readOnlyDirs -contains $dir

    if (-not (Test-Path $path)) {
        Write-Host "[跳过] $dir —— 目录不存在" -ForegroundColor DarkGray
        $results += [pscustomobject]@{ Dir = $dir; Branch = '-'; Status = '跳过(无目录)' }
        continue
    }
    # 同上：worktree 的 .git 是文件，不能用「是否为目录」来判定。
    git -C $path rev-parse --git-dir *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[跳过] $dir —— 不是 git 工作区" -ForegroundColor DarkGray
        $results += [pscustomobject]@{ Dir = $dir; Branch = '-'; Status = '跳过(非git)' }
        continue
    }

    $branch = (git -C $path rev-parse --abbrev-ref HEAD).Trim()
    $tag = $(if ($isReadOnly) { ' [只读快照·push-only]' } else { '' })
    Write-Host "=== $dir ($branch)$tag ===" -ForegroundColor White

    # ── 上游对比：分叉即跳过，纯落后则先快进 ──
    $ab = Get-AheadBehind $path $branch
    if ($null -eq $ab) {
        Write-Host "  无上游跟踪分支（首次推送将以 -u 建立）" -ForegroundColor DarkGray
    } else {
        Write-Host ("  vs {0}: 领先 {1} / 落后 {2}" -f $ab.Upstream, $ab.Ahead, $ab.Behind) -ForegroundColor DarkGray
        if ($ab.Behind -gt 0 -and $ab.Ahead -gt 0) {
            Write-Host "  [跳过] 与上游分叉（领先 $($ab.Ahead) 且落后 $($ab.Behind)），无法快进；请手动 rebase/merge 后重跑" -ForegroundColor Red
            $results += [pscustomobject]@{ Dir = $dir; Branch = $branch; Status = "跳过(分叉 +$($ab.Ahead)/-$($ab.Behind))" }
            Write-Host ""
            continue
        }
        if ($ab.Behind -gt 0) {
            if ($DryRun) {
                Write-Host "  将 merge --ff-only $($ab.Upstream)（落后 $($ab.Behind)）" -ForegroundColor Yellow
            } else {
                git -C $path merge --ff-only $ab.Upstream *> $null
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "  [跳过] 落后 $($ab.Behind) 且快进失败（工作区可能有冲突改动）" -ForegroundColor Red
                    $results += [pscustomobject]@{ Dir = $dir; Branch = $branch; Status = "跳过(无法快进 -$($ab.Behind))" }
                    Write-Host ""
                    continue
                }
                Write-Host "  已快进 $($ab.Behind) 个提交" -ForegroundColor Green
            }
        }
    }

    if ($DryRun) {
        if ($isReadOnly) {
            $dirty = git -C $path status --porcelain
            if ($dirty) { Write-Host "  只读快照有本地改动（不会 add/commit，请手工处理）" -ForegroundColor Yellow }
            Write-Host "  将只 push origin $branch（push-only）"
        } else {
            $dirty = git -C $path status --porcelain
            if ($dirty) {
                $msgPreview = $(if ($Message) { $Message } else { "<自动生成：$today $(Get-ScopeLabel $dir): …>" })
                Write-Host "  将 add -A；commit -m '$msgPreview'；push origin $branch"
            } else {
                Write-Host "  无改动，跳过 commit；push origin $branch"
            }
        }
        $results += [pscustomobject]@{ Dir = $dir; Branch = $branch; Status = 'DryRun' }
        Write-Host ""
        continue
    }

    try {
        if ($isReadOnly) {
            # push-only：只读快照目录绝不 add/commit。有本地改动就出声，但不动它。
            $dirty = git -C $path status --porcelain
            if ($dirty) { Write-Host "  只读快照存在本地改动，已忽略（不 add/commit）" -ForegroundColor Yellow }
        } else {
            git -C $path add -A
            if ($LASTEXITCODE -ne 0) { throw "git add 失败 (exit $LASTEXITCODE)" }

            # 仅当有已暂存改动时才提交；否则可能仍有未推送的既有提交需要 push。
            $staged = git -C $path status --porcelain
            if ($staged) {
                $commitMsg = $(if ($Message) { $Message } else { New-AutoMessage $path $dir $today })
                git -C $path commit -m $commitMsg | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "git commit 失败 (exit $LASTEXITCODE)" }
                Write-Host "  已提交: $commitMsg" -ForegroundColor Green
            } else {
                Write-Host "  无改动，跳过 commit" -ForegroundColor DarkGray
            }
        }

        # push 带重试：到 github.com 的连接偶发超时，重试通常即可通过。
        # 注意：原生 git 失败不会抛异常，必须显式检查 $LASTEXITCODE。
        $pushed = $false
        for ($attempt = 1; $attempt -le $PushRetries; $attempt++) {
            git -C $path push -u origin $branch
            if ($LASTEXITCODE -eq 0) { $pushed = $true; break }
            if ($attempt -lt $PushRetries) {
                Write-Host "  push 失败 (exit $LASTEXITCODE)，${RetryDelaySeconds}s 后重试 ($attempt/$PushRetries)" -ForegroundColor Yellow
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
        if (-not $pushed) { throw "push 失败，已重试 $PushRetries 次（多为到 github.com 的连接超时）" }

        Write-Host "  已推送到 origin/$branch" -ForegroundColor Green
        $results += [pscustomobject]@{ Dir = $dir; Branch = $branch; Status = '成功' }
    }
    catch {
        Write-Host "  失败: $($_.Exception.Message)" -ForegroundColor Red
        $results += [pscustomobject]@{ Dir = $dir; Branch = $branch; Status = "失败: $($_.Exception.Message)" }
    }
    Write-Host ""
}

Write-Host "===== 汇总 =====" -ForegroundColor Cyan
$results | Format-Table -AutoSize | Out-String | Write-Host

if ($results | Where-Object { $_.Status -like '失败*' }) { exit 1 }
