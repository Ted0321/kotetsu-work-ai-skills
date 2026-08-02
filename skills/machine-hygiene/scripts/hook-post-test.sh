#!/usr/bin/env bash
# machine-hygiene / hook-post-test.sh
#
# Claude Code の PostToolUse フック用。標準入力でフックJSONを受け取り、
# 「いま実行されたBashコマンドがテストだったか」を判定して、
# テストだったときだけ残ったヘッドレスブラウザを終了する。
#
# キャッシュはここでは消さない（coverage / test-results を直後に読みたいことがあるため）。
# キャッシュ削除は SessionEnd フック側で行う。
#
# 終了コードは常に 0。フックがClaude Codeの動作を止めないようにする。
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
case "$SELF" in */*) DIR="${SELF%/*}" ;; *) DIR="." ;; esac
DIR="$(cd "$DIR" 2>/dev/null && pwd -P)" || DIR="."
PAYLOAD="$(cat)"

# ---- フックJSONから command と cwd を取り出す --------------------------------
extract() { # $1 = jqパス, $2 = pythonパス
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$PAYLOAD" | jq -r "$1 // empty" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$PAYLOAD" | python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
cur = d
for k in '$2'.split('.'):
    if not isinstance(cur, dict):
        sys.exit(0)
    cur = cur.get(k)
print(cur if isinstance(cur, str) else '')
" 2>/dev/null
  fi
}

CMD="$(extract '.tool_input.command' 'tool_input.command')"
CWD="$(extract '.cwd' 'cwd')"
[ -n "$CWD" ] || CWD="$PWD"

# jq も python3 も無い環境では、payload全体をコマンド文字列とみなして判定する
[ -n "$CMD" ] || CMD="$PAYLOAD"

# ---- テストコマンドかどうか --------------------------------------------------
TEST_RE='(npm|pnpm|yarn|bun|npx)[[:space:]]+([a-z:-]+[[:space:]]+)*(test|e2e)|vitest|jest|playwright[[:space:]]+test|cypress[[:space:]]+run|pytest|go[[:space:]]+test|cargo[[:space:]]+test|mvn[[:space:]]+test|gradle[[:space:]]+test|rspec|phpunit'
printf '%s' "$CMD" | grep -Eqi "$TEST_RE" || exit 0

# ---- 残骸の掃除（プロセスのみ） ----------------------------------------------
bash "$DIR/sweep.sh" --apply --quiet --no-caches --root "$CWD"
exit 0
