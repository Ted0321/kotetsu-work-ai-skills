#!/usr/bin/env bash
# machine-hygiene / audit.sh  (macOS / Linux / WSL / Git Bash)
#
# 読み取り専用のマシン監査。何も終了せず、何も削除しない。
# Markdownで出すので、そのままAIに読ませて「次に自動化できること」を出させる。
#
#   bash audit.sh            # カレントをプロジェクトルートとして監査
#   bash audit.sh --root ../ # ルートを指定
set -uo pipefail

ROOT="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-$PWD}"; shift ;;
    -h|--help) echo "usage: bash audit.sh [--root PATH]"; exit 0 ;;
    *) shift ;;
  esac
  shift
done
ROOT="$(cd "$ROOT" 2>/dev/null && pwd -P || echo "$PWD")"

human() {
  local kb="${1:-0}"
  if   [ "$kb" -ge 1048576 ]; then awk -v k="$kb" 'BEGIN{printf "%.1fGB", k/1048576}'
  elif [ "$kb" -ge 1024 ];    then awk -v k="$kb" 'BEGIN{printf "%.0fMB", k/1024}'
  else printf '%sKB' "$kb"; fi
}
etime_to_secs() {
  local t="${1:-0}" d=0 h=0 m=0 s=0 a b c
  case "$t" in *-*) d="${t%%-*}"; t="${t#*-}" ;; esac
  IFS=: read -r a b c <<<"$t"
  if   [ -n "${c:-}" ]; then h="$a"; m="$b"; s="$c"
  elif [ -n "${b:-}" ]; then m="$a"; s="$b"
  else s="${a:-0}"; fi
  echo $(( 10#${d:-0}*86400 + 10#${h:-0}*3600 + 10#${m:-0}*60 + 10#${s:-0} ))
}

HEADLESS_RE='(--headless|--remote-debugging-port|--remote-debugging-pipe|ms-playwright|puppeteer_dev_chrome_profile|\.cache/puppeteer|/chromedriver|/geckodriver|/msedgedriver|selenium-manager)'
REAL_PROFILE_RE='(Application Support/Google/Chrome|Application Support/Chromium|Application Support/Firefox|Application Support/Microsoft Edge|\.config/google-chrome|\.config/chromium|\.config/microsoft-edge|\.mozilla/firefox)'
RUNNER_RE='(vitest|jest|playwright(\.js)? test|pytest|mocha|karma|cypress|webdriver|node --test)'

echo "# マシン監査 — $(date '+%Y-%m-%d %H:%M')"
echo
echo "対象プロジェクト: \`$ROOT\`"
echo

# ---- 1) ヘッドレス残骸 -------------------------------------------------------
HL_N=0; HL_RSS=0; HL_OLD=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  read -r pid etime rss args <<<"$line"
  case "$args" in *"machine-hygiene"*) continue ;; esac
  printf '%s' "$args" | grep -Eqi "$HEADLESS_RE" || continue
  printf '%s' "$args" | grep -Eqi "$REAL_PROFILE_RE" && continue
  age="$(etime_to_secs "$etime")"
  HL_N=$(( HL_N + 1 )); HL_RSS=$(( HL_RSS + ${rss:-0} ))
  [ "$age" -gt "$HL_OLD" ] && HL_OLD="$age"
done < <(ps -eo pid=,etime=,rss=,args= 2>/dev/null)

RUN_N=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  read -r pid etime rss args <<<"$line"
  case "$args" in *"machine-hygiene"*|*"audit.sh"*) continue ;; esac
  printf '%s' "$args" | grep -Eqi "$RUNNER_RE" || continue
  [ "$(etime_to_secs "$etime")" -lt 900 ] && continue
  RUN_N=$(( RUN_N + 1 ))
done < <(ps -eo pid=,etime=,rss=,args= 2>/dev/null)

echo "## 1. テストの残骸"
echo
echo "| 項目 | 値 |"
echo "|---|---|"
echo "| 残っているヘッドレスブラウザ | ${HL_N}件 |"
echo "| そのメモリ合計 | $(human "$HL_RSS") |"
echo "| 最も古い残骸の経過時間 | $(( HL_OLD / 60 ))分 |"
echo "| 15分以上生きているテストランナー | ${RUN_N}件 |"
echo

# ---- 2) 重いプロセス ---------------------------------------------------------
echo "## 2. いま重いプロセス（上位5）"
echo
echo '```'
ps -eo pcpu=,pmem=,rss=,comm= 2>/dev/null | sort -rn | head -5 | \
  awk '{printf "CPU %5s%%  MEM %5s%%  RSS %6.0fMB  %s\n", $1, $2, $3/1024, $4}'
echo '```'
echo

# ---- 3) プロジェクト内のキャッシュ ------------------------------------------
CACHE_DIRS=(
  "node_modules/.cache" "node_modules/.vite" ".next/cache" ".turbo" ".parcel-cache"
  ".vite" ".nuxt" ".svelte-kit" ".astro" ".angular/cache" ".eslintcache"
  "coverage" ".nyc_output" "test-results" "playwright-report" "blob-report"
  ".pytest_cache" ".mypy_cache" ".ruff_cache"
)
echo "## 3. 消していいキャッシュ（プロジェクト内）"
echo
TOTAL_KB=0
FOUND=0
{
  echo "| パス | サイズ |"
  echo "|---|---|"
  for rel in "${CACHE_DIRS[@]}"; do
    [ -e "$ROOT/$rel" ] || continue
    kb="$(du -sk "$ROOT/$rel" 2>/dev/null | awk '{print $1}')"; kb="${kb:-0}"
    TOTAL_KB=$(( TOTAL_KB + kb ))
    FOUND=$(( FOUND + 1 ))
    echo "| \`$rel\` | $(human "$kb") |"
  done
  PYC_KB=0
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    k="$(du -sk "$d" 2>/dev/null | awk '{print $1}')"; PYC_KB=$(( PYC_KB + ${k:-0} ))
  done < <(find "$ROOT" \( -name .git -o -name node_modules \) -prune -o -type d -name '__pycache__' -print 2>/dev/null)
  if [ "$PYC_KB" -gt 0 ]; then
    TOTAL_KB=$(( TOTAL_KB + PYC_KB ))
    FOUND=$(( FOUND + 1 ))
    echo "| \`__pycache__\`（再帰） | $(human "$PYC_KB") |"
  fi
  [ "$FOUND" -eq 0 ] && echo "| （なし） | - |"
  echo
  echo "**合計: $(human "$TOTAL_KB")**"
}
echo

# ---- 4) 一時フォルダの自動化残骸 ---------------------------------------------
TMPROOT="${TMPDIR:-/tmp}"; TMPROOT="${TMPROOT%/}"
TMP_N=0; TMP_KB=0
while IFS= read -r d; do
  [ -z "$d" ] && continue
  k="$(du -sk "$d" 2>/dev/null | awk '{print $1}')"
  TMP_N=$(( TMP_N + 1 )); TMP_KB=$(( TMP_KB + ${k:-0} ))
done < <(find "$TMPROOT" -maxdepth 1 -mindepth 1 -uid "$(id -u)" \
           \( -name 'playwright*' -o -name 'puppeteer_dev_*' -o -name '.org.chromium.Chromium.*' \
              -o -name '.com.google.Chrome.*' -o -name 'chromedriver*' -o -name 'scoped_dir*' \
              -o -name 'geckodriver*' -o -name 'rust_mozprofile*' \) -print 2>/dev/null)

echo "## 4. 一時フォルダに残った自動化プロファイル"
echo
echo "\`$TMPROOT\` に ${TMP_N}件 / $(human "$TMP_KB")"
echo

# ---- 5) ディスク --------------------------------------------------------------
echo "## 5. ディスク"
echo
echo '```'
df -h "$ROOT" 2>/dev/null | tail -2
echo '```'
echo

# ---- 6) 判定 -----------------------------------------------------------------
echo "## 6. 判定"
echo
NEED=0
[ "$HL_N" -gt 0 ] && { echo "- ヘッドレス残骸が ${HL_N}件（$(human "$HL_RSS")）。テスト後の自動終了フックを入れる価値あり。"; NEED=1; }
[ "$RUN_N" -gt 0 ] && { echo "- 15分以上生きているテストランナーが ${RUN_N}件。ハングしたまま放置されている可能性。"; NEED=1; }
[ "$TOTAL_KB" -gt 524288 ] && { echo "- プロジェクト内キャッシュが $(human "$TOTAL_KB")。セッション終了時の自動削除が効く。"; NEED=1; }
[ "$TMP_KB" -gt 524288 ] && { echo "- 一時フォルダの自動化残骸が $(human "$TMP_KB")。\`sweep --apply --deep\` の対象。"; NEED=1; }
[ "$NEED" -eq 0 ] && echo "- 特に問題なし。掃除不要。"
echo
echo "> 実行するには: \`bash scripts/sweep.sh\`（確認）→ \`bash scripts/sweep.sh --apply\`（実行）"
