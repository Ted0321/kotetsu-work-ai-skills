---
name: claude-cache-cleanup
description: "Set up a safe weekly cleanup automation for Claude Code's accumulated local data: old session transcripts, shell snapshots, file history, todo/task files, MCP logs, and temp files. Installs a deterministic allowlist-based cleanup script and registers it with the OS scheduler (Windows Task Scheduler / macOS launchd / Linux cron) so it runs weekly with zero tokens and zero permission prompts. Use when the user says 「Claude Codeの掃除」「古いキャッシュ・ログを消したい」「ディスク容量を空けたい」「クリーンアップを自動化して」「週次で掃除して」「.claudeが肥大化してる」 or asks to automate cleanup of Claude Code caches, session logs, or temp files."
---

# Claude Code 週次おそうじ自動化

## 目的

Claude Code は使うほどローカルにデータが溜まる（セッションログ、シェルスナップショット、編集履歴、MCPログ、一時ファイル）。
これを「安全な範囲だけ・週1回・以後は確認なし」で自動的に片付ける仕組みを、その場でセットアップする。

## 設計思想（なぜ毎週AIを起動しないのか）

Claude Code には常駐スケジューラがなく、ファイル削除を毎週AIの判断でやるのは遅い・高い・非決定的で、無人実行には権限バイパスも必要になる。だから分担する：

- **AIの仕事は1回だけ**: 診断 → 方針確認 → スクリプト設置 → スケジューラ登録
- **毎週の実行は決定的スクリプト＋OS標準スケジューラ**: トークン0・許可プロンプト0・毎回同じ動き

## 前提

- ユーザーの**ローカルマシン上の Claude Code** で実行されること。リモート／クラウドセッション（Claude Code on the web 等）で呼ばれた場合は、掃除対象が使い捨てコンテナ内にしか無いことを伝え、ローカルでの実行を案内する。
- 削除したデータは復元できない。だからこそ下の安全原則を厳守する。

## 原則（安全設計・交渉不可）

1. **Allowlist方式**: 下の表に列挙した場所以外は絶対に触らない。`~/.claude` 全体を走査・削除するコマンドは書かない。
2. **更新日時フィルタ**: 保持日数（既定30日）より新しいファイルは対象外。「アクティブ・直近のものに触らない」はこの仕組みで構造的に保証する。
3. **ファイル単位で削除**: ディレクトリ丸ごとの `rm -rf` は禁止。削除後に空になったサブフォルダのみ削除可。
4. **設定・資産は不可侵**: `settings.json` / `settings.local.json` / `CLAUDE.md` / `keybindings.json` / `.credentials.json` / `~/.claude.json`、および `agents` `skills` `commands` `hooks` `plugins` `rules` `workflows` `agent-memory` `output-styles` `themes` の各フォルダは理由を問わず対象外。`projects/` 配下の `memory/`（自動メモリ）も消さない（**projects/ は `*.jsonl` のみ対象**とすることで守る）。
5. **保持日数の下限は7日**: ユーザーが7日未満を希望しても受けない（スクリプト側にも同じ安全装置がある）。
6. **設置前に必ずドライラン**を見せ、本削除はその後に行う。

## 掃除対象（allowlist）

| 場所 | 中身 | 既定の保持 |
|---|---|---|
| `~/.claude/projects/` の `*.jsonl` | セッションログ（会話履歴） | 30日 |
| `~/.claude/todos/`・`~/.claude/tasks/` | 過去セッションのToDo/タスク状態 | 30日 |
| `~/.claude/shell-snapshots/` | シェルスナップショット | 14日 |
| `~/.claude/file-history/` | 編集履歴（rewind用バックアップ） | 30日 |
| `~/.claude/backups/` | `~/.claude.json` の移行バックアップ | 30日 |
| `~/.claude/statsig/` | フィーチャーフラグのキャッシュ | 30日 |
| `~/.cache/claude-cli-nodejs/`（macOS: `~/Library/Caches/claude-cli-nodejs/`、Win: `%LOCALAPPDATA%\claude-cli-nodejs\`） | MCPログ・CLIキャッシュ | 30日 |
| 一時領域の `claude-*`（`$TMPDIR`・`/tmp`・`%TEMP%`） | セッションの作業ファイル | 30日 |

存在しない場所はスキップする（Claude Code のバージョンで有無が異なる）。

## 手順

### Step 1: スクリプト設置

このスキルの `scripts/` にある実装済みスクリプトを使う（新規に書き起こさない）。

- macOS / Linux / WSL: `scripts/claude-cleanup.sh` → `~/.claude/cleanup/claude-cleanup.sh` へコピーし `chmod +x`
- Windows: `scripts/claude-cleanup.ps1` → `%USERPROFILE%\.claude\cleanup\claude-cleanup.ps1` へコピー（**UTF-8 BOM付きのまま**コピーする。PowerShell 5.1 の文字化け対策）

スキルのファイルにアクセスできない場合のみ、上の対象表と原則を完全に満たす同等スクリプトを生成する（allowlist・日数フィルタ・ファイル単位削除・7日下限・DRY_RUN対応・`~/.claude/cleanup/cleanup.log` へのログ・ログの400行ローテーションを必ず実装）。

### Step 2: ドライランで現状診断

```bash
DRY_RUN=1 bash ~/.claude/cleanup/claude-cleanup.sh
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\.claude\cleanup\claude-cleanup.ps1" -DryRun
```

出力を「場所 / 件数 / サイズ」の表に整えて見せ、合計何MBが対象かを伝える。

### Step 3: 方針確認（この1回だけ質問してよい）

AskUserQuestion で次の2点だけ確認する。ユーザーが依頼時にすでに指定していたら聞かずに進む。**設置後は二度と確認しない。**

1. 保持日数: 30日（推奨・既定）/ 60日 / 90日
2. 実行タイミング: 毎週月曜 9:00（既定）/ 任意の曜日・時刻

保持日数を変える場合はスクリプト呼び出しに環境変数/引数で渡す（スクリプト本体は書き換えない）。
例: `RETENTION_DAYS=60 bash ...` / `-RetentionDays 60`

### Step 4: スケジューラ登録（OS別）

既存の同名登録があれば置き換える（二重登録しない）。

**Windows（タスクスケジューラ・管理者権限不要）**

```powershell
$script = Join-Path $HOME '.claude\cleanup\claude-cleanup.ps1'
Register-ScheduledTask -TaskName 'ClaudeCodeCleanup' -Force `
  -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 09:00) `
  -Action (New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $script)) `
  -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable)
```

`-StartWhenAvailable` により、時刻にPCが起動していなくても次回起動時に実行される。
確認: `Get-ScheduledTask -TaskName ClaudeCodeCleanup`

**macOS（launchd）** — `~/Library/LaunchAgents/com.claude-code.cleanup.plist` を作成（`$HOME` は実パスに展開して書く）:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.claude-code.cleanup</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string>
    <string>/Users/USERNAME/.claude/cleanup/claude-cleanup.sh</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Weekday</key><integer>1</integer>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
</dict></plist>
```

```bash
launchctl unload ~/Library/LaunchAgents/com.claude-code.cleanup.plist 2>/dev/null
launchctl load -w ~/Library/LaunchAgents/com.claude-code.cleanup.plist
launchctl list | grep com.claude-code.cleanup   # 確認
```

スリープ中に時刻を過ぎた回は、復帰時に実行される（cronより確実）。

**Linux（cron）**

```bash
( crontab -l 2>/dev/null | grep -vF 'claude-cleanup.sh' ; \
  echo '0 9 * * 1 /bin/bash $HOME/.claude/cleanup/claude-cleanup.sh' ) | crontab -
crontab -l   # 確認
```

常時起動でないPCなら systemd user timer（`Persistent=true`）を代わりに提案してよい。

**WSL** — WSL内のcronは動いていないことが多い。Windows側のタスクスケジューラに `wsl.exe -e bash -lc '~/.claude/cleanup/claude-cleanup.sh'` を登録するのが確実。

### Step 5: Claude Code 本体の保持設定を揃える

`~/.claude/settings.json` に `"cleanupPeriodDays": <保持日数>` をマージする（Claude Code 組み込みの保持設定。起動時にセッションログ等を同じ基準で掃除してくれる。既定30日）。

- 既存のJSONを読み、**他のキーを保持したまま**この1キーだけ追加/更新して書き戻す
- ファイルが無ければ `{"cleanupPeriodDays": 30}` で新規作成
- JSONが壊れていたら**触らずに**その旨を報告する

### Step 6: 初回実行と報告

本実行を1回行い、`cleanup.log` とドライラン時の数字から Before/After を計算して報告する。フォーマット（スクリーンショット映えを意識して崩さない）:

```text
━━━ Claude Code おそうじレポート ━━━
 before : X.X GB（X,XXX ファイル）
 after  : X.X GB → ★X.X GB 回収★
 内訳   : 会話ログ X.X GB / スナップショット X.X GB / MCPログ X.X GB / その他 X.X GB
 次回   : 毎週月曜 9:00 に自動実行（もう確認しません）
 停止   : 「おそうじ自動化を止めて」と言えば解除
━━━━━━━━━━━━━━━━━━━━━━
```

## 設置後の運用（ユーザーがこう言ったら）

| 依頼 | やること |
|---|---|
| 「掃除の結果見せて」 | `cleanup.log` の末尾を読んで直近の実行結果を要約 |
| 「今すぐ掃除して」 | スクリプトを手動実行して結果を報告 |
| 「止めて」「一時停止して」 | スケジューラ登録だけ解除（スクリプトとログは残す）。Windows: `Unregister-ScheduledTask -TaskName ClaudeCodeCleanup -Confirm:$false` / macOS: `launchctl unload -w ...` / Linux: crontab から該当行を除去 |
| 「全部元に戻して」 | 登録解除 + `~/.claude/cleanup/` を削除 + `settings.json` から `cleanupPeriodDays` を除去。削除済みデータは戻せないことを伝える |

## 品質チェック（完了報告の前に）

- [ ] ドライランを見せてから本削除したか
- [ ] スケジューラの登録を実際に確認したか（`Get-ScheduledTask` / `launchctl list` / `crontab -l`）
- [ ] 二重登録になっていないか
- [ ] `settings.json` が書き戻し後も有効なJSONか再パースして確認したか
- [ ] 報告に「止め方」を含めたか
