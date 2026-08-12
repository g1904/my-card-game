#requires -Version 5.1
<#
    push-all-impl.ps1 - 批量提交并推送 MyCardGame 下的所有分支检出目录。

    每个 .claude / game-* / backend-* / main 目录都是同一个远程仓库
    (g1904/my-card-game) 的一份检出，各自处于不同分支。本脚本对每个目录执行
    git add -A -> 若有改动则 commit -> push origin <当前分支>。

    尚未初始化为 git 检出的目录会被跳过并在汇总中标注 —— 某些分支尚未创建时，
    直接运行本脚本是安全的。

    提交信息默认使用当天日期 (yyyy-MM-dd)，可通过 -Message 覆盖。

    用法（经由 push-all.cmd 调用，绕过执行策略）：
      .\push-all.cmd                       # 提交信息 = 今天的日期
      .\push-all.cmd -Message "修复抽卡bug"  # 覆盖提交信息
      .\push-all.cmd -DryRun               # 只打印将执行的操作，不改动
      .\push-all.cmd -PushRetries 5        # 网络差时多重试几次（默认 3 次，间隔 5s）

    push 使用 -u，因此新分支首次推送即建立上游跟踪。
#>
[CmdletBinding()]
param(
    # 提交信息。默认使用当天日期 yyyy-MM-dd。
    [string]$Message = (Get-Date -Format 'yyyy-MM-dd'),

    # 只打印计划的操作，不实际 add/commit/push。
    [switch]$DryRun,

    # push 失败时的总尝试次数（到 github.com 的连接偶发超时）。
    [int]$PushRetries = 3,

    # 两次 push 尝试之间的等待秒数。
    [int]$RetryDelaySeconds = 5
)

$ErrorActionPreference = 'Stop'

# 仓库根 = 本脚本上溯两级 (.claude\scripts -> .claude -> 根)。
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# 需要处理的检出目录（各自是一份带 .git 的独立分支检出）。
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

Write-Host "提交信息: $Message" -ForegroundColor Cyan
if ($DryRun) { Write-Host "(DryRun：不会实际改动)" -ForegroundColor Yellow }
Write-Host ""

$results = @()

foreach ($dir in $branchDirs) {
    $path = Join-Path $root $dir
    if (-not (Test-Path (Join-Path $path '.git'))) {
        Write-Host "[跳过] $dir —— 不是 git 检出" -ForegroundColor DarkGray
        $results += [pscustomobject]@{ Dir = $dir; Branch = '-'; Status = '跳过(非git)' }
        continue
    }

    $branch = (git -C $path rev-parse --abbrev-ref HEAD).Trim()
    Write-Host "=== $dir ($branch) ===" -ForegroundColor White

    if ($DryRun) {
        $dirty = git -C $path status --porcelain
        $hasChanges = [bool]$dirty
        Write-Host ("  将 add -A；{0}；push origin {1}" -f `
            ($(if ($hasChanges) { "commit -m '$Message'" } else { "无改动，跳过 commit" }), $branch))
        $results += [pscustomobject]@{ Dir = $dir; Branch = $branch; Status = 'DryRun' }
        continue
    }

    try {
        git -C $path add -A
        if ($LASTEXITCODE -ne 0) { throw "git add 失败 (exit $LASTEXITCODE)" }

        # 仅当有已暂存改动时才提交；否则可能仍有未推送的既有提交需要 push。
        $staged = git -C $path status --porcelain
        if ($staged) {
            git -C $path commit -m $Message | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "git commit 失败 (exit $LASTEXITCODE)" }
            Write-Host "  已提交" -ForegroundColor Green
        } else {
            Write-Host "  无改动，跳过 commit" -ForegroundColor DarkGray
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
