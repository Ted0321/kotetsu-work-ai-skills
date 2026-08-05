# X投稿 完成稿 — Claude Code 週次おそうじ（改良版）

`templates/thin_drop_x_post.md` の型に沿った、そのまま貼れる完成稿。
◯GB の2箇所だけ、自分の環境の実測値（診断ワンライナーの出力）に差し替える。

## メイン投稿

添付画像: 1枚目 = 診断ワンライナーの実行結果（Before）、2枚目 = おそうじレポート（After）。
実スクショが撮れるまでは `assets/before-after-sample.png`（サンプル明記）で代用可。

```text
Claude Code、使うほどローカルにデータが溜まり続けてるの、知ってました？
会話ログ・シェルスナップショット・MCPログ…私の環境で◯GBありました。

海外でバズってた「codexに後片付けさせるプロンプト」を、Claude Code用に改良しました。

改良版がやること
・毎週の実行にAIを使わない（OSスケジューラに登録＝トークン0・確認なし）
・消す場所はパスで固定。AIの解釈に任せない
・30日より新しいものは機械的に保護
・実行前ドライラン＋Before/Afterレシート
・「止めて」の一言で解除

使い方
1. リプ2のワンライナーで自分の溜まり具合をチェック
2. リプ1のプロンプトをClaude Codeに貼る
3. 以後は毎週月曜9時に勝手に片付く

プロンプト全文はリプに🧵 保存して月曜の朝に。
```

## リプ1（本体プロンプト）

プレミアム（長文投稿）ならプロンプト全文をテキストで貼る（→ [PROMPT.md](./PROMPT.md) の「② 本体プロンプト」をコピー）。
**テキストで貼れない場合**は `assets/prompt-card.png`（プロンプト全文の画像版）を添付し、コピー用リンクを添える:

```text
本体プロンプトはこれ（画像）。
コピペ用テキストはここから↓
https://github.com/Ted0321/kotetsu-work-ai-skills/blob/main/skills/claude-cache-cleanup/PROMPT.md

貼るとまずドライラン（何がどれだけ消えるか）が表示されて、
問題なければ設置→週次登録→初回実行まで進みます。
```

## リプ2（診断ワンライナー）

```text
自分の「溜まり具合」はこれで見られます（消しはしない、見るだけ）

Mac / Linux / WSL:
cd ~ && du -shc .claude/projects .claude/todos .claude/tasks .claude/shell-snapshots .claude/file-history .claude/backups .claude/statsig .cache/claude-cli-nodejs Library/Caches/claude-cli-nodejs 2>/dev/null

Windows (PowerShell) は文字数の都合でここから↓
https://github.com/Ted0321/kotetsu-work-ai-skills/blob/main/skills/claude-cache-cleanup/PROMPT.md
```

## リプ3（安全設計＋導線）

```text
「AIに削除を任せて大丈夫？」への答えが今回の改良の本体です。

・消してよい場所を実パスで列挙（それ以外に触るコードが存在しない）
・「最近のものに触らない」は更新日時フィルタで機械的に保証
・ファイル単位の削除のみ（rm -rf 禁止）／保持7日未満は拒否
・素のClaude Codeにプロンプトだけ渡す再現テスト済み

検証済みスクリプト・画像素材ごとリポジトリに置いてます：
https://github.com/Ted0321/kotetsu-work-ai-skills/tree/main/skills/claude-cache-cleanup

スキルとして入れたい人は：
npx skills add Ted0321/kotetsu-work-ai-skills@claude-cache-cleanup
```

## 画像ALTテキスト案

- Before画像: 「診断コマンドの出力。Claude Codeの会話ログやスナップショットが合計◯GB溜まっている様子」
- After画像: 「おそうじレポート。before ◯GB → after ◯GB で◯GB回収、次回は毎週月曜9時に自動実行と表示」
- プロンプトカード: 「Claude Code週次おそうじの改良版プロンプト全文。消してよい場所のリストと安全ルール、5つの手順」

## 投稿前チェックリスト

- [ ] ◯GB を実測値に差し替えた（またはサンプル画像である旨を明記した）
- [ ] プロンプトが**テキストでコピーできる導線**がある（画像のみにしない）
- [ ] リポジトリのリンク先が main ブランチにマージ済みで、リンクが生きている
- [ ] 画像にALTテキストを付けた
