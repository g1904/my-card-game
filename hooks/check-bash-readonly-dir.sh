#!/bin/bash
# PreToolUse(Bash) 守卫：拦截**写入四个只读快照目录**的 Bash 命令。
#   只读目录：game-testing-branch/ · game-production-branch/
#             backend-testing-branch/ · backend-production-branch/
#   （settings.json 的 Edit deny 已拦截文件编辑工具；本钩子补上 Bash 写入这个缺口。）
# 只读访问（cat / grep / diff / git show 等）照常放行；
# git 子命令一律放行 —— 分支提升走根级 promote.cmd / push-all.cmd，本钩子不干涉 git。
#
# 判定方式：路径 token 正则直接匹配四个目录名（本项目目录名固定，无需解析器）。
# stdin 是 JSON，用 python 解析（本机没有 jq）。python 缺失或 JSON 解析失败 → 拒绝（exit 2）。
INPUT=$(cat)

PY=$(cat <<'PYEOF'
import sys, json, re, shlex

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(3)

command = (data.get('tool_input') or {}).get('command') or ''
if not command:
    sys.exit(0)

# 只匹配**路径 token**（前后是分隔符/引号/串首尾），不匹配裸子串；兼容 / 与 \ 两种分隔符。
RO = re.compile(r'(?:^|[\s/\\=:\'"(])(?:game|backend)-(?:testing|production)-branch(?=$|[/\\\s\'")])')

def is_readonly_target(token):
    return bool(RO.search(token))

def block(reason, snippet):
    sys.stderr.write(
        'BLOCKED: %s。四个快照目录（game-testing-branch/ game-production-branch/ '
        'backend-testing-branch/ backend-production-branch/）只读；代码只写 '
        'game-feature-branch/ 与 backend-feature-branch/。命令片段: %s\n'
        % (reason, snippet[:200])
    )
    sys.exit(2)

# ------------------------------------------------------- 1) 重定向写入检查 ----
for m in re.finditer(r'\d*>{1,2}\s*([^\s;|&<>]+)', command):
    if is_readonly_target(m.group(1)):
        block('重定向写入只读快照目录', m.group(0))

# ------------------------------------------------ 2) 逐条简单命令的检查 ----
segments = re.split(r'(?:\|\|?|&&|;|\n)', command)
WRITE_CMDS = {'sed', 'rm', 'touch', 'truncate', 'tee', 'dd', 'install',
              'ln', 'mkdir', 'rmdir', 'unlink', 'shred'}
MOVE_CMDS = {'mv', 'cp', 'rsync', 'scp'}

for seg in segments:
    seg = seg.strip()
    if not seg:
        continue
    try:
        # posix=False：保留 Windows 反斜杠路径（posix 模式会把 \ 当转义吃掉）。
        tokens = shlex.split(seg, posix=False)
    except ValueError:
        tokens = seg.split()
    if not tokens:
        continue
    i = 0
    while i < len(tokens) and re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', tokens[i]):
        i += 1
    if i >= len(tokens):
        continue
    cmd = tokens[i].rsplit('/', 1)[-1]
    args = tokens[i + 1:]

    if cmd == 'sed':
        if any(a == '-i' or a.startswith('-i') or a == '--in-place' or a.startswith('--in-place=')
               for a in args if a.startswith('-')):
            if any(is_readonly_target(a) for a in args if not a.startswith('-')):
                block('sed -i 就地修改只读快照目录', seg)
        continue

    if cmd in WRITE_CMDS:
        if any(is_readonly_target(a) for a in args if not a.startswith('-')):
            block(cmd + ' 写入只读快照目录', seg)
        continue

    if cmd in MOVE_CMDS:
        # 只在**目标**（最后一个位置参数）落在只读目录时拦截；
        # 从快照目录拷贝出来做交叉对比是合法的高频操作。
        positional = [a for a in args if not a.startswith('-')]
        if positional and is_readonly_target(positional[-1]):
            block(cmd + ' 目标位于只读快照目录', seg)
        continue

sys.exit(0)
PYEOF
)

printf '%s' "$INPUT" | python -X utf8 -c "$PY"
STATUS=$?

if [[ $STATUS -eq 0 ]]; then
  exit 0
elif [[ $STATUS -eq 2 ]]; then
  exit 2
else
  echo "BLOCKED: check-bash-readonly-dir hook 无法解析输入 (python exit=$STATUS)，为安全起见拒绝本次操作。" >&2
  exit 2
fi
