# 使用例

## 入力

```text
PCが重い。E2Eを何回か回したあとから、ファンが止まらない。
```

## 1. スキルが監査を実行

```bash
bash scripts/audit.sh
```

```markdown
# マシン監査 — 2026-08-02 23:14

対象プロジェクト: `/Users/you/work/app`

## 1. テストの残骸

| 項目 | 値 |
|---|---|
| 残っているヘッドレスブラウザ | 11件 |
| そのメモリ合計 | 4.2GB |
| 最も古い残骸の経過時間 | 214分 |
| 15分以上生きているテストランナー | 2件 |

## 2. いま重いプロセス（上位5）
（略）

## 3. 消していいキャッシュ（プロジェクト内）

| パス | サイズ |
|---|---|
| `node_modules/.cache` | 890MB |
| `test-results` | 1.2GB |
| `playwright-report` | 310MB |

**合計: 2.4GB**

## 4. 一時フォルダに残った自動化プロファイル

`/var/folders/.../T` に 37件 / 1.8GB
```

## 2. スキルの出力（ユーザーに見せるもの）

```markdown
## いま何が起きているか
ヘッドレスブラウザが11件、メモリ4.2GBを占有したままです。
一番古いものは3時間半前のテストの残骸。キャッシュは2.4GB、一時フォルダに1.8GB。

## 原因
Playwrightのテストが途中で落ちたとき、ブラウザが親プロセスと一緒に終了していません。
回すたびに1〜2件ずつ積み上がっています。

## 今日やること
フックを入れてください。掃除を毎回頼むより、テスト後に自動で終わる方が確実です。
（先に一度だけ手動掃除で4.2GBを取り戻します）

## 提案
- 15分以上生きているテストランナーが2件。テストコマンドにtimeoutを付ける
- 一時フォルダが1.8GB。週1で `sweep --apply --deep` を回す
```

## 3. 承認を取ってから実行

```bash
# 先に dry-run を見せる
bash scripts/sweep.sh
# → [dry-run] 終了対象のヘッドレス残骸: 11件（メモリ約 4.2GB） pid: 4468 4471 ...
# → [dry-run] 削除対象: node_modules/.cache（890MB）
# → ...

# ユーザーが「OK」と言ってから
bash scripts/sweep.sh --apply
# → ヘッドレス残骸を終了: 11件（メモリ約 4.2GB 解放）
# → キャッシュ／残骸を削除: 14箇所（2.4GB 解放）
```

## 4. フックを入れる（ここが本題）

`~/.claude/settings.json` に `assets/settings.hooks.macos-linux.json` の `hooks` をマージ。

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/skills/machine-hygiene/scripts/hook-post-test.sh\"", "timeout": 30 }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/skills/machine-hygiene/scripts/sweep.sh\" --apply --quiet --root \"$CLAUDE_PROJECT_DIR\"", "timeout": 60 }
        ]
      }
    ]
  }
}
```

以後、Claude Codeが `npx playwright test` を実行するたびに、
フックがそのコマンドを見て「テストだった」と判定し、残ったブラウザだけを終了する。
セッション終了時にキャッシュも消える。**AIは1回も呼ばれない＝トークンは増えない。**

## 触られないもの（確認済み）

| プロセス | 結果 |
|---|---|
| `chrome --headless --remote-debugging-port=9222` | 終了する |
| `chrome --remote-debugging-port=9333 --user-data-dir=~/.config/google-chrome/Default` | **終了しない**（普段使いのプロファイル） |
| `node_modules/.bin/vite dev --port 5173` | **終了しない**（dev server） |
| `src/keepme/app.py` | **消えない**（ソース） |
