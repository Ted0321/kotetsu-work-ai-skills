# Find Skills JA（find-skills-ja）

**スキルを探すスキル、日本語ユーザー向け改良版。**

Claude Code などで「議事録のスキルある？」と日本語で聞くだけで、
合うスキルを探し、安全確認までしてから提案してくれるようになります。

## なぜ改良版が必要か（実測データ）

skills.sh で累計260万インストールの人気1位スキル `find-skills`（vercel-labs）。
ただし検索エンジンの仕様上、**日本語では何もヒットしません**（2026-07-21 実測）。

| クエリ | 結果 |
| --- | --- |
| 「議事録」 | 0件 |
| 「テスト」 | 0件 |
| 「リファクタリング」 | 0件 |
| "how to write meeting notes"（英語の文章） | 0件 |
| "meeting minutes"（英語キーワード） | ヒット（9.5K installs） |
| "testing"（英語キーワード） | ヒット（118K installs） |

効くのは「短い英語の名詞キーワード」だけ。
そこで本スキルは、検索前に **日本語→英語キーワード変換** を必ず行います。

## オリジナルとの違い

| | オリジナル find-skills | find-skills-ja |
| --- | --- | --- |
| 日本語での依頼 | 検索が0件になりがち | 英語キーワードへ自動変換（対訳表つき） |
| インストール前の確認 | 人気シグナル（DL数・スター） | ＋SKILL.md本文を読んで危険な指示がないか確認 |
| 水増し対策 | なし | 一括インストールによるDL数水増しを検知 |
| インストール既定 | グローバル＋無確認（`-g -y`） | プロジェクトスコープ＋ユーザー確認 |

## 導入

```bash
npx skills add Ted0321/kotetsu-work-ai-skills@find-skills-ja
```

導入後は Claude Code に日本語でこう聞くだけです：

```text
議事録つくるのに使えるスキルってある？
```

→ `meeting minutes` / `meeting notes` で検索 → 品質・安全確認 → 日本語で提案、まで自動で行われます。

想定セッション例: [examples/sample_input_output.md](./examples/sample_input_output.md)

## 注意

- 本スキルは検索に `npx skills find`（[skills CLI](https://github.com/vercel-labs/skills)）を使います
- エージェント型スキルです。ChatGPT等へのコピペ利用は想定していません（Claude Code / Cursor / Codex など SKILL.md 対応エージェント向け）

## クレジット

[vercel-labs/skills](https://github.com/vercel-labs/skills) の `find-skills`（MIT License）を参考に、
日本語ユーザー向けに再設計したものです。

検証データ・改良の経緯: X [@kotetsu_0321](https://x.com/kotetsu_0321)
