---
name: deep-research-report
description: "Convert deep research output (Claude Research, ChatGPT Deep Research, Gemini, Codex — any long-form MD/Word/text) into a consulting-quality HTML report: pyramid structure, numbers promoted to KPIs/charts, comparisons turned into framework tables, citations preserved. Use when the user provides research/investigation results and says レポートにして/HTMLにまとめて/資料にして/きれいにして, mentions ディープリサーチの結果/調査結果/リサーチ結果, or asks to research a topic AND deliver a report. NEVER invents numbers or facts not present in the source (盛らない原則)."
---

# Deep Research Report — 調査結果を「会議に出せるレポート」に変換

Deep Researchは「調べる」は最強だが、「伝える」は最弱。
出てくるのは、結論が最後・数字が文中に埋没・比較が文章のままの「壁のような長文」で、そのままでは会議に出せない。
このスキルは調査結果を**編集**し、結論から読めるコンサル品質のHTMLレポートに変換する。

## 目的

Deep Research系機能（Claude / ChatGPT / Gemini / Codex いずれの出力でも）が生成した
長文の調査結果を、意思決定に使えるHTMLレポートへ変換する。
デザインは `html-report-design` と同じ設計（余白と文字階層・濃紺1色・A4印刷対応）。

## 使い方（2モード）

**モードA: 変換（主役・どのAIの出力でもOK）**
ユーザーが調査結果（MD・テキスト・Wordの中身・チャット出力の貼り付け・ファイルパス）を渡してきたら、
それを原文として下の編集ルールで変換する。質問はせず、まず変換して見せる。

**モードB: 調査から実行（Claude Code等、Web検索が使える環境のみ）**
「〜について調べてレポートにして」と言われたら、
1. 問いを3〜5個のサブクエスチョンに分解する
2. Web検索を計5〜10クエリ実行（同義語で複数系統）。主要な主張・数値は**2つ以上の出典で相互確認**する
3. 参照したすべての出典（タイトル・発行元・年）を記録する
4. 集めた事実を「原文」として、以下同じ編集ルールで変換する

## 編集ルール（このスキルの本体）

原文の情報を**足さず・盛らず・並べ替える**。やることは5つ。

1. **ピラミッド化** — 結論を冒頭のエグゼクティブサマリー（結論・根拠・示唆の3点）へ移す。
   各章の頭に「この章で言いたいこと1文」（`.msg`）を立てる。原文の章立てには従わなくてよい。
   「はじめに」「調査方法」の類は削るか巻末の注記へ
2. **数字の昇格** — 文中に埋まった重要数値を拾い出し、最重要3つを `.kpis` に、
   推移は折れ線、構成比・ランキングは横棒、増減の内訳は滝グラフに昇格させる。
   単位・年度を必ず添える
3. **比較・分類の図解化** — 「Aは〜、一方Bは〜」の文章比較はテーブルかフレームワーク表 `.matrix` に、
   段階論はステージ見出し `.mx-h.stage` に、プロセスは矢羽根 `.chevrons` に変換する
4. **出典の保全** — 原文の出典・脚注は消さない。図表には出所 `.src` を付け、
   巻末に「出典一覧」（`.refs`）としてまとめ直す。本文の `[n]` 参照は維持する
5. **盛らない原則（最重要）** — 原文にない数値・固有名詞・因果関係を追加しない。
   原文が「85%超」なら「85%超」のまま使う（勝手に87%などにしない）。
   原文が曖昧・情報が古い・出典が単一の箇所は、削るか「要確認」「単一出典」と注記する。
   推計・予測は必ず「予測」と明示し、チャートでは破線にする

## Deep Research特有の編集観点（デザインスキルとの違いの本体）

Deep Researchの出力には、人が書く文章にはない固有の癖がある。ここを処理するのがこのスキルの頭脳。

**1. 証拠の格付け — 出典の確度を可視化する**
- すべての出典を3段階で格付けし、巻末の出典一覧に付記する:
  - `●` 複数の独立した出典で相互確認できた
  - `◐` 単一出典のみ（採用するが単一と明示）
  - `○` 予測・推計・体感値（チャートは破線、`F`表記）
- 信頼の目安は 官公庁・業界団体の統計 ＞ 調査会社レポート ＞ 企業公開資料 ＞ 記事・ブログ
- 古いデータ（目安2年超）は本文に「時点」を必ず添える

**2. 数字の矛盾・定義差の処理 — 都合のよい方だけ拾わない**
- 同じ指標なのに調査によって数字が食い違う場合、定義差を確認して注記するか、レンジ（例: 54〜68%）で書く
- 「導入」「定着」など調査ごとに定義が揺れる語は、採用した定義を `.note` で明示する

**3. 事実と示唆の分離 — Deep Researchの「意見」を事実に混ぜない**
- 事実（出典番号つき）は本論の章へ、解釈・示唆は最終章に集約し、解釈であることを注記する
- 原文でAIの推測が事実のように書かれている箇所は、示唆側へ移すか削る

**4. 残論点 — 「わかっていないこと」を1セクション立てる**
- 原文が答えていない問い・データの空白・定義の揺れを「残論点と追加調査」として示す
- 読み手の「この調査、どこまで信じていいのか」に先回りして答える。ここが資料の信頼を決める

**5. 文章パターン→図表の対訳表 — 図表化を勘でやらない**

| 原文によくあるパターン | 変換する図表 |
| --- | --- |
| 「20XX年度にX%、20YY年度にY%と上昇し…」 | 折れ線（予測期間は破線） |
| 「AがX%と最も高く、次いでBがY%…」 | 横棒（主役だけ濃紺） |
| 「〜の内訳は、aがX、bがY…」 | ウォーターフォール |
| 「課題はAが47%、Bが41%…」 | フレームワーク表（%を行ラベルへ） |
| 「第一に…第二に…第三に…」 | サマリーの番号列挙 or フレームワーク表 |
| 「4段階の整理が用いられる」「成熟度」 | ステージ表（矢羽根見出し・目標だけ濃紺） |
| 「〜という段階を踏む」「進め方の定石」 | 矢羽根 |
| 「第1四半期に…第3四半期以降に…」 | ロードマップ |
| 「今後は〜と予測される」 | 破線＋`F`表記＋出典格付け`○` |

## レポートの骨格

```html
<div class="page">
  <header class="doc-header">
    <p class="eyebrow">取扱い表記（社外秘 など）</p>
    <h1>結論が伝わるタイトル（「〜の調査結果」ではなく主張を入れる）</h1>
    <p class="lead">何を調べ、何が言えるかを1〜2文で。</p>
    <div class="doc-meta"><span>日付</span><span>作成者</span><span>宛先</span></div>
  </header>
  <section>
    <h2>エグゼクティブサマリー</h2>
    <ol class="summary"><li><b>結論。</b>…</li><li><b>根拠。</b>…</li><li><b>示唆。</b>…</li></ol>
  </section>
  <section>
    <h2><span class="no">01</span>章見出し</h2>
    <p class="msg">この章の so what 1文。</p>
    <!-- .kpis / figure(チャート) / table / .matrix / 本文 -->
  </section>
  <!-- 02, 03 … 事実の章のあと「示唆・打ち手」（解釈と明示） -->
  <section>
    <h2><span class="no">0n</span>残論点 — この調査でわかっていないこと</h2>
    <p class="msg">答えの出ていない問いを残す。ここを埋めるのが次の調査の論点になる。</p>
    <ul><li><b>論点名。</b>何が不明か・なぜ不明か・どう扱ったか</li></ul>
  </section>
  <section>
    <h2>出典一覧</h2>
    <p class="src">確度: ●=複数出典で一致 ◐=単一出典 ○=予測・推計</p>
    <ol class="refs"><li>出典1（発行元・年）●</li><li>…</li></ol>
  </section>
  <footer class="doc-footer"><span>資料名</span><span>注記</span></footer>
</div>
```

## デザインCSS（そのまま使う。変えてよいのは --accent の1色だけ）

```css
:root{--ink:#1a1a1a;--ink-2:#555;--ink-3:#8e8e8e;--accent:#173f66;--accent-tint:#eef3f8;--hairline:#d9d9d9;--fill-gray:#e7e9ec;--paper:#fff}
html{color-scheme:light}
body{margin:0;background:var(--paper);color:var(--ink);font-family:"Helvetica Neue",Arial,"Hiragino Kaku Gothic ProN","Hiragino Sans","Yu Gothic Medium","Yu Gothic",Meiryo,sans-serif;font-size:15px;line-height:1.9;border-top:6px solid var(--accent)}
.page{max-width:760px;margin:0 auto;padding:56px clamp(24px,6vw,48px) 96px}
.doc-header{padding-bottom:28px;border-bottom:1px solid var(--ink)}
.eyebrow{font-size:11px;letter-spacing:.16em;color:var(--ink-3);text-transform:uppercase;margin:0 0 20px}
h1{font-size:27px;line-height:1.5;margin:0 0 12px}
.lead{font-size:14px;color:var(--ink-2);margin:0 0 24px;max-width:38em}
.doc-meta{font-size:12px;color:var(--ink-3);display:flex;gap:24px;flex-wrap:wrap}
.page>section{border-top:1px solid var(--hairline);padding-top:44px;margin-top:64px}
.page>section:first-of-type{border-top:0;padding-top:0;margin-top:56px}
h2{font-size:19px;margin:0}
h2 .no{color:var(--accent);margin-right:14px}
.msg{font-size:16px;font-weight:600;line-height:1.8;margin:18px 0 24px;max-width:36em}
p{margin:0 0 16px;max-width:42em}
ul,ol{margin:0 0 16px;padding-left:1.4em;max-width:41em}
li{margin-bottom:6px}
ul{list-style:none;padding-left:1.2em}
ul li::before{content:"–";float:left;margin-left:-1.2em;color:var(--ink-3)}
.summary{list-style:none;margin:24px 0 0;padding:0;counter-reset:s;max-width:44em}
.summary li{counter-increment:s;position:relative;padding-left:2.4em;margin-bottom:14px}
.summary li::before{content:counter(s,decimal-leading-zero);position:absolute;left:0;top:.4em;font-size:12px;font-weight:700;color:var(--accent)}
.kpis{display:flex;flex-wrap:wrap;row-gap:24px;margin:32px 0 8px}
.kpi{padding:2px 32px}
.kpi:first-child{padding-left:0}
.kpi+.kpi{border-left:1px solid var(--hairline)}
.kpi .v{font-size:30px;font-weight:700;color:var(--accent);line-height:1.3}
.kpi .v small{font-size:14px;margin-left:2px}
.kpi .l{font-size:11.5px;color:var(--ink-3);margin-top:6px}
.tbl,.fig-scroll{overflow-x:auto}
table{width:100%;border-collapse:collapse;margin:28px 0 8px;font-size:13px;line-height:1.6}
caption,figcaption{text-align:left;font-size:12.5px;font-weight:600;margin-bottom:10px}
th{font-size:12px;font-weight:600;text-align:left;padding:10px 12px;border-top:2px solid var(--ink);border-bottom:1px solid var(--ink)}
td{padding:10px 12px;border-bottom:1px solid var(--hairline);vertical-align:top}
th.num,td.num{text-align:right;font-variant-numeric:tabular-nums}
tr.total td{border-top:1px solid var(--ink);border-bottom:2px solid var(--ink);font-weight:600;background:var(--accent-tint)}
figure{margin:32px 0 8px}
figcaption{margin-bottom:14px}
figure svg{width:100%;height:auto;display:block}
svg text{font-family:inherit}
.src{font-size:11.5px;color:var(--ink-3);margin:6px 0 0}
.note{font-size:12.5px;color:var(--ink-2);border-left:2px solid var(--hairline);padding:2px 0 2px 14px;margin:24px 0 16px;max-width:40em}
.chevrons{display:flex;margin:28px 0 8px;min-width:520px}
.chev{flex:1;padding:9px 10px 9px 22px;font-size:12px;font-weight:600;line-height:1.5;text-align:center;background:var(--fill-gray);margin-left:4px;clip-path:polygon(0 0,calc(100% - 12px) 0,100% 50%,calc(100% - 12px) 100%,0 100%,12px 50%)}
.chev:first-child{margin-left:0;clip-path:polygon(0 0,calc(100% - 12px) 0,100% 50%,calc(100% - 12px) 100%,0 100%)}
.chev.on{background:var(--accent);color:#fff}
.chev small{display:block;font-size:10.5px;font-weight:500;opacity:.75}
.matrix{display:grid;grid-template-columns:var(--mx-label,140px) repeat(var(--mx-cols,2),1fr);gap:18px 20px;margin:28px 0 8px;min-width:560px}
.mx-h{font-size:11.5px;font-weight:600;color:var(--ink-2);text-align:center;align-self:end;padding-bottom:8px;border-bottom:1px solid var(--ink)}
.mx-label{background:var(--accent);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;gap:2px;font-size:12px;font-weight:700;padding:12px 10px}
.mx-label small{font-size:10px;opacity:.7}
.mx-label.alt{background:var(--fill-gray);color:var(--ink)}
.mx-cell{font-size:12px;line-height:1.75}
.mx-cell ul{margin:0}
.mx-h.stage{border-bottom:0;background:var(--fill-gray);color:var(--ink);padding:7px 8px;line-height:1.4;clip-path:polygon(0 0,calc(100% - 10px) 0,100% 50%,calc(100% - 10px) 100%,0 100%,10px 50%)}
.mx-h.stage.first{clip-path:polygon(0 0,calc(100% - 10px) 0,100% 50%,calc(100% - 10px) 100%,0 100%)}
.mx-h.stage.on{background:var(--accent);color:#fff}
.mx-h.stage small{display:block;font-size:9.5px;font-weight:600;opacity:.7;letter-spacing:.06em}
b,strong{font-weight:700}
.refs{list-style:none;margin:16px 0 0;padding:0;counter-reset:r;font-size:11.5px;color:var(--ink-3)}
.refs li{counter-increment:r;position:relative;padding-left:2.2em;margin-bottom:5px;line-height:1.7}
.refs li::before{content:"[" counter(r) "]";position:absolute;left:0}
.refs li::after{content:none}
.doc-footer{margin-top:88px;padding-top:20px;border-top:1px solid var(--hairline);font-size:11.5px;color:var(--ink-3);display:flex;justify-content:space-between;flex-wrap:wrap;gap:16px}
@media print{@page{size:A4;margin:16mm}.page{max-width:none;padding:0}table,figure,.kpis,.chevrons,.matrix{break-inside:avoid}}
```

チャートの作法: 脇役グレー（面 `#c9ccd1`・線 `#a8adb5`）＋主役の濃紺1色、凡例なしの直接ラベル、
負値のみ `#a33c2e`（`▲`表記）、予測は破線。SVGは `viewBox` で書く。
完成見本: [assets/sample-research.md](./assets/sample-research.md)（Before）→
[assets/sample-report.html](./assets/sample-report.html)（After）。

## 変換の手順

1. 原文を通読し、次を抽出する: 結論候補／重要数値（単位・年度つき）／比較・分類／時系列／出典
2. 骨格に再配置する。サマリーを最初に書き、各章は「msg → 根拠」の順に組む
3. 図解は型で作る（数値比較=table、推移=折れ線、構成比=横棒、比較=matrix、段階=stage、プロセス=矢羽根）
4. **照合チェック**: 出力に使ったすべての数値・固有名詞を原文と突き合わせ、一致しないものは削除する
5. 単一HTMLファイルで出力する（上のCSSを改変せず使用）

## 品質チェック（出力前）

- [ ] 出力中の数値・固有名詞が**すべて原文にある**（照合済み。原文にない数字を1つも作っていない）
- [ ] 出典一覧に確度マーク（●◐○）が付いている。予測のチャートは破線＋`F`表記
- [ ] 調査間で食い違う数字を片側だけ採用していない（レンジ表記か定義差の注記がある）
- [ ] 事実（出典つき）と示唆（解釈）が章として分離されている
- [ ] 「残論点（わかっていないこと）」のセクションがある
- [ ] サマリーが結論・根拠・示唆の3点になっている。全章に `.msg` がある
- [ ] 出典一覧（`.refs`）があり、原文の出典が消えていない
- [ ] カードUI 0個・色は黒グレー＋濃紺1色・グラデ/絵文字/角丸 0
- [ ] 図表に番号・タイトル・出所がある。数字は右揃え・単位明記

## トーン

- 編集者として振る舞う。書き足さない、盛らない、並べ替えて研ぐ
- 迷ったら「原文に忠実」を優先し、判断が必要な箇所は注記で開示する
