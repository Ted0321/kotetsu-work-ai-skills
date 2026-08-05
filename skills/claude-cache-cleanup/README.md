# Claude Code 週次おそうじ（claude-cache-cleanup）

**海外でバズった「codexに後片付けを任せる」Tipの、Claude Code 版。**

Claude Code は使うほどローカルにデータが溜まります（セッションログ、シェルスナップショット、編集履歴、MCPログ、一時ファイル）。
このスキルは、それを **「安全な範囲だけ・週1回・以後は確認なし」** で自動的に片付ける仕組みを、一言でセットアップします。

## 元ネタ

> codex ヒント: codex に後片付けを任せましょう。
> プロンプト: 「古い codex キャッシュ、スレッドログ、安全に削除できる一時ファイルをクリアする週次自動化を設定してください。アクティブなものや最近のものには触れないでください。（略）毎回私に聞かずに、毎週自動的に実行してください。」

これをそのまま Claude Code に貼っても動きはしますが、**何をどう消すかはその場のAI任せ**になります。
本スキルは「消してよい場所のリスト」「保持日数」「実行方式」まで設計済みです。

## codex 版との違い（ここが設計ポイント）

| | codex 版（元ネタ） | このスキル |
|---|---|---|
| 毎週の実行 | AIが毎回起動して判断 | **決定的スクリプト＋OS標準スケジューラ**（タスクスケジューラ / launchd / cron） |
| 毎週のコスト | トークン消費あり | **ゼロ**（AIは初回セットアップのみ） |
| 「確認なし」の実現 | AIの権限を緩める | そもそもAIを介さない（許可プロンプト自体が発生しない） |
| 消す範囲 | その場のAIの解釈 | **allowlist固定**＋保持日数フィルタ＋ファイル単位削除 |
| 事故防止 | プロンプトの言い方次第 | 設定・スキル・認証情報は構造的に対象外。保持7日未満は拒否。ドライラン必須 |

## 導入

```bash
npx skills add Ted0321/kotetsu-work-ai-skills@claude-cache-cleanup
```

導入後、Claude Code にこう言うだけです（元ネタの直訳でOK）：

```text
古くなった Claude Code のキャッシュ・セッションログ・一時ファイルを安全に掃除する週次自動化をセットアップして。
アクティブなものや最近のものには触らず、置きっぱなしで容量を食っている古いデータだけを対象に。
毎回私に聞かずに、毎週自動で実行して。
```

→ ①現状のドライラン表示 → ②保持日数と曜日・時刻だけ確認（この1回だけ） → ③スクリプト設置とスケジューラ登録 → ④初回実行と回収量の報告、まで自動で進みます。

## スキルを入れずに使う場合（コピペ用フルプロンプト）

スキル未導入の Claude Code（や他のエージェント）には、設計を全部埋め込んだこちらを貼ってください：

```text
Claude Code が溜め込んだ古いキャッシュ・セッションログ・一時ファイルを安全に掃除する「週次自動化」をセットアップして。

■ 方式
毎週の実行はAIではなく、決定的なクリーンアップスクリプト＋OS標準のスケジューラ
（Windows: タスクスケジューラ / macOS: launchd / Linux: cron）で行うこと。
あなたの仕事はスクリプト作成・ドライラン確認・スケジューラ登録の1回だけ。

■ 削除してよいもの（この場所の・保持日数より古いファイルだけ。ファイル単位で削除）
- ~/.claude/projects/ の *.jsonl（古いセッションログ。memory/ 等は残す）… 30日
- ~/.claude/todos/ と ~/.claude/tasks/ … 30日
- ~/.claude/shell-snapshots/ … 14日
- ~/.claude/file-history/ … 30日
- ~/.claude/backups/ … 30日
- ~/.claude/statsig/ … 30日
- MCPログのキャッシュ（~/.cache/claude-cli-nodejs または ~/Library/Caches/claude-cli-nodejs
  または %LOCALAPPDATA%\claude-cli-nodejs）… 30日
- 一時フォルダ（$TMPDIR・/tmp・%TEMP%）直下の claude-* … 30日
存在しない場所はスキップ。

■ 絶対に触らないもの
settings.json / settings.local.json / CLAUDE.md / keybindings.json / .credentials.json / ~/.claude.json、
agents・skills・commands・hooks・plugins・rules・workflows・agent-memory・output-styles・themes、
projects/ 配下の memory/、および保持日数以内のファイルすべて。
ディレクトリ丸ごとの rm -rf は禁止（空になったサブフォルダの削除のみ可）。
保持日数を7日未満にすることも禁止。

■ 手順
1. まずドライランで「どこの・何件・何MBが消えるか」を表で見せる
2. スクリプトを ~/.claude/cleanup/ に設置（DRY_RUN対応・実行ログを cleanup.log に残す）
3. OSに合わせて毎週月曜9時に登録（既存登録があれば置き換え。二重登録しない）
4. ~/.claude/settings.json に "cleanupPeriodDays": 30 もマージ（他のキーは保持）
5. 初回を1回実行し、回収量・次回実行日時・止め方を報告

以後は毎回私に聞かず、毎週自動で実行して。
```

## 何が消えて、何が残るか

| | 例 | 扱い |
|---|---|---|
| 消える | 30日以上前のセッションログ、14日以上前のシェルスナップショット、古いMCPログ・編集履歴・一時ファイル | 週1で自動削除 |
| 残る | 直近30日のすべて、settings.json、CLAUDE.md、skills / agents / commands / plugins、認証情報、プロジェクトの自動メモリ | 何があっても触らない |

同梱スクリプト（[scripts/claude-cleanup.sh](./scripts/claude-cleanup.sh) / [scripts/claude-cleanup.ps1](./scripts/claude-cleanup.ps1)）は allowlist 方式で、表に無い場所を触るコードがそもそも存在しません。

## FAQ

**Q. Claude Code には `cleanupPeriodDays`（既定30日）があるのに、なぜ要るの？**
組み込みの掃除は Claude Code の**起動時**に走り、対象も限定的です。ターミナルを開きっぱなしの人、MCPログ・一時フォルダ・古い編集履歴まで含めて片付けたい人向けに、本スキルはOSスケジューラで確実に週1回実行し、回収量のログも残します（`cleanupPeriodDays` の設定もセットアップ時に揃えます）。

**Q. 本当に安全？**
「新しいものに触らない」をAIの注意力ではなく**更新日時フィルタ**で保証し、「消してよい場所」を**allowlist**で固定しています。さらに保持7日未満の設定は拒否、設置前ドライラン必須、実行ログ付き。bash版はテストハーネスで削除対象・保護対象・非破壊ドライランを検証済みです。

**Q. 止めたいときは？**
Claude Code に「おそうじ自動化を止めて」と言えば、スケジューラ登録を解除してくれます（手動なら Windows: `Unregister-ScheduledTask -TaskName ClaudeCodeCleanup`、macOS: `launchctl unload -w ~/Library/LaunchAgents/com.claude-code.cleanup.plist`、Linux: `crontab -e` で該当行を削除）。

**Q. 会社PCと自宅PCの両方で使いたい**
データはマシンごとに溜まるので、各マシンで一度ずつセットアップしてください。

## 注意

- エージェント型スキルです（スクリプト設置とスケジューラ登録を行うため、ChatGPT等へのコピペ利用は上記フルプロンプトを使ってください）
- ユーザーの**ローカルマシンの Claude Code** で実行してください（クラウド版セッション内で実行しても意味がありません）
- 削除されたデータは復元できません。保持日数は自分の使い方に合わせて（過去の会話を `claude --resume` でよく掘り返す人は60〜90日推奨）

## クレジット

海外で共有されていた codex の週次クリーンアップTipを、Claude Code のデータ配置・権限モデルに合わせて再設計したものです。

想定セッション例: [examples/sample_input_output.md](./examples/sample_input_output.md)
