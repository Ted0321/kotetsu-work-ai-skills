# 貼るだけプロンプト（machine-hygiene 薄配布版）

リポジトリを入れなくても、**このプロンプトをClaude Codeに貼るだけ**で
「テスト後の後始末フック」が手元に作られる。

安全条件をプロンプト本文に埋め込んであるのが要点。
「ヘッドレスを全部終了して」とだけ頼むと、**普段使いのChromeまで落ちる**。

---

## 本体（そのままコピー）

```text
テスト実行後の後始末を、Claude Codeのフックで自動化して。以下の条件で作って。

【1】掃除スクリプト ~/.claude/scripts/sweep.sh を作る

終了するプロセス（この条件を「全部」満たすものだけ）:
- ブラウザ本体かドライバであること。コマンドラインに chrome / chromium / msedge /
  firefox / headless_shell / chromedriver / geckodriver / msedgedriver のいずれかを含む
- かつ、コマンドラインに --headless / --remote-debugging-port / --remote-debugging-pipe /
  ms-playwright / puppeteer_dev_chrome_profile / selenium-manager のいずれかを含む
- かつ、起動から3秒以上経っている

絶対に終了しないもの（除外条件・例外なし）:
- 実行ファイルが C:\Windows\ や /System/ にあるもの＝OSのシステムプロセス
- コマンドラインに実プロファイルのパスを含むもの
  （Chrome/User Data、Application Support/Google/Chrome、.config/google-chrome、
  .config/chromium、.mozilla/firefox）＝普段使いのブラウザ
- dev server（vite / next dev / npm start / webpack serve）

※「--headless を含む」だけで判定しないこと。Windowsの conhost.exe（正規の
コンソールホスト）や libreoffice --headless（文書変換）まで巻き込み、
ターミナルや変換処理が落ちる。ブラウザ本体かどうかの条件が必須。

削除するキャッシュ（--caches を付けたときだけ、カレント配下のみ、この固定リスト以外は消さない）:
- node_modules/.cache, node_modules/.vite, .next/cache, .turbo, .parcel-cache,
  .angular/cache, .eslintcache, coverage, .nyc_output, test-results,
  playwright-report, blob-report, .pytest_cache, .mypy_cache, .ruff_cache, __pycache__
- .git / .env / node_modules本体 / ソースは絶対に触らない

オプション:
- 既定は dry-run（対象を表示するだけで何もしない）
- --apply を付けたときだけ実際に終了・削除する
- 終了コードは常に0にする（フックがClaude Codeを止めないように）

【2】~/.claude/settings.json の hooks に追記する（既存の hooks は絶対に壊さず、配列に足す）

- PostToolUse（matcher: "Bash"）
  標準入力のフックJSONから tool_input.command を取り出し、それがテストコマンド
  （npm/pnpm/yarn/bun test、vitest、jest、playwright test、cypress run、pytest、
  go test、cargo test など）だったときだけ sweep.sh --apply を実行。
  ※ここではキャッシュを消さない（直後に coverage / test-results を読みたいので）

- SessionEnd
  sweep.sh --apply --caches を実行（キャッシュ削除はここだけ）

【3】作り終えたら、まず --apply を付けずに実行して「何が終了・削除される予定か」を
私に見せて。私がOKと言うまで --apply は実行しないで。

（Windowsなら sweep.sh の代わりに PowerShell スクリプトで同じものを作って、
フックは powershell -NoProfile -ExecutionPolicy Bypass -File で呼ぶこと）
```

---

## なぜこの形か

| 設計 | 理由 |
|---|---|
| 「ブラウザ本体であること」を必須条件にする | `--headless` だけで判定すると、Windowsの `conhost.exe --headless` を残骸と誤認する（実測で23件検出）。kill するとターミナルが落ちる |
| 除外条件を先に書く | 「終了して」だけだと普段使いのChromeが落ちる。事故の9割はここ |
| 削除対象を固定リストで渡す | 「キャッシュを消して」は範囲が無限。消していい物だけを列挙する |
| dry-run を既定にする | 最初の1回を必ず目視できる |
| キャッシュ削除を SessionEnd だけにする | テスト直後に coverage を消すと、レポートが読めなくなる |
| 終了コードを常に0にする | フックが落ちるとClaude Code側の動作が止まる |

## 厚い版との違い

| | 貼るだけプロンプト | リポジトリ版（`npx skills add`） |
|---|---|---|
| 導入 | コピペ1回 | 1コマンド |
| マシン監査 | なし | `audit.sh` / `audit.ps1` あり |
| Windows | プロンプトで指示 | `.ps1` 同梱・検証済み |
| 一時フォルダ掃除 | なし | `--deep` あり |
| 更新 | 手動 | `npx skills` で追従 |

```bash
npx skills add Ted0321/kotetsu-work-ai-skills@machine-hygiene
```
