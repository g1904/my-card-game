#!/bin/bash
input=$(cat)

# 按【完整路径】一次性取出字段，每行一个。
# 优先 jq；本机没装则用 python（按路径取值，不会像 sed 那样按字段名全局误匹配——
# used_percentage 在 payload 里出现 3 次：context_window / rate_limits.five_hour / rate_limits.seven_day）。
if command -v jq >/dev/null 2>&1; then
  FIELDS=$(printf '%s' "$input" | jq -r '
    [ .model.display_name // "Claude",
      .effort.level // "?",
      .workspace.current_dir // "",
      .context_window.used_percentage // 0,
      .context_window.context_window_size // 200000,
      (.rate_limits.five_hour.used_percentage // -1),
      (.rate_limits.seven_day.used_percentage // -1) ] | .[] | tostring' 2>/dev/null)
else
  FIELDS=$(printf '%s' "$input" | python -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
def g(path, default):
    cur = d
    for k in path:
        if not isinstance(cur, dict):
            return default
        cur = cur.get(k)
        if cur is None:
            return default
    return cur
for p, dv in ((("model","display_name"),"Claude"),
              (("effort","level"),"?"),
              (("workspace","current_dir"),""),
              (("context_window","used_percentage"),0),
              (("context_window","context_window_size"),200000),
              (("rate_limits","five_hour","used_percentage"),-1),
              (("rate_limits","seven_day","used_percentage"),-1)):
    print(g(p, dv))
' 2>/dev/null)
fi

FIELDS=${FIELDS//$'\r'/}   # Windows 上 python/jq 输出 CRLF，\r 会污染数值运算
{ read -r MODEL; read -r EFFORT; read -r DIR; read -r PCT; read -r SIZE; read -r H5; read -r D7; } <<< "$FIELDS"

# 解析器整个挂掉时的兜底（read 读不到 -> 空串）
MODEL=${MODEL:-Claude}
EFFORT=${EFFORT:-?}
DIR=${DIR:-$PWD}; DIR=${DIR//\\//}          # Windows 路径统一成 / 便于取末段
PCT=${PCT:-0};   PCT=${PCT%%.*};  PCT=${PCT:-0}
SIZE=${SIZE:-200000}; SIZE=${SIZE%%.*}; SIZE=${SIZE:-200000}
H5=${H5:--1}; H5=${H5%%.*}; H5=${H5:--1}
D7=${D7:--1}; D7=${D7%%.*}; D7=${D7:--1}

# absolute tokens matter more than % on a 1M window
USED=$((PCT * SIZE / 100000))   # in thousands

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; DIM='\033[2m'; RESET='\033[0m'
# session token：<=200k 绿，200-300k 黄，>=300k 红
if   [ "$USED" -ge 300 ]; then C="$RED"
elif [ "$USED" -gt 200 ]; then C="$YELLOW"
else C="$GREEN"; fi

# 配额：>80% 黄，>95% 红
lim_color() {
  if   [ "$1" -gt 95 ]; then printf '%s' "$RED"
  elif [ "$1" -gt 80 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}
# 7d、5h 缺失时整段省略，逗号不留孤儿
PARTS=()
[ "$D7" -ge 0 ] && PARTS+=("${DIM}7d${RESET} $(lim_color "$D7")${D7}%${RESET}")
[ "$H5" -ge 0 ] && PARTS+=("${DIM}5h${RESET} $(lim_color "$H5")${H5}%${RESET}")
PARTS+=("${DIM}Session${RESET} ${C}${USED}k${RESET}")

METRICS=""
for p in "${PARTS[@]}"; do
  [ -n "$METRICS" ] && METRICS="${METRICS}${DIM},${RESET} "
  METRICS="${METRICS}${p}"
done

BRANCH=""
git rev-parse --git-dir >/dev/null 2>&1 && BRANCH=" ${DIM}🌿 $(git branch --show-current 2>/dev/null)${RESET}"

printf "%b\n" "${DIM}${DIR##*/}${RESET}${BRANCH} ${DIM}|${RESET} $MODEL ${DIM}·${RESET} $EFFORT ${DIM}|${RESET} ${METRICS}"
