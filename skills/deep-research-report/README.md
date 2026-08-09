# Deep Research Report（deep-research-report）

**Deep Researchの調査結果を丸ごと渡すと、「会議に出せるコンサル品質のHTMLレポート」に編集して出力するスキル。**

Deep Researchは「調べる」は最強ですが、「伝える」は最弱です。
出てくるのは結論が最後・数字が文中に埋没・比較が文章のままの壁のような長文で、そのままでは会議に出せません。
このスキルは、その長文を**書き足さずに並べ替える「編集」**でレポートに変えます。

## 何が変わるか

| Deep Researchの素の出力 | このスキルの出力 |
| --- | --- |
| 結論が最後（結論に辿り着けない） | エグゼクティブサマリーが冒頭に（結論・根拠・示唆の3点） |
| 重要な数字が文中に埋没 | KPI表示・折れ線・横棒・滝グラフに昇格 |
| 「Aは〜、一方Bは〜」の文章比較 | テーブル／フレームワーク表／ステージ表に変換 |
| 出典がURLの羅列 | 図表ごとの出所＋巻末の出典一覧に整理（消さない） |
| 読み手が要約し直す必要がある | 各章の頭に「言いたいこと1文」。飛ばし読みできる |

見本: [assets/sample-research.md](./assets/sample-research.md)（Before・素の調査出力）→
[assets/sample-report.html](./assets/sample-report.html)（After・ブラウザで開けます）

## html-report-design（前作）との違い

デザインは同じシステムを使いますが、役割が違います。前作は「書くときのデザイン矯正」、
本スキルは「調べた結果の編集」です。Deep Researchの出力に固有の癖を処理する頭脳を持っています。

| | html-report-design | deep-research-report |
| --- | --- | --- |
| 役割 | これから作る資料の見た目を矯正 | 出来上がった長文調査の中身を編集 |
| 入力 | 資料にしたい内容（案件メモ） | Deep Research等の長文出力そのもの |
| 独自の処理 | 図解の型・デザインCSS | 証拠の格付け（●◐○）／数字の矛盾・定義差の処理／事実と示唆の分離／残論点の抽出／盛らない原則（全数値照合） |
| 図表化 | 内容に応じて型を選ぶ | 「文章パターン→図表」の対訳表で機械的に変換 |

## 盛らない原則

変換で一番怖いのは「AIが数字を盛る」ことです。このスキルは編集ルールの最上位に
**「原文にない数値・固有名詞・因果関係を追加しない」**を置き、出力前に全数値を原文と照合する
チェックを義務化しています。曖昧な箇所・単一出典・予測値は削るか「要確認」と注記されます。

## 使い方

**モードA: 変換（主役）** — Claude / ChatGPT / Gemini / Codex どの出力でもOK

1. いつも通りDeep Research（等の調査機能）を回す
2. 結果のMD・テキスト・ファイルをClaudeに渡して一言:

```text
この調査結果を deep-research-report でレポートにして
```

**モードB: 調査から実行（Claude CodeなどWeb検索が使える環境）**

```text
〜について調べて、deep-research-report でレポートにして
```

検索5〜10クエリ→出典の相互確認→同じ編集、まで一気に行います。

## 導入

Claude Code（デスクトップ版・CLIどちらでも）に、次の1行を貼るだけです。

```text
https://github.com/Ted0321/kotetsu-work-ai-skills の skills/deep-research-report を ~/.claude/skills/ にインストールして
```

コマンド派は:

```bash
npx skills add Ted0321/kotetsu-work-ai-skills@deep-research-report
```

ChatGPT等へのコピペ利用は [SKILL.md](./SKILL.md) 全文＋調査結果を続けて貼ればOKです。

## 注意

- デザインは [html-report-design](../html-report-design/) と同じ設計（自己完結で同梱済み。併用インストールは不要）
- 白背景・A4印刷前提。アクセントは濃紺1色（「アクセントは #xxxxxx で」と言えば差し替わります）
- 元の調査が間違っている場合、このスキルは直せません（盛らない原則により、元の内容に忠実に出します）
