# カタログ

| X公開日 | ID | 名前 | 版 | 種別 | パス | 一言 |
|---|---|---|---|---|---|---|
| 2026-07-21 | find-skills-ja | Find Skills JA | v0.2 | エージェント型 | [skills/find-skills-ja](./skills/find-skills-ja/) | 日本語で聞くだけでスキルが見つかる |
| 未定 | company-deep-dive-report | 企業ディープダイブ・レポート | v0.1 | エージェント型 | [skills/company-deep-dive-report](./skills/company-deep-dive-report/) | 企業の儲け方と次に起きることを、根拠付きで分解する |
| 2026-07-25 | issue-structuring | 論点整理スキル | v0.1 | コピペ型 | [skills/issue-structuring](./skills/issue-structuring/) | AIに書く前に、決めることを切れ |
| 2026-08-08 | deliverable-review | 資料レビュー | v0.1 | コピペ型 | [skills/deliverable-review](./skills/deliverable-review/) | きれいでも、決められない資料は通さない |
| 2026-08-22 | research-to-insight | 調査から示唆 | v0.1 | コピペ型 | [skills/research-to-insight](./skills/research-to-insight/) | 調べた事実を、次の判断へつなぐ |

## 種別

| 種別 | 使い方 | 対象 |
|---|---|---|
| **コピペ型** | `SKILL.md` を開いてAIに貼り、案件メモを足す（Claude Code / Codex ではスキルとしても導入可） | Claude / ChatGPT / Gemini など何でも |
| **エージェント型** | `npx skills add Ted0321/kotetsu-work-ai-skills@<ID>` で導入。以後は自動で発火 | Claude Code / Cursor / Codex など SKILL.md 対応エージェント |

## 公開順
1. Find Skills JA
2. 企業ディープダイブ・レポート（公開日未定）
3. 論点整理
4. 資料レビュー
5. 調査から示唆
