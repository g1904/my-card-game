# Claude Code 会话管理器实现（绕过 --resume 的 50 条显示上限）
# 收藏数据存于本项目 .claude\session-tags.json（项目本地，按 session ID 记录）。
# 一般通过封装脚本 session-manager 调用；也可如下直接调用底层实现。
#
# 用法（在项目根目录运行；或用 -Project 指定路径）：
#   列出全部会话：        powershell -File .claude\scripts\session-manager-impl.ps1
#   只看最近 N 条：       ... -Top 20
#   关键词搜索（仅用户发言）：... -Grep "BIG_WH"
#   收藏一条（可用 ID 前缀，或 . 表示当前会话）：
#                         ... -Save ae6eb11d            或   ... -Save .
#   收藏并打标签（-Tags 支持多个，逗号分隔）：
#                         ... -Save ae6eb11d -Tags 库存审查,待跟进
#   取消收藏：            ... -Unsave ae6eb11d
#   给会话加标签：        ... -Tag ae6eb11d -Tags 库存审查,待跟进
#   移除某标签：          ... -Untag ae6eb11d -Tags 库存审查,待跟进
#   只看已收藏：          ... -Saved
#   按标签筛选收藏（须同时含全部所给标签）：... -Saved -Tags 库存审查,待跟进
# 参数大小写不敏感（-save / -Save / -SAVE 等价）。
param(
    [string]$Project = (Get-Location).Path,
    [int]$Top = 0,
    [string]$Grep,
    [string]$Save,
    [string]$Unsave,
    [string]$Tag,
    [string]$Untag,
    [string[]]$Tags,
    [switch]$Saved
)

# --- UTF-8 修正：控制台输出 + 文件读取都按 UTF-8，解决中文乱码 ---
$OutputEncoding = [System.Text.Encoding]::UTF8
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# --- 标签归一化：兼容多种入口传参 ---
# 原生 PowerShell 下 -Tags a,b 会被解析成数组 @('a','b')；但经 powershell -File 传参时
# 逗号不会被拆分，整串作为单个元素传入（如 'a,b'）。这里统一按 , ; 及全角 ，；再拆一遍，
# 保证无论从 bash 封装、.cmd 还是原生 PowerShell 调用，$Tags 最终都是干净的标签数组。
if ($Tags) {
    $Tags = @($Tags | ForEach-Object { $_ -split '[,，;；]' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

$root    = "$env:USERPROFILE\.claude\projects"
$tagFile = Join-Path (Split-Path $PSScriptRoot -Parent) 'session-tags.json'  # .claude\session-tags.json

# Claude Code 把 cwd 里的 : \ / . 等转成 -
$slug = ($Project -replace '[:\\/.]', '-')
$dir  = Join-Path $root $slug
if (-not (Test-Path $dir)) { Write-Error "找不到会话目录: $dir"; return }

# ---------- 收藏数据读写 ----------
function Load-Tags {
    $store = @{}
    if (Test-Path $tagFile) {
        $json = Get-Content $tagFile -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($p in $json.PSObject.Properties) {
            $tags = @(); if ($p.Value.tags) { $tags = @($p.Value.tags) }
            $store[$p.Name] = @{ tags = $tags; added = $p.Value.added }
        }
    }
    return $store
}
function Save-Tags($store) {
    if ($store.Count -eq 0) { '{}' | Out-File $tagFile -Encoding utf8 }
    else { ($store | ConvertTo-Json -Depth 5) | Out-File $tagFile -Encoding utf8 }
}
# 把 ID 前缀解析成完整 session id；'.' 或 'current' 或空 → 当前（最新）会话
function Resolve-Id($val) {
    if (-not $val -or $val -eq '.' -or $val -eq 'current') {
        $newest = Get-ChildItem $dir -Filter *.jsonl | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $newest) { Write-Error "该项目下没有会话"; return $null }
        return $newest.BaseName
    }
    $hits = Get-ChildItem $dir -Filter "$val*.jsonl"
    if ($hits.Count -eq 0) { Write-Error "没有匹配的会话: $val"; return $null }
    if ($hits.Count -gt 1) { Write-Error "前缀不唯一，匹配到 $($hits.Count) 条，请给更长前缀"; return $null }
    return $hits[0].BaseName
}
# 从会话文件提取一行预览（摘要 or 首条用户消息）
function Get-Preview($file) {
    $preview = ''
    foreach ($line in (Get-Content $file -TotalCount 40 -Encoding UTF8)) {
        try {
            $o = $line | ConvertFrom-Json
            if ($o.type -eq 'summary' -and $o.summary) { $preview = $o.summary; break }
            if ($o.type -eq 'user' -and $o.message.content) {
                $c = $o.message.content
                if ($c -is [string]) { $preview = $c } elseif ($c[0].text) { $preview = $c[0].text }
                if ($preview) { break }
            }
        } catch {}
    }
    if ($preview.Length -gt 60) { $preview = $preview.Substring(0, 60) }
    return ($preview -replace '\s+', ' ')
}

$store = Load-Tags

# ---------- 写操作：收藏 / 取消 / 打标签 / 移标签 ----------
if ($PSBoundParameters.ContainsKey('Save')) {
    $id = Resolve-Id $Save; if (-not $id) { return }
    if (-not $store.ContainsKey($id)) { $store[$id] = @{ tags = @(); added = (Get-Date).ToString('yyyy-MM-dd') } }
    if ($Tags) {
        foreach ($tg in $Tags) { if ($tg -and $store[$id].tags -notcontains $tg) { $store[$id].tags = @($store[$id].tags + $tg) } }
    }
    Save-Tags $store
    $t = if ($store[$id].tags) { " [标签: $($store[$id].tags -join ', ')]" } else { '' }
    Write-Host "★ 已收藏 $id$t" -ForegroundColor Green; return
}
if ($PSBoundParameters.ContainsKey('Unsave')) {
    $id = Resolve-Id $Unsave; if (-not $id) { return }
    if ($store.ContainsKey($id)) { $store.Remove($id); Save-Tags $store; Write-Host "☆ 已取消收藏 $id" -ForegroundColor Yellow }
    else { Write-Host "该会话未收藏: $id" -ForegroundColor Yellow }
    return
}
if ($PSBoundParameters.ContainsKey('Tag')) {
    if (-not $Tags) { Write-Error "请用 -Tags 指定标签名（可多个，逗号分隔），例如 -Tag $Tag -Tags 库存审查,待跟进"; return }
    $id = Resolve-Id $Tag; if (-not $id) { return }
    if (-not $store.ContainsKey($id)) { $store[$id] = @{ tags = @(); added = (Get-Date).ToString('yyyy-MM-dd') } }
    foreach ($tg in $Tags) { if ($tg -and $store[$id].tags -notcontains $tg) { $store[$id].tags = @($store[$id].tags + $tg) } }
    Save-Tags $store
    Write-Host "🏷 已给 $id 加标签 '$($Tags -join ', ')'（当前: $($store[$id].tags -join ', ')）" -ForegroundColor Green; return
}
if ($PSBoundParameters.ContainsKey('Untag')) {
    if (-not $Tags) { Write-Error "请用 -Tags 指定要移除的标签名（可多个，逗号分隔）"; return }
    $id = Resolve-Id $Untag; if (-not $id) { return }
    if ($store.ContainsKey($id)) {
        $store[$id].tags = @($store[$id].tags | Where-Object { $Tags -notcontains $_ })
        Save-Tags $store
        Write-Host "已从 $id 移除标签 '$($Tags -join ', ')'（剩余: $($store[$id].tags -join ', ')）" -ForegroundColor Yellow
    } else { Write-Host "该会话未收藏: $id" -ForegroundColor Yellow }
    return
}

# ---------- 读操作：列表 ----------
$files = Get-ChildItem $dir -Filter *.jsonl | Sort-Object LastWriteTime -Descending

if ($Saved) {
    $files = $files | Where-Object { $store.ContainsKey($_.BaseName) }
    if ($Tags) {
        # 须同时包含所给的全部标签（AND）
        $files = $files | Where-Object {
            $owned = $store[$_.BaseName].tags
            @($Tags | Where-Object { $owned -notcontains $_ }).Count -eq 0
        }
    }
}
if ($Grep) {
    # 仅在「用户发言」中搜索（type == user）
    $hitIds = foreach ($f in $files) {
        foreach ($line in (Get-Content $f.FullName -Encoding UTF8)) {
            if ($line -notmatch '"type"\s*:\s*"user"') { continue }
            try {
                $o = $line | ConvertFrom-Json
                if ($o.type -ne 'user' -or -not $o.message.content) { continue }
                $c = $o.message.content
                $txt = if ($c -is [string]) { $c } else { ($c | ForEach-Object { $_.text }) -join ' ' }
                if ($txt -and $txt -like "*$Grep*") { $f.BaseName; break }
            } catch {}
        }
    }
    $files = $files | Where-Object { $hitIds -contains $_.BaseName }
}
if ($Top -gt 0) { $files = $files | Select-Object -First $Top }

$rows = foreach ($f in $files) {
    $on = $store.ContainsKey($f.BaseName)
    [pscustomobject]@{
        '★'     = if ($on) { '★' } else { '' }
        Date    = $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
        Id      = $f.BaseName
        Tags    = if ($on) { $store[$f.BaseName].tags -join ',' } else { '' }
        Preview = Get-Preview $f.FullName
    }
}
$rows | Format-Table -AutoSize -Wrap

$scope = if ($Saved) { '已收藏' } elseif ($Grep) { "用户发言匹配 '$Grep'" } else { '全部' }
Write-Host "`n$scope 会话 $(@($files).Count) 条。  恢复: claude --resume <Id>   收藏: -Save <Id> [-Tags 标签1,标签2]" -ForegroundColor Cyan
