# check-knowledge-staleness.ps1 —— 知识保鲜检查
#
# .claude/knowledge/*（薄引用层）是两个事实来源的投影：game-feature-branch/（代码现状）
# 与 game-design-documents/（设计意图）。本脚本对比这两处相对「上次全量对账」的漂移量，
# 提示何时该跑 /sync-knowledge —— 让保鲜从「凭感觉」变成「看得见的落后提交数」。
#
# 基线文件： .claude/knowledge/.staleness-baseline（每行 `<目录名> <commit哈希>`，随 claude-config 入库）
# 追踪范围： 只追踪知识层实际覆盖的事实来源。后端两个目录尚未纳入 —— 知识引用层目前只覆盖
#            客户端（见 .claude/rules/design-library-routing.md 两库结构差异表）；后端开工且
#            knowledge/* 开始覆盖它时，把目录加进下方 $tracked 即可。
#
# 用法：
#   检查：     powershell -NoProfile -ExecutionPolicy Bypass -File .claude\scripts\check-knowledge-staleness.ps1
#   刷新基线： 同上 + ` -Update`（应在 /sync-knowledge 对账完成后执行，不要用它掩盖未对账的漂移）
# 退出码： 0 = 基线内无漂移；1 = 有漂移（建议 /sync-knowledge）；2 = 基线缺失或失效（先 -Update 建立）

[CmdletBinding()]
param([switch]$Update)

$ErrorActionPreference = 'Stop'
$claudeDir = Split-Path -Parent $PSScriptRoot
$root      = Split-Path -Parent $claudeDir
$baselineFile = Join-Path $claudeDir 'knowledge\.staleness-baseline'

$tracked = @('game-feature-branch', 'game-design-documents')

# ---------- 采集各目录当前 HEAD ----------
$current = @{}
$dirty   = @{}
foreach ($t in $tracked) {
    $dirPath = Join-Path $root $t
    $head = git -C $dirPath rev-parse HEAD
    if ($LASTEXITCODE -ne 0) {
        Write-Output "staleness: 无法读取 $t 的 HEAD（不是 git 检出？），跳过"
        continue
    }
    $current[$t] = $head.Trim()
    $status = git -C $dirPath status --porcelain
    $dirty[$t] = @($status | Where-Object { $_ }).Count
}

# ---------- -Update：写基线 ----------
if ($Update) {
    $lines = @("# knowledge 保鲜基线 —— 由 check-knowledge-staleness.ps1 -Update 写入（$(Get-Date -Format 'yyyy-MM-dd')）")
    $lines += "# 每行：<worktree 目录名> <当时的 HEAD>。应在 /sync-knowledge 对账完成后刷新。"
    foreach ($t in $tracked) {
        if ($current.ContainsKey($t)) { $lines += "$t $($current[$t])" }
    }
    $lines | Out-File -LiteralPath $baselineFile -Encoding utf8
    Write-Output "staleness: 基线已刷新 → .claude/knowledge/.staleness-baseline"
    foreach ($t in $tracked) {
        if ($current.ContainsKey($t)) { Write-Output "  $t = $($current[$t].Substring(0,10))" }
    }
    exit 0
}

# ---------- 读基线 ----------
if (-not (Test-Path -LiteralPath $baselineFile)) {
    Write-Output "staleness: 基线缺失。先跑一次 /sync-knowledge 对账，然后执行本脚本 -Update 建立基线。"
    exit 2
}
$baseline = @{}
foreach ($line in (Get-Content -LiteralPath $baselineFile -Encoding UTF8)) {
    if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
    $parts = $line.Trim() -split '\s+'
    if ($parts.Count -ge 2) { $baseline[$parts[0]] = $parts[1] }
}

# ---------- 比对 ----------
$driftCount = 0
$baselineBroken = $false
foreach ($t in $tracked) {
    if (-not $current.ContainsKey($t)) { continue }
    $dirPath = Join-Path $root $t
    if (-not $baseline.ContainsKey($t)) {
        Write-Output "staleness: $t 不在基线中（新增的追踪目录？）—— 对账后 -Update 补入"
        $baselineBroken = $true
        continue
    }
    $base = $baseline[$t]
    git -C $dirPath cat-file -e "$base^{commit}"
    if ($LASTEXITCODE -ne 0) {
        Write-Output "staleness: $t 的基线提交 $($base.Substring(0,10)) 已不可达（历史被改写？）—— 对账后 -Update 重建"
        $baselineBroken = $true
        continue
    }
    if ($base -eq $current[$t]) {
        $msg = "staleness: $t 无提交漂移"
        if ($dirty[$t] -gt 0) { $msg += "（但有 $($dirty[$t]) 处未提交改动 —— 不计入基线比对）" }
        Write-Output $msg
        continue
    }
    $changed = @(git -C $dirPath diff --name-only "$base..HEAD" | Where-Object { $_ })
    $ahead   = (git -C $dirPath rev-list --count "$base..HEAD").Trim()
    $driftCount++
    Write-Output "staleness: $t 自基线以来有 $ahead 个提交、$($changed.Count) 个文件变更："
    $changed | Select-Object -First 20 | ForEach-Object { Write-Output "    $_" }
    if ($changed.Count -gt 20) { Write-Output "    …（其余 $($changed.Count - 20) 个略）" }
    if ($dirty[$t] -gt 0) { Write-Output "    另有 $($dirty[$t]) 处未提交改动" }
}

if ($baselineBroken) {
    Write-Output "staleness: 基线部分失效 —— 建议先 /sync-knowledge，再 -Update 重建。"
    exit 2
}
if ($driftCount -gt 0) {
    Write-Output "staleness: 事实来源已漂移 —— 建议运行 /sync-knowledge 对账，完成后执行本脚本 -Update 刷新基线。"
    exit 1
}
Write-Output "staleness: 全部追踪目录与基线一致，知识层无需刷新。"
exit 0
