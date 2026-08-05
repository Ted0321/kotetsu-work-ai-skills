#!/usr/bin/env bash
# claude-cleanup.sh — Claude Code が溜め込む古いデータを安全に片付ける週次スクリプト (macOS / Linux)
# 配布元: https://github.com/Ted0321/kotetsu-work-ai-skills (skills/claude-cache-cleanup)
#
# 安全設計（このスクリプトが守ること）:
#   1. 下の TARGETS に列挙した場所しか触らない（allowlist方式）
#   2. 保持日数より新しいファイルには触らない → アクティブ・直近のものは構造的に対象外
#   3. ファイル単位で削除する。ディレクトリ丸ごとの rm -rf はしない
#      （削除後に空になったサブフォルダのみ削除する）
#   4. projects/ 配下は *.jsonl（セッションログ）だけを対象にする
#      → 同居している自動メモリ (memory/) 等は消さない
#   5. 保持日数 7日未満では起動を拒否する
#
# 使い方:
#   DRY_RUN=1 bash claude-cleanup.sh   # 削除せず、対象の件数とサイズだけ表示
#   bash claude-cleanup.sh             # 実行（毎週これがスケジューラから呼ばれる）

set -u
LC_ALL=C
export LC_ALL

# ===== 設定（編集してよいのはここだけ） =====
RETENTION_DAYS="${RETENTION_DAYS:-30}"                    # セッションログ等の保持日数
SNAPSHOT_RETENTION_DAYS="${SNAPSHOT_RETENTION_DAYS:-14}"  # シェルスナップショットの保持日数
LOG_FILE="${LOG_FILE:-$HOME/.claude/cleanup/cleanup.log}"
# ==========================================

DRY_RUN="${DRY_RUN:-0}"
TMP_BASE="${TMPDIR:-/tmp}"
TMP_BASE="${TMP_BASE%/}"

# 安全装置: 保持日数は数値かつ7日以上のみ許可
case "${RETENTION_DAYS}${SNAPSHOT_RETENTION_DAYS}" in
  *[!0-9]*) echo "ERROR: 保持日数は数値で指定してください" >&2; exit 1 ;;
esac
if [ "$RETENTION_DAYS" -lt 7 ] || [ "$SNAPSHOT_RETENTION_DAYS" -lt 7 ]; then
  echo "ERROR: 保持日数7日未満は許可されていません (RETENTION_DAYS=$RETENTION_DAYS, SNAPSHOT_RETENTION_DAYS=$SNAPSHOT_RETENTION_DAYS)" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")" || exit 1

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"; }

kb_of() { du -sk "$1" 2>/dev/null | cut -f1; }

# 標準入力のファイル一覧の合計KB（ファイル名の空白に対応）
sum_kb() { tr '\n' '\0' | xargs -0 du -k 2>/dev/null | awk '{s+=$1} END{print s+0}'; }

# KB を読みやすい単位にする
human_kb() {
  if [ "$1" -ge 1048576 ]; then echo "約$(($1 / 1048576))GB"
  elif [ "$1" -ge 1024 ]; then echo "約$(($1 / 1024))MB"
  else echo "${1}KB"
  fi
}

# dir 内で days より古い対象ファイルを列挙（filter が "-" ならファイル名の絞り込みなし）
list_old() {
  if [ "$3" = "-" ]; then
    find "$1" -type f -mtime +"$2" 2>/dev/null
  else
    find "$1" -type f -name "$3" -mtime +"$2" 2>/dev/null
  fi
}

files_deleted=0
kb_freed=0

clean_dir() { # $1=dir $2=days $3=name filter
  dir="$1"; days="$2"; filter="$3"
  [ -d "$dir" ] || return 0
  # 安全装置: HOME か一時領域の下以外は何があっても触らない
  case "$dir" in
    "$HOME"/*|"$TMP_BASE"/*) ;;
    *) log "SKIP(unsafe path): $dir"; return 0 ;;
  esac
  count=$(list_old "$dir" "$days" "$filter" | grep -c .)
  if [ "$DRY_RUN" = "1" ]; then
    kb=0
    [ "$count" -gt 0 ] && kb=$(list_old "$dir" "$days" "$filter" | sum_kb)
    log "DRY-RUN: $dir : ${count}件 / $(human_kb "$kb") が対象（${days}日より古いもの）"
    return 0
  fi
  before=$(kb_of "$dir"); before=${before:-0}
  if [ "$count" -gt 0 ]; then
    list_old "$dir" "$days" "$filter" | tr '\n' '\0' | xargs -0 rm -f -- 2>/dev/null
  fi
  find "$dir" -mindepth 1 -type d -empty -delete 2>/dev/null
  after=$(kb_of "$dir"); after=${after:-0}
  freed=$((before - after)); [ "$freed" -lt 0 ] && freed=0
  files_deleted=$((files_deleted + count))
  kb_freed=$((kb_freed + freed))
  [ "$count" -gt 0 ] && log "CLEAN: $dir : ${count}件削除 / $(human_kb "$freed")回収"
  return 0
}

# 掃除対象のallowlist（形式: ディレクトリ|保持日数|ファイル名フィルタ）
# ここに無い場所は絶対に触らない。存在しない場所は自動でスキップされる。
TARGETS="
$HOME/.claude/projects|$RETENTION_DAYS|*.jsonl
$HOME/.claude/todos|$RETENTION_DAYS|-
$HOME/.claude/tasks|$RETENTION_DAYS|-
$HOME/.claude/shell-snapshots|$SNAPSHOT_RETENTION_DAYS|-
$HOME/.claude/file-history|$RETENTION_DAYS|-
$HOME/.claude/backups|$RETENTION_DAYS|-
$HOME/.claude/statsig|$RETENTION_DAYS|-
$HOME/.cache/claude-cli-nodejs|$RETENTION_DAYS|-
$HOME/Library/Caches/claude-cli-nodejs|$RETENTION_DAYS|-
"

log "===== claude-cleanup 開始 (retention=${RETENTION_DAYS}d / snapshots=${SNAPSHOT_RETENTION_DAYS}d, dry_run=${DRY_RUN}) ====="

while IFS='|' read -r dir days filter; do
  [ -n "$dir" ] || continue
  clean_dir "$dir" "$days" "$filter"
done <<EOF
$TARGETS
EOF

# 一時領域の claude-*（Claude Code セッションの作業ディレクトリ）
for d in "$TMP_BASE"/claude-*; do
  [ -d "$d" ] && clean_dir "$d" "$RETENTION_DAYS" "-"
done

if [ "$DRY_RUN" = "1" ]; then
  log "===== ドライラン終了（何も削除していません） ====="
else
  log "===== 完了: 合計 ${files_deleted}件削除 / $(human_kb "$kb_freed")回収 ====="
fi

# ログ肥大化防止（直近400行のみ保持）
if [ -f "$LOG_FILE" ]; then
  tail -n 400 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

exit 0
