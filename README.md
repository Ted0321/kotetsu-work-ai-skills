# kotetsu-work-ai-skills

**仕事が前に進むAIスキルを配るリポジトリ**（X: [@kotetsu_0321](https://x.com/kotetsu_0321)）

抽象的なAI論ではなく、資料・会議・方針決めの前に使える **型（スキル）** を置いています。  
共通コアはAgent Skills形式で作り、Claude Code / CodexではSkillとして、その他のAIではコピペで使えます。

| 種別 | 使い方 | 対象 |
|---|---|---|
| **コピペ型** | `SKILL.md` をAIに貼って使う | Claude / ChatGPT / Gemini など何でも |
| **エージェント型** | コマンド1行で導入、以後は自動で発火 | Claude Code / Cursor / Codex など |

---

## いちばん新しい / おすすめ

| スキル | 種別 | 一言 | パス |
|---|---|---|---|
| **Find Skills JA** `find-skills-ja` | エージェント型 | 日本語で聞くだけでスキルが見つかる | [`skills/find-skills-ja/`](./skills/find-skills-ja/) |
| **論点整理** `issue-structuring` | コピペ型 | AIに書く前に、決めることを切る | [`skills/issue-structuring/`](./skills/issue-structuring/) |
| **資料レビュー** `deliverable-review` | コピペ型 | きれいでも、決められない資料は通さない | [`skills/deliverable-review/`](./skills/deliverable-review/) |
| **調査から示唆** `research-to-insight` | コピペ型 | 調べた事実を、次の判断へつなぐ | [`skills/research-to-insight/`](./skills/research-to-insight/) |

---

## 使い方

### コピペ型（3分）

1. 使いたいスキルの `SKILL.md` を開く  
2. 中身をAIに貼る（または skill として読ませる）  
3. 末尾に自分の案件メモを足す  

```text
（SKILL.md の本文）

# 案件メモ
来週の方針会議。先方はPoCと言っているが現場はデータ不足。経営はROI。整理して。
```

### エージェント型（1行）

```bash
# 例: Find Skills JA を導入
npx skills add Ted0321/kotetsu-work-ai-skills@find-skills-ja
```

導入後は Claude Code などに日本語で話しかけるだけで自動発火します。  
コピペ型のスキルも同じコマンドでスキルとして導入できます（`@issue-structuring` など）。

### 手動でClaude Code / Codexへ入れる場合

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

---

## 一覧

詳しくは [CATALOG.md](./CATALOG.md)

| ID | 名前 | 種別 | 状態 |
|---|---|---|---|
| find-skills-ja | Find Skills JA | エージェント型 | v0.1 |
| issue-structuring | 論点整理スキル | コピペ型 | v0.1 |
| deliverable-review | 資料レビュー | コピペ型 | v0.1 |
| research-to-insight | 調査から示唆 | コピペ型 | v0.1 |

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
│   ├── find-skills-ja/       # エージェント型
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
