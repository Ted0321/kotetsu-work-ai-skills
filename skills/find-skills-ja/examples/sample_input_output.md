# 想定セッション例（find-skills-ja）

Claude Code に導入した状態での、理想的なやり取りの例。

---

## 入力（ユーザー）

```text
議事録つくるのに使えるスキルってある？
```

## エージェントの動き（内部）

1. 意図を特定: 会議メモ→議事録の整形
2. キーワード変換: `meeting minutes`（第1候補）/ `meeting notes`（第2候補）
3. 検索実行:
   ```bash
   npx skills find "meeting minutes"
   npx skills find "meeting notes"
   ```
4. 上位候補の SKILL.md 本文を取得し、指示内容と安全性を確認
5. 既存スキルとの重複を確認: `npx skills ls`

## 出力（エージェント→ユーザー）

```text
「meeting-minutes」スキルが見つかりました。

- 内容: 会議メモから決定事項・ToDo・宿題を構造化した議事録を生成
- 提供元: github/awesome-copilot（9.5K installs）
- 本文レビュー: 議事録テンプレートに沿った整形指示のみ。
  外部送信や危険なコマンド実行の指示はありません
- 詳細: https://skills.sh/github/awesome-copilot/meeting-minutes

このプロジェクトにインストールしますか？
（全プロジェクト共通にしたい場合はその旨教えてください）
```

---

## 悪い例（オリジナル find-skills で起きがちな動き）

```text
ユーザー: 議事録つくるのに使えるスキルってある？
エージェント: （`npx skills find 議事録` を実行）
エージェント: スキルが見つかりませんでした。
```

→ 日本語のまま検索して0件。実際にはスキルは存在している。
find-skills-ja はこの取りこぼしを防ぐ。
