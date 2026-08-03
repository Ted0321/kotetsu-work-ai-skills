---
name: machine-hygiene
description: "Keep the dev machine cool and fast by auditing it and cleaning up after test runs: kill leftover headless browser processes, delete regenerable build/test caches, and install Claude Code hooks that do it automatically at zero token cost. Use when the user says their machine is hot/slow/laggy/noisy, when browsers or test runners pile up after E2E runs, when disk or memory is filling up, or in Japanese 「PCが重い」「ファンがうるさい」「テストのあとブラウザが残る」「メモリを食っている」「キャッシュを消したい」「マシンを監査して」「掃除を自動化したい」."
---

# machine-hygiene — テストの後始末を自動化する

## 目的

E2Eテストやスクレイピングを回すたびに、ヘッドレスブラウザとキャッシュが積み上がる。
気づくとCPUが張り付き、ファンが回り、エディタがカクつく。
**その後始末を、毎回AIに頼まず、フックで自動化する。**

トークンを使うのはこのスキルを呼ぶ最初の1回だけ。
以後の掃除はフック（ただのシェル実行）なので**追加コストはゼロ**。

## このスキルがやること

| モード | 発火する言葉 | 中身 |
|---|---|---|
| **監査** | 「PCが重い」「監査して」 | 読み取り専用。残骸・キャッシュ・重いプロセスを一覧化し、次の一手を出す |
| **掃除** | 「掃除して」「消して」 | dry-runで見せる → 承認 → 実行 |
| **自動化** | 「自動化して」「フック入れて」 | Claude Codeのフックに登録し、以後は自動 |

## 原則（安全条件・例外なし）

1. **プロセスを終了する条件は3つ全部を満たすときだけ。** 1つでも欠けたら触らない。
   - **ブラウザ本体かドライバであること**（`chrome` / `chromium` / `msedge` /
     `firefox` / `headless_shell` / `chromedriver` / `geckodriver` / `msedgedriver`）
   - **自動化固有のマーカーを持つこと**（`--headless`、`--remote-debugging-port`、
     `ms-playwright`、`puppeteer_dev_chrome_profile`、`selenium-manager` 等）
   - **起動から3秒以上経っていること**

   `--headless` だけで判定してはいけない。Windowsの `conhost.exe --headless`
   （正規のコンソールホスト。実測で23件検出）や `libreoffice --headless`
   （文書変換）を巻き込み、ターミナルや変換処理を落とす。

   加えて、次は無条件で除外する。
   - 実プロファイル参照（`AppData\Local\Google\Chrome\User Data`、
     `Application Support/Google/Chrome` 等）＝普段使いのブラウザ
   - `C:\Windows\` / `/System/` 配下＝OSのシステムプロセス
2. **消すのは再生成できるものだけ。** ソース、`.git`、`.env`、`node_modules`本体、
   ビルド成果物の最終物は対象外。対象は下の固定リストに限る。
3. **削除は必ず dry-run を先に見せる。** `--apply` なしで実行して結果を提示し、
   ユーザーの承認を得てから `--apply` を付ける。
4. **`--deep`（OS一時フォルダの掃除）は毎回明示的に確認する。** 既定では走らせない。
5. **dev server は殺さない。** `next dev`、`vite`、`npm start` などは対象外。

## 削除対象（この固定リスト以外は消さない）

```text
node_modules/.cache   node_modules/.vite   .next/cache   .turbo   .parcel-cache
.vite   .nuxt   .svelte-kit   .astro   .angular/cache   .eslintcache
coverage   .nyc_output   test-results   playwright-report   blob-report
.pytest_cache   .mypy_cache   .ruff_cache   __pycache__（再帰）
```

`--deep` を付けたときだけ、OSの一時フォルダ（`$TMPDIR` / `%TEMP%`）の直下にある
自動化プロファイル残骸（`playwright*`、`puppeteer_dev_*`、`chromedriver*`、
`scoped_dir*`、`rust_mozprofile*` など、**60分以上更新されていないもの**）を追加する。

## 手順

### A. 監査（まずこれ）

OSに合わせて実行する。**何も終了せず、何も削除しない。**

```bash
# macOS / Linux / WSL / Git Bash
bash scripts/audit.sh
```

```powershell
# Windows
powershell -NoProfile -File scripts\audit.ps1
```

出力（Markdown）を読み、次の3点だけを言う。

1. **いま何が起きているか** — 残骸の件数とメモリ、キャッシュ合計サイズ
2. **原因** — どのテストが残骸を出しているか（プロセスのコマンドラインから推定）
3. **次の一手** — 掃除するか、フックを入れるか

数字を並べて終わりにしない。「40℃で回すために今日やること」を1つに絞る。

### B. 掃除

```bash
bash scripts/sweep.sh                 # 1) dry-run。消える対象を提示する
bash scripts/sweep.sh --apply         # 2) 承認後に実行
bash scripts/sweep.sh --apply --deep  # 3) 一時フォルダまで（都度確認）
```

```powershell
powershell -NoProfile -File scripts\sweep.ps1
powershell -NoProfile -File scripts\sweep.ps1 -Apply
powershell -NoProfile -File scripts\sweep.ps1 -Apply -Deep
```

**1) を飛ばして 2) を実行しない。** dry-run の出力をそのまま見せて承認を取る。

### C. 自動化（フック導入）

ここが本体。以後はAIを呼ばずに勝手に片付く。

| フック | 発火 | やること | なぜ |
|---|---|---|---|
| `PostToolUse` (matcher: `Bash`) | Bashコマンドの実行後 | コマンドがテストだったときだけ、ヘッドレス残骸を終了 | テスト直後が一番溜まる |
| `SessionEnd` | セッション終了時 | 残骸終了＋キャッシュ削除 | 作業中に `coverage` を消さないため、削除はここ |

**キャッシュ削除を PostToolUse に入れないこと。** テスト直後に `coverage` や
`test-results` を消すと、レポートを読めなくなる。

導入手順:

1. スキル本体を配置する（未導入なら）
   ```bash
   npx skills add Ted0321/kotetsu-work-ai-skills@machine-hygiene
   ```
2. `assets/settings.hooks.macos-linux.json`（Windowsは `settings.hooks.windows.json`）を開く
3. 中身の `hooks` を、settings.json の `hooks` に**マージ**する
   - 全プロジェクトに効かせる: `~/.claude/settings.json`
   - このプロジェクトだけ: `<project>/.claude/settings.json`
   - **既存の `hooks` を上書きしない。** 既に定義があれば配列に足す
4. パスを実際の配置先に直す（Windowsは絶対パスにする）
5. Claude Code を再起動し、`/hooks` で登録を確認する
6. 動作確認: 適当なテストを1回走らせ、`bash scripts/audit.sh` で残骸が0になることを見る

導入後、ユーザーには次の1行だけ伝える。

> 入れました。次からテストの後は自動でヘッドレスが片付き、セッション終了時にキャッシュも消えます。追加のトークンコストはかかりません。

### D. さらなる機会（監査の“おかわり”）

監査結果に次が出ていたら、追加の自動化を提案する（勝手に入れない）。

| 監査で見えたもの | 提案する自動化 |
|---|---|
| 15分以上生きているテストランナーが常にいる | テストコマンドに timeout を付ける／CIに寄せる |
| 一時フォルダが数GB | 週1で `sweep --apply --deep` を回す（cron / タスクスケジューラ） |
| 特定のプロセスが常にCPU上位 | そのツールの watch モードを切る |
| キャッシュ合計が毎回1GB超 | ビルドキャッシュの置き場をプロジェクト外に移す |

## 出力フォーマット（厳守）

```markdown
## いま何が起きているか
（残骸◯件 / メモリ◯GB / キャッシュ◯GB — 数字は監査出力から引く）

## 原因
（どの作業が残骸を出しているか、1〜2行）

## 今日やること
（1つだけ。掃除するか、フックを入れるか）

## 提案（任意）
（さらなる自動化があれば最大2つ。無ければ「なし」）
```

## 品質チェック（出力前）

- [ ] 削除を伴う操作の前に、dry-run の結果を提示して承認を取ったか
- [ ] 「普段使いのブラウザは対象外」であることを伝えたか
- [ ] 数字（件数・サイズ）を監査出力から引用したか（推測で書いていないか）
- [ ] 「今日やること」を1つに絞ったか
- [ ] フック導入時、既存の `hooks` 定義を壊していないか

## トーン

- 簡潔、実務。恐怖を煽らない
- 「速くなりました」ではなく「◯GB 解放、残骸0件」と数字で言う
