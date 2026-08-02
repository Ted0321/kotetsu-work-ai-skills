#!/usr/bin/env bash
# machine-hygiene / sweep.sh  (macOS / Linux / WSL / Git Bash)
#
# テスト実行で残ったヘッドレスブラウザを終了し、再生成可能なキャッシュを削除する。
#
# 既定は DRY-RUN（何も壊さず、消す対象を表示するだけ）。
# 実際に終了・削除するには --apply を付ける。
#
#   bash sweep.sh                 # 何が消えるか見るだけ
#   bash sweep.sh --apply         # 実行
#   bash sweep.sh --apply --deep  # OSの一時フォルダに残った自動化プロファイルも掃除
#
# 終了コードは常に 0（フックを止めないため）。
set -uo pipefail

VERSION="0.1.0"
APPLY=0
DO_PROCS=1
DO_CACHES=1
DEEP=0
QUIET=0
ROOT="$PWD"
MIN_AGE=3
EXCLUDES=()

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOS'

オプション:
  --apply           実際に終了・削除する（既定は dry-run）
  --deep            OSの一時フォルダに残った自動化プロファイルも対象にする
  --no-procs        プロセスの掃除をしない
  --no-caches       キャッシュの削除をしない
  --root PATH       対象プロジェクトのルート（既定: カレント）
  --min-age SEC     この秒数より新しいプロセスは触らない（既定: 3）
  --exclude NAME    このキャッシュ名は消さない（複数指定可）
  --quiet           何もなければ無出力（フック用）
  -h, --help        このヘルプ
EOS
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apply)      APPLY=1 ;;
    --deep)       DEEP=1 ;;
    --no-procs)   DO_PROCS=0 ;;
    --no-caches)  DO_CACHES=0 ;;
    --quiet)      QUIET=1 ;;
    --root)       ROOT="${2:-}"; shift ;;
    --min-age)    MIN_AGE="${2:-3}"; shift ;;
    --exclude)    EXCLUDES+=("${2:-}"); shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "sweep.sh: unknown option: $1" >&2; exit 0 ;;
  esac
  shift
done

# ---- 出力ヘルパ -------------------------------------------------------------
LINES=()
say() { LINES+=("$1"); }
flush() {
  [ "${#LINES[@]}" -eq 0 ] && return 0
  printf '%s\n' "${LINES[@]}"
}
human() { # KB -> 人が読める形
  local kb="${1:-0}"
  if   [ "$kb" -ge 1048576 ]; then awk -v k="$kb" 'BEGIN{printf "%.1fGB", k/1048576}'
  elif [ "$kb" -ge 1024 ];    then awk -v k="$kb" 'BEGIN{printf "%.0fMB", k/1024}'
  else printf '%sKB' "$kb"; fi
}

# ---- ルートの安全確認 -------------------------------------------------------
if ! ROOT="$(cd "$ROOT" 2>/dev/null && pwd -P)"; then
  echo "sweep.sh: --root が見つかりません" >&2; exit 0
fi
HOME_P="$(cd "$HOME" 2>/dev/null && pwd -P || echo "$HOME")"
# 削除を伴うときだけ、危険なルートを弾く（プロセス掃除だけなら関係ない）
if [ "$DO_CACHES" -eq 1 ] || [ "$DEEP" -eq 1 ]; then
  if [ "$ROOT" = "/" ] || [ "$ROOT" = "$HOME_P" ]; then
    echo "sweep.sh: 安全のため / と \$HOME 直下ではキャッシュ削除をしません（--root で指定するか --no-caches を付けてください）" >&2
    DO_CACHES=0
    DEEP=0
  fi
fi

# ---- 1) 残ったヘッドレスブラウザ --------------------------------------------
# 自動化でしか付かないフラグ／パスだけを対象にする。
HEADLESS_RE='(--headless|--remote-debugging-port|--remote-debugging-pipe|ms-playwright|puppeteer_dev_chrome_profile|\.cache/puppeteer|/chromedriver|/geckodriver|/msedgedriver|selenium-manager)'
# 普段使いのブラウザ（実プロファイル）は絶対に触らない。
REAL_PROFILE_RE='(Application Support/Google/Chrome|Application Support/Chromium|Application Support/Firefox|Application Support/Microsoft Edge|\.config/google-chrome|\.config/chromium|\.config/microsoft-edge|\.mozilla/firefox|AppData/Local/Google/Chrome/User Data)'

etime_to_secs() { # [[dd-]hh:]mm:ss -> 秒
  local t="${1:-0}" d=0 h=0 m=0 s=0 a b c
  case "$t" in *-*) d="${t%%-*}"; t="${t#*-}" ;; esac
  IFS=: read -r a b c <<<"$t"
  if   [ -n "${c:-}" ]; then h="$a"; m="$b"; s="$c"
  elif [ -n "${b:-}" ]; then m="$a"; s="$b"
  else s="${a:-0}"; fi
  echo $(( 10#${d:-0} * 86400 + 10#${h:-0} * 3600 + 10#${m:-0} * 60 + 10#${s:-0} ))
}

KILL_PIDS=()
KILL_RSS=0
if [ "$DO_PROCS" -eq 1 ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    read -r pid etime rss args <<<"$line"
    [ "$pid" = "$$" ] && continue
    case "$args" in *"machine-hygiene"*) continue ;; esac
    printf '%s' "$args" | grep -Eqi "$HEADLESS_RE" || continue
    printf '%s' "$args" | grep -Eqi "$REAL_PROFILE_RE" && continue
    [ "$(etime_to_secs "$etime")" -lt "$MIN_AGE" ] && continue
    KILL_PIDS+=("$pid")
    KILL_RSS=$(( KILL_RSS + ${rss:-0} ))
  done < <(ps -eo pid=,etime=,rss=,args= 2>/dev/null)
fi

if [ "${#KILL_PIDS[@]}" -gt 0 ]; then
  if [ "$APPLY" -eq 1 ]; then
    kill -TERM "${KILL_PIDS[@]}" 2>/dev/null
    sleep 2
    for p in "${KILL_PIDS[@]}"; do kill -0 "$p" 2>/dev/null && kill -KILL "$p" 2>/dev/null; done
    say "ヘッドレス残骸を終了: ${#KILL_PIDS[@]}件（メモリ約 $(human "$KILL_RSS") 解放）"
  else
    say "[dry-run] 終了対象のヘッドレス残骸: ${#KILL_PIDS[@]}件（メモリ約 $(human "$KILL_RSS")） pid: ${KILL_PIDS[*]}"
  fi
fi

# ---- 2) プロジェクト内のキャッシュ ------------------------------------------
# すべて「消しても再生成される」ものだけ。ソース・.git・.env は対象外。
CACHE_DIRS=(
  "node_modules/.cache" "node_modules/.vite" ".next/cache" ".turbo" ".parcel-cache"
  ".vite" ".nuxt" ".svelte-kit" ".astro" ".angular/cache" ".eslintcache"
  "coverage" ".nyc_output" "test-results" "playwright-report" "blob-report"
  ".pytest_cache" ".mypy_cache" ".ruff_cache"
)

dir_kb() { du -sk "$1" 2>/dev/null | awk '{print $1}'; }

REMOVED=0
FREED_KB=0
if [ "$DO_CACHES" -eq 1 ]; then
  for rel in "${CACHE_DIRS[@]}"; do
    skip=0
    for ex in "${EXCLUDES[@]:-}"; do [ -n "$ex" ] && [ "$ex" = "$rel" ] && skip=1; done
    [ "$skip" -eq 1 ] && continue

    target="$ROOT/$rel"
    [ -e "$target" ] || continue
    # ルート配下であることを再確認（シンボリックリンク経由の脱出を防ぐ）
    real="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)/$(basename "$target")"
    case "$real" in "$ROOT"/*) ;; *) continue ;; esac

    kb="$(dir_kb "$target")"; kb="${kb:-0}"
    FREED_KB=$(( FREED_KB + kb ))
    REMOVED=$(( REMOVED + 1 ))
    if [ "$APPLY" -eq 1 ]; then
      rm -rf -- "$target"
    else
      say "[dry-run] 削除対象: $rel（$(human "$kb")）"
    fi
  done

  # __pycache__ は再帰的に（.git と node_modules の中は見ない）
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    kb="$(dir_kb "$d")"; kb="${kb:-0}"
    FREED_KB=$(( FREED_KB + kb ))
    REMOVED=$(( REMOVED + 1 ))
    if [ "$APPLY" -eq 1 ]; then rm -rf -- "$d"; else say "[dry-run] 削除対象: ${d#"$ROOT"/}（$(human "$kb")）"; fi
  done < <(find "$ROOT" \( -name .git -o -name node_modules \) -prune -o -type d -name '__pycache__' -print 2>/dev/null)
fi

# ---- 3) --deep: OSの一時フォルダに残った自動化プロファイル -------------------
if [ "$DEEP" -eq 1 ]; then
  TMPROOT="${TMPDIR:-/tmp}"
  TMPROOT="${TMPROOT%/}"
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    kb="$(dir_kb "$d")"; kb="${kb:-0}"
    FREED_KB=$(( FREED_KB + kb ))
    REMOVED=$(( REMOVED + 1 ))
    if [ "$APPLY" -eq 1 ]; then rm -rf -- "$d"; else say "[dry-run] 一時フォルダ削除対象: $d（$(human "$kb")）"; fi
  done < <(find "$TMPROOT" -maxdepth 1 -mindepth 1 -uid "$(id -u)" -mmin +60 \
             \( -name 'playwright*' -o -name 'puppeteer_dev_*' -o -name '.org.chromium.Chromium.*' \
                -o -name '.com.google.Chrome.*' -o -name 'chromedriver*' -o -name 'scoped_dir*' \
                -o -name 'geckodriver*' -o -name 'rust_mozprofile*' \) -print 2>/dev/null)
fi

if [ "$REMOVED" -gt 0 ] && [ "$APPLY" -eq 1 ]; then
  say "キャッシュ／残骸を削除: ${REMOVED}箇所（$(human "$FREED_KB") 解放）"
fi

if [ "${#LINES[@]}" -eq 0 ]; then
  [ "$QUIET" -eq 1 ] || echo "[machine-hygiene] 掃除するものはありませんでした"
  exit 0
fi

echo "[machine-hygiene v$VERSION]"
flush
exit 0
