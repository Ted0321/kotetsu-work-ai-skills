# コピペ用プロンプト — Claude Code 週次おそうじ（改良版）

Claude Code に下のプロンプトを貼るだけで、「古いデータだけを・毎週・確認なしで」片付ける仕組みが組み上がります。
スキルのインストールは不要です。素の Claude Code で再現できることを、隔離環境での実地テストで確認済みです。

## 使い方（3ステップ）

1. **診断**（任意・スクショ推奨）: 下の「溜まり具合チェック」を実行して Before を撮る
2. **本体プロンプトを貼る**: ドライラン表示 → 設置 → スケジューラ登録 → 初回実行まで自動で進む
3. 最後に出る**おそうじレポートを撮る** → Before/After の完成

---

## ① 溜まり具合チェック（診断ワンライナー）

**macOS / Linux / WSL:**

```bash
cd ~ && du -shc .claude/projects .claude/todos .claude/tasks .claude/shell-snapshots .claude/file-history .claude/backups .claude/statsig .cache/claude-cli-nodejs Library/Caches/claude-cli-nodejs 2>/dev/null
```

**Windows (PowerShell):**

```powershell
$t=0; foreach($n in 'projects','todos','tasks','shell-snapshots','file-history','backups','statsig'){ $d=Join-Path $HOME ".claude\$n"; if(Test-Path $d){ $s=[math]::Round(((Get-ChildItem $d -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum)/1MB,1); $t+=$s; "{0,10:N1} MB  {1}" -f $s,$n } }; $d=Join-Path $env:LOCALAPPDATA 'claude-cli-nodejs'; if(Test-Path $d){ $s=[math]::Round(((Get-ChildItem $d -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum)/1MB,1); $t+=$s; "{0,10:N1} MB  mcp-logs" -f $s }; "{0,10:N1} MB  合計" -f $t
```

コマンドが面倒なら、Claude Code に「Claude Code が溜め込んでいるデータ量を場所別に表で見せて」と聞くだけでもOKです。

---

## ② 本体プロンプト（これを Claude Code に貼る）

```text
Claude Code が溜め込んだ古いキャッシュ・会話ログ・一時ファイルを安全に片付ける「週次おそうじ」をセットアップして。以下を厳守すること。

【方式】
毎週の実行にAIを使わないこと。決定的なクリーンアップスクリプトを作成し、OS標準のスケジューラに毎週月曜9:00で登録する（Windows: タスクスケジューラ / macOS: launchd / Linux: cron。WSLはWindows側から wsl.exe 経由で登録）。あなたの仕事は今回の設置1回だけ。以後は確認なし・トークン消費ゼロで毎週動く。

【消してよいもの】次の場所の「30日より古いファイル」だけ（★印は14日）
・~/.claude/projects/ 内の *.jsonl（過去の会話ログ。memory/ など jsonl 以外は残す）
・~/.claude/ 内の todos/ tasks/ file-history/ backups/ statsig/
・~/.claude/shell-snapshots/ ★
・MCPログ: ~/.cache/claude-cli-nodejs（macOSは ~/Library/Caches/claude-cli-nodejs、Windowsは %LOCALAPPDATA%\claude-cli-nodejs）
・OSの一時フォルダ直下の claude-*
存在しない場所はスキップ。削除は必ずファイル単位で行い、フォルダごとの rm -rf は禁止（空になったサブフォルダの削除のみ可）。

【絶対に触らないもの】
settings.json / settings.local.json / CLAUDE.md / keybindings.json / .credentials.json / ~/.claude.json、agents・skills・commands・hooks・plugins・rules などの資産フォルダ、そして保持日数以内のファイル全部。スクリプトには「保持日数が7日未満なら実行を拒否する」安全装置を入れること。

【手順】
1. まずドライラン: 何も消さずに、削除対象を「場所/件数/サイズ」の表で見せる
2. スクリプトを ~/.claude/cleanup/ に設置（ドライラン用フラグ付き。実行のたび cleanup.log に記録を残す）
3. スケジューラへ登録（既存の同名登録は置き換えて二重登録を防ぐ）。登録結果を表示して確認
4. ~/.claude/settings.json に "cleanupPeriodDays": 30 を追記マージ（他のキーは保持。JSONが壊れていたら触らず報告）
5. 初回のおそうじを実行し、最後に必ずこの形式で報告:

━━━ Claude Code おそうじレポート ━━━
 before : X.X GB（X,XXX ファイル）
 after  : X.X GB → ★X.X GB 回収★
 内訳   : 会話ログ X.X GB / スナップショット X.X GB / MCPログ X.X GB / その他 X.X GB
 次回   : 毎週月曜 9:00 に自動実行（もう確認しません）
 停止   : 「おそうじ自動化を止めて」と言えば解除
━━━━━━━━━━━━━━━━━━━━━━
```

---

## カスタマイズ

| 変えたいこと | プロンプトのどこを変える |
|---|---|
| 保持期間を長く（会話ログをよく掘り返す人） | 「30日」を 60日 / 90日 に（7日未満は不可） |
| 実行タイミング | 「毎週月曜9:00」を好きな曜日・時刻に |
| 掃除をやめる | 設定後に「おそうじ自動化を止めて」と言うだけ |

## 注意

- 対象は**あなたのローカルマシン**の Claude Code です（クラウド版のセッション内で実行しても意味がありません）
- 削除したデータは復元できません。初回のドライラン表示で内容を確認してから進んでください
- 会話ログを消すと `claude --resume` でその会話に戻れなくなります（30日より古いものだけ）
