# ローカル開発ガイド

このリポジトリの **公開正本** は GitHub です。  
ローカルでは同じ内容を編集し、`git push` / `git pull` で同期します。

## ローカル場所

| パス | 説明 |
|---|---|
| `C:\Users\ytets\kotetsu-work-ai-skills` | **推奨の作業パス**（ジャンクション） |
| `C:\Users\ytets\work-ai-skills` | 実体フォルダ（同じ中身） |
| リモート | https://github.com/Ted0321/kotetsu-work-ai-skills |

X運用リポジトリ `x_twitter` とは **別** です。  
戦略・投稿下書きは `x_twitter`、公開スキル本体は **ここ**。

---

## 初回セットアップ（別PCのとき）

```bash
gh auth login
gh repo clone Ted0321/kotetsu-work-ai-skills
cd kotetsu-work-ai-skills
```

または:

```bash
git clone https://github.com/Ted0321/kotetsu-work-ai-skills.git
cd kotetsu-work-ai-skills
```

---

## 日常の流れ

### 最新を取る（pull）

```bash
cd C:\Users\ytets\kotetsu-work-ai-skills
git pull origin main
```

### スキルを追加・更新して上げる（push）

```bash
cd C:\Users\ytets\kotetsu-work-ai-skills

# 1) 編集（または scripts で骨格作成）
# 2) 確認
git status
git diff

# 3) コミット
git add .
git commit -m "Add skill: yyy"

# 4) 公開
git push origin main
```

### 新しいスキルの骨格を作る

```bash
# Git Bash
bash scripts/new-skill.sh deliverable-review "資料レビュー"

# または PowerShell
powershell -File scripts/new-skill.ps1 -Id deliverable-review -Title "資料レビュー"
```

作成後:
1. `skills/<id>/SKILL.md` を書く  
2. `examples/` に例を足す  
3. `CATALOG.md` に1行追加（スクリプトが仮追記する場合あり）  
4. push  

---

## フォルダ構成（運用ルール）

```text
kotetsu-work-ai-skills/
├── README.md                 # 公開トップ
├── CATALOG.md                # 一覧（公開）
├── LICENSE
├── docs/
│   └── LOCAL_DEV.md          # 今ここ
├── scripts/
│   ├── new-skill.sh
│   └── new-skill.ps1
├── skills/
│   ├── _template/            # コピー元（公開しなくてよいがgit管理する）
│   └── issue-structuring/    # 各スキル
│       ├── README.md
│       ├── SKILL.md          # 本体（必須）
│       └── examples/
└── templates/                # X薄配布などの型
```

### 入れてよいもの
- スキル本体・例・公開README
- 汎用テンプレ

### 入れないもの
- APIキー、`.env`
- クライアント実名データ
- `x_twitter` の戦略・競合分析・未公開下書き

---

## x_twitter との役割分担

| 置き場 | 役割 |
|---|---|
| `kotetsu-work-ai-skills` | **公開スキルの正本**（GitHub同期） |
| `x_twitter/library/skills_hub` | 仕様メモ・X投稿パッケージ連携用の作業コピー |
| `x_twitter/posts` | 配布告知の投稿本文 |

公開する変更は、必ず **kotetsu-work-ai-skills で commit & push**。  
その後、必要なら `x_twitter` 側のリンクや投稿を更新。

---

## トラブル

### push が拒否される
```bash
git pull --rebase origin main
git push origin main
```

### 認証エラー
```bash
gh auth status
gh auth login
```

### どのフォルダが正か分からない
Explorer で `C:\Users\ytets\kotetsu-work-ai-skills` を開けばOK。  
中身は `work-ai-skills` と同じです。
