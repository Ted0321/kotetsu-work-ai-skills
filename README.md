# kotetsu-work-ai-skills

**仕事が前に進むAIスキルを配るリポジトリ**（X: [@kotetsu_0321](https://x.com/kotetsu_0321)）

抽象的なAI論ではなく、資料・会議・方針決めの前に使える **型（スキル）** を置いています。  
共通コアはAgent Skills形式で作り、Claude Code / CodexではSkillとして、その他のAIではコピペで使えます。

---

## いちばん新しい / おすすめ

| スキル | 一言 | パス |
|---|---|---|
| **論点整理** `issue-structuring` | AIに書く前に、決めることを切る | [`skills/issue-structuring/`](./skills/issue-structuring/) |
| **資料レビュー** `deliverable-review` | きれいでも、決められない資料は通さない | [`skills/deliverable-review/`](./skills/deliverable-review/) |
| **調査から示唆** `research-to-insight` | 調べた事実を、次の判断へつなぐ | [`skills/research-to-insight/`](./skills/research-to-insight/) |
| **企業ディープダイブ** `company-deep-dive-report` | 企業の儲け方と次に起きることを、根拠付きで分解する | [`skills/company-deep-dive-report/`](./skills/company-deep-dive-report/) |

---

## 使い方（共通・3分）

1. 使いたいスキルの `SKILL.md` を開く  
2. 中身をAIに貼る（または skill として読ませる）  
3. 末尾に自分の案件メモを足す  

### Claude Code / Codexへインストール

| 対象 | 個人で使う | プロジェクトで共有する |
|---|---|---|
| Claude Code | `~/.claude/skills/<skill-name>/` | `.claude/skills/<skill-name>/` |
| Codex | `~/.agents/skills/<skill-name>/` | `.agents/skills/<skill-name>/` |

PowerShellの例:

```powershell
# Claude Code
Copy-Item -Recurse -Force .\skills\issue-structuring "$HOME\.claude\skills\issue-structuring"

# Codex
Copy-Item -Recurse -Force .\skills\issue-structuring "$HOME\.agents\skills\issue-structuring"
```

### 例（論点整理）

```text
（SKILL.md の本文）

# 案件メモ
来週の方針会議。先方はPoCと言っているが現場はデータ不足。経営はROI。整理して。
```

---

## 一覧

詳しくは [CATALOG.md](./CATALOG.md)

| ID | 名前 | 状態 |
|---|---|---|
| issue-structuring | 論点整理スキル | v0.1 |
| deliverable-review | 資料レビュー | v0.1 |
| research-to-insight | 調査から示唆 | v0.1 |
| company-deep-dive-report | 企業ディープダイブ・レポート | v0.1 |

Xでの紹介順と検証項目は [ROADMAP.md](./ROADMAP.md) にまとめています。

---

## 方針

- **薄いもの**は X で直接配布することもあります  
- **厚いもの**（複数ファイル・更新前提）をここに集約します  
- 完璧より、現場で使える v0.1 を先に出します  
- 思考の話は、使える型にして渡します  

---

## リポジトリ構成

```text
kotetsu-work-ai-skills/
├── README.md
├── CATALOG.md
├── ROADMAP.md
├── LICENSE
├── skills/
│   ├── issue-structuring/
│   ├── deliverable-review/
│   └── research-to-insight/
└── templates/          # 自分で薄配布を作るときの型
```

各Skillの実行コアは `SKILL.md` と `examples/` です。`agents/openai.yaml` はCodex向けの表示メタデータで、Claude Code側の実行条件にはしていません。

---

## ライセンス

MIT（自由に使ってください。商用利用可。クレジットは任意ですが嬉しいです）

---

## 作者

- X: [@kotetsu_0321](https://x.com/kotetsu_0321)
- GitHub: [Ted0321](https://github.com/Ted0321)

Issue / PR 歓迎です（日本語でOK）。

---

## 開発者向け（ローカル）

- 作業フォルダ: `C:\Users\ytets\kotetsu-work-ai-skills`
- 手順: [docs/LOCAL_DEV.md](./docs/LOCAL_DEV.md)
- 新規スキル: `bash scripts/new-skill.sh <id> [タイトル]`
