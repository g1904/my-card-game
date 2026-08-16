#requires -Version 5.1
<#
    index-size-guard.ps1 - PostToolUse 钩子：台账文件体积告警（**只告警，绝不拦截**）。

    背景：`handoffs/_index.md` / `answer-logs/_index.md` /
    `open-questions/update-log.md` 三份台账曾各自长到 181KB / 51KB / 122KB，
    原因是每行都把被索引文件的整段叙述复述了一遍——违反
    `game-design-documents/decisions/ADR-0005` 的薄引用纪律。
    本钩子在这类文件被 Edit / Write 之后检查体积，超阈值就出声提醒。

    形态：读 stdin 的 PostToolUse 钩子 JSON，取 tool_input.file_path；
    若该路径命中下列任一模式且文件 > 20KB，打印一行中文告警。

      *_index.md                      （任何目录下的 _index.md 台账）
      open-questions/update-log.md
      answer-logs/_index.md

    **永不阻塞**：无论解析成败、文件是否存在，一律 exit 0。钩子的职责是提醒
    作者「这份索引又在长回台账」，而不是打断正在进行的编辑。

    ── 为什么用 PowerShell 而不是 python ──
    本机 python 3.14 与 node 均在 PATH 上（见 rules/environment-rules.md），
    三者都能胜任。选 PowerShell 的理由：仓库里其余脚本（push-all-impl /
    promote-impl / session-manager-impl）已全部是 PowerShell 5.1，保持
    单一运行时可以少一个依赖面；且本脚本只需一次 stdin 读取 + 一个
    ConvertFrom-Json，5.1 原生就够，不存在需要换语言的复杂度。
#>

# 单独包一层：钩子**任何情况下都不许**以非零码退出而拦住工具调用。
try {
    $raw = [Console]::In.ReadToEnd()
    if (-not $raw) { exit 0 }

    $payload = $raw | ConvertFrom-Json
    $path = $payload.tool_input.file_path
    if (-not $path) { exit 0 }

    if (-not (Test-Path -LiteralPath $path)) { exit 0 }

    # 统一成正斜杠，便于用同一套模式匹配 Windows / POSIX 两种写法。
    $norm = ($path -replace '\\', '/')
    $leaf = Split-Path -Leaf $norm

    $isIndex = ($leaf -like '*_index.md') `
        -or ($norm -like '*open-questions/update-log.md') `
        -or ($norm -like '*answer-logs/_index.md')
    if (-not $isIndex) { exit 0 }

    $limit = 20KB
    $size = (Get-Item -LiteralPath $path).Length
    if ($size -gt $limit) {
        $kb = [math]::Round($size / 1KB, 1)
        Write-Host ("[台账体积告警] {0} 已达 {1} KB（阈值 20 KB）——索引在长回台账了：每行只该留「指向哪份文件 + 一句话」，叙述归被索引的文件自身（见 game-design-documents/decisions/ADR-0005）。" -f $leaf, $kb)
    }
}
catch {
    # 静默吞掉一切异常：告警钩子出错不应该影响任何编辑操作。
}

exit 0
