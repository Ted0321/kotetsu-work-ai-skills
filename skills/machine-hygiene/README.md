# machine-hygiene — テストの後始末を自動化する

E2Eテストのたびに増えるヘッドレスブラウザとキャッシュを、**Claude Codeのフックで自動的に片付ける**スキル。
掃除そのものはシェルスクリプトなので、導入後の**トークンコストはゼロ**。

> 元ネタ: 「テスト後にヘッドレスを全部終了 / キャッシュをクリア / マシンを監査」。
> これをClaude Codeでやるなら、スキル（判断）＋フック（実行）に分けるのが素直。

## クイックスタート

```bash
# 1. 導入
npx skills add Ted0321/kotetsu-work-ai-skills@machine-hygiene

# 2. まず監査（読み取り専用・何も壊さない）
bash scripts/audit.sh          # Windows: powershell -NoProfile -File scripts\audit.ps1

# 3. 掃除（既定はdry-run。--apply で実行）
bash scripts/sweep.sh
bash scripts/sweep.sh --apply

# 4. 自動化（assets/ のフック定義を settings.json にマージ）
```

Claude Code に「PCが重い」「テストのあとブラウザが残る」「掃除を自動化して」と言うだけでも発火します。

## リポジトリを入れずに試す

[`assets/oneshot-prompt.md`](./assets/oneshot-prompt.md) のプロンプトを Claude Code に貼るだけでも、
同じフックが手元に作られます（監査スクリプトと `--deep` は付きません）。

## 中身

| ファイル | 役割 |
|---|---|
| `SKILL.md` | 判断のルール（何を消していいか・何を絶対に触らないか） |
| `assets/oneshot-prompt.md` | 貼るだけプロンプト（薄配布版） |
| `scripts/audit.sh` / `audit.ps1` | 読み取り専用のマシン監査。Markdownで出力 |
| `scripts/sweep.sh` / `sweep.ps1` | 掃除。**既定はdry-run**、`--apply` で実行 |
| `scripts/hook-post-test.sh` / `.ps1` | PostToolUseフック。テストコマンドの後だけ残骸を終了 |
| `assets/settings.hooks.*.json` | settings.json にマージするフック定義 |

## フックの割り当て

| フック | やること | 理由 |
|---|---|---|
| `PostToolUse` (Bash) | テストコマンドの直後に、ヘッドレス残骸だけ終了 | 一番溜まるタイミング |
| `SessionEnd` | 残骸終了＋キャッシュ削除 | 作業中に `coverage` を消さないため |

## 出力されるもの

- マシン監査レポート（残骸件数・メモリ・キャッシュサイズ・ディスク・判定）
- dry-run の削除対象一覧
- 「今日やること」1つと、追加の自動化提案

## 安全設計

- **普段使いのブラウザは終了しない。** 実プロファイル（`Chrome/User Data` 等）を
  参照するプロセスは除外し、`--headless` や `ms-playwright` など自動化固有の
  マーカーを持つものだけを対象にする
- **削除対象は固定リストのみ**（`SKILL.md` に全件記載）。ソース・`.git`・`.env`・
  `node_modules` 本体は触らない
- **既定はdry-run。** `--apply` を付けるまで何も消えない
- OS一時フォルダの掃除は `--deep` を明示したときだけ、かつ60分以上更新のないものだけ
- dev server（`next dev` / `vite` / `npm start`）は対象外
- スクリプトの終了コードは常に0（フックがClaude Codeを止めない）

## 注意

- 監査の数字はOS標準コマンド（`ps` / `du` / `df` / `Get-CimInstance`）由来です
- 並行して別のテストを回している最中に `--apply` すると、そのブラウザも終了します
  （既定では起動3秒未満のプロセスは除外。`--min-age` で調整可）
- WSLから見えるのはWSL側のプロセスだけです。Windows側も掃除するなら `.ps1` を使ってください
