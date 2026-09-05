# verify-config.ps1 —— .claude 配置的确定性自检
#
# 给 /sync-knowledge 与 /update-readme 这两个模型驱动对账补一个零成本的确定性底座。
# 只做能机械判定的检查，语义层面的漂移（副本化、过时、术语）仍归 /sync-knowledge。
#
# 检查项：
#   1. skills/<name>/SKILL.md 存在且 frontmatter name 与文件夹名一致
#   2. rules/*.md 全部在 Context.md 中登记
#   3. rules / skills / knowledge 内指向 .claude、两个设计库、main 的 .md 引用不悬空
#      （代码围栏内的示例路径不检查；含占位符 <…> / * 的路径天然不匹配、自动跳过）
#   4. knowledge/* 薄引用层不含代码块（ADR-0005；引擎实践类 standards 三份豁免）
#   5. knowledge 各子目录的 _index.md 未漏登记同目录文件
#
# 用法： powershell -NoProfile -ExecutionPolicy Bypass -File .claude\scripts\verify-config.ps1
# 退出码： 0 = 全绿；1 = 有待处理项（逐条打印，多为该跑 /sync-knowledge 或 /update-readme 的信号）

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$claudeDir = Split-Path -Parent $PSScriptRoot
$root      = Split-Path -Parent $claudeDir

# —— 项目常量（与 ScryfallExtension 版本的唯一差异在这里）——
$refPattern  = '(?:\.claude|game-design-documents|backend-design-documents|main)/[\w\-./]+?\.md'
$fenceExempt = @(
    'knowledge\architecture.md',   # 结构树图围栏是导航形态，不是设计副本
    'knowledge\standards\csharp-conventions.md',
    'knowledge\standards\godot-scene-conventions.md',
    'knowledge\standards\mobile-portrait-ui.md'
)

$issues = New-Object System.Collections.Generic.List[string]

function RelPath([string]$full) {
    return $full.Substring($claudeDir.Length + 1) -replace '\\', '/'
}

# ---------- 1. skills frontmatter ----------
foreach ($dir in (Get-ChildItem (Join-Path $claudeDir 'skills') -Directory)) {
    $skill = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skill)) {
        $issues.Add("skills/$($dir.Name)/ 缺少 SKILL.md")
        continue
    }
    $m = Select-String -LiteralPath $skill -Pattern '^name:\s*(\S+)' -Encoding UTF8 | Select-Object -First 1
    if ($null -eq $m) {
        $issues.Add("skills/$($dir.Name)/SKILL.md 缺少 frontmatter name")
    } elseif ($m.Matches[0].Groups[1].Value -ne $dir.Name) {
        $issues.Add("skills/$($dir.Name)/SKILL.md 的 frontmatter name '$($m.Matches[0].Groups[1].Value)' 与文件夹名不一致")
    }
}

# ---------- 2. rules 全部登记进 Context.md ----------
$contextPath = Join-Path $claudeDir 'rules\Context.md'
$contextRaw  = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8
foreach ($rule in (Get-ChildItem (Join-Path $claudeDir 'rules') -Filter *.md | Where-Object Name -ne 'Context.md')) {
    if ($contextRaw.IndexOf(".claude/rules/$($rule.Name)") -lt 0) {
        $issues.Add("rules/$($rule.Name) 未在 Context.md 中登记")
    }
}

# ---------- 3. 悬空引用 ----------
$scanFiles = @()
$scanFiles += Get-ChildItem (Join-Path $claudeDir 'rules')   -Filter *.md
$scanFiles += Get-ChildItem (Join-Path $claudeDir 'skills')  -Recurse -Filter SKILL.md
$scanFiles += Get-ChildItem (Join-Path $claudeDir 'knowledge') -Recurse -Filter *.md
foreach ($f in $scanFiles) {
    $rel = RelPath $f.FullName
    $inFence = $false
    $lineNo  = 0
    foreach ($line in (Get-Content -LiteralPath $f.FullName -Encoding UTF8)) {
        $lineNo++
        if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        foreach ($m in [regex]::Matches($line, $refPattern)) {
            # 示例路径不检查：含 xxx / .... 占位，或由「如 / 例如」引导的举例
            if ($m.Value -match 'xxx|\.\.\.\.') { continue }
            if ($line.Substring(0, $m.Index) -match '[（(]如|例如') { continue }
            # 有意的前向引用不算悬空（正文声明该文档「预期但未存在 / 尚不存在」）
            if ($line -match '尚不存在|未存在') { continue }
            $target = Join-Path $root ($m.Value -replace '/', '\')
            if (-not (Test-Path -LiteralPath $target)) {
                $issues.Add("悬空引用: ${rel}:${lineNo} → $($m.Value)")
            }
        }
    }
}

# ---------- 4. 薄引用层不含代码块 ----------
foreach ($f in (Get-ChildItem (Join-Path $claudeDir 'knowledge') -Recurse -Filter *.md)) {
    $relWin = $f.FullName.Substring($claudeDir.Length + 1)
    if ($fenceExempt -contains $relWin) { continue }
    $raw = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    if ($raw -match '(?m)^\s*```') {
        $issues.Add("薄引用层含代码块: $(RelPath $f.FullName) —— 核对是否为设计副本（ADR-0005），是则用 /sync-knowledge 压回引用")
    }
}

# ---------- 5. _index.md 漏登记 ----------
foreach ($dir in (Get-ChildItem (Join-Path $claudeDir 'knowledge') -Recurse -Directory)) {
    $idx = Join-Path $dir.FullName '_index.md'
    if (-not (Test-Path -LiteralPath $idx)) { continue }
    $idxRaw = Get-Content -LiteralPath $idx -Raw -Encoding UTF8
    foreach ($md in (Get-ChildItem $dir.FullName -Filter *.md | Where-Object Name -ne '_index.md')) {
        if ($idxRaw.IndexOf($md.Name) -lt 0) {
            $issues.Add("$(RelPath $idx) 未登记同目录文件 $($md.Name)")
        }
    }
}

# ---------- 输出 ----------
if ($issues.Count -eq 0) {
    Write-Output "verify-config: 全绿（skills frontmatter / rules 登记 / 引用完整性 / 薄引用纪律 / _index 台账）"
    exit 0
}
Write-Output "verify-config: $($issues.Count) 项待处理"
foreach ($i in $issues) { Write-Output "  - $i" }
exit 1
