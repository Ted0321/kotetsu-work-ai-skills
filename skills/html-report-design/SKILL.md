---
name: html-report-design
description: "Design system that makes HTML output look like a professional consulting deliverable instead of default AI styling. Use WHENEVER generating any HTML document — report, analysis memo, proposal, research summary, dashboard, artifact — and when the user says 「HTMLで資料」「HTMLでまとめて」「レポートにして」「コンサル風に」「資料っぽく」「デザインがダサい」 or asks to restyle existing AI-generated HTML. Replaces boxes, borders, gradients, emoji and rainbow colors with whitespace-driven, typography-first, print-ready (A4) design."
---

# HTML資料デザイン — コンサル品質の出力設計

AIが出すHTMLがダサいのは、**構造を「線と箱」で作るから**。
一流の資料は、構造を**「余白と文字の階層」**で作る。
このスキルは、HTMLを出力するあらゆる場面でその流儀を強制する。

## 目的

HTMLで資料（報告書・分析メモ・提案書・調査サマリー・ダッシュボード）を出すとき、
そのまま社内外に出せる「コンサル品質」のデザインで出力する。
デフォルトのAIっぽい見た目（カード乱立・グラデ・絵文字・虹色）を禁止する。

## 原則（5つ）

1. **区切りは余白で作る。** セクションの境界は64px以上の余白＋横の細罫1本まで。囲み枠は使わない。
2. **階層は文字で作る。** サイズ・太さ・色の濃淡（黒→グレー2段階）で階層を表現する。背景色で表現しない。
3. **色は3つまで。** 紙の白＋インクの黒グレー系＋アクセント1色（既定は濃紺）。アクセントは面積5%以下、重要な数字と構造要素だけに使う。
4. **構造は「メッセージ→根拠」。** 各セクションは見出しの直後に「言いたいこと1文（メッセージライン）」を置き、その下に根拠（表・図・本文）を並べる。
5. **印刷に耐える。** 白背景固定・A4で崩れない。画面映えではなく配布資料として設計する。

## 禁止事項（ダサさの正体。1つでもあれば直す）

- `border` + `border-radius` + `box-shadow` の**カードUI**でコンテンツを囲む
- グラデーション背景（特に紫→青）、ダークテーマ既定
- 絵文字・アイコンを見出しや箇条書きの飾りに使う
- 意味なく色数が増える（青の情報ボックス、黄色の注意ボックス、緑の成功ボックス…）
- 本文・見出しのセンタリング（表紙のみ例外可、既定は左揃え）
- 表の縦罫線・全セル罫線・シマシマ背景
- 角丸・影・立体表現の多用
- `border-left: 4px solid` の色付きコールアウト乱立

## デザインCSS（そのまま使う。変えてよいのは --accent の1色だけ）

```css
:root{
  --ink:#1a1a1a;         /* 本文 */
  --ink-2:#555555;       /* 補足 */
  --ink-3:#8e8e8e;       /* キャプション・出所 */
  --accent:#173f66;      /* アクセント（濃紺）。クライアントカラーがあれば1色だけ差し替え */
  --accent-tint:#eef3f8; /* アクセント淡色。合計行など最小限に */
  --hairline:#d9d9d9;    /* 罫線 */
  --fill-gray:#e7e9ec;   /* 図解の脇役の面（矢羽根・ロードマップのバー） */
  --paper:#ffffff;
}
html{color-scheme:light}
body{
  margin:0;background:var(--paper);color:var(--ink);
  font-family:"Helvetica Neue",Arial,"Hiragino Kaku Gothic ProN","Hiragino Sans","Yu Gothic Medium","Yu Gothic",Meiryo,sans-serif;
  font-size:15px;line-height:1.9;
  border-top:6px solid var(--accent);
  -webkit-font-smoothing:antialiased;
}
.page{max-width:760px;margin:0 auto;padding:56px clamp(24px,6vw,48px) 96px}

/* 表紙ブロック */
.doc-header{padding-bottom:28px;border-bottom:1px solid var(--ink)}
.eyebrow{font-size:11px;letter-spacing:.16em;color:var(--ink-3);text-transform:uppercase;margin:0 0 20px}
h1{font-size:27px;line-height:1.5;letter-spacing:.02em;margin:0 0 12px;font-feature-settings:"palt" 1}
.lead{font-size:14px;color:var(--ink-2);margin:0 0 24px;max-width:38em}
.doc-meta{font-size:12px;color:var(--ink-3);display:flex;gap:24px;flex-wrap:wrap}

/* セクション */
.page>section{border-top:1px solid var(--hairline);padding-top:44px;margin-top:64px}
.page>section:first-of-type{border-top:0;padding-top:0;margin-top:56px}
h2{font-size:19px;letter-spacing:.03em;margin:0;font-feature-settings:"palt" 1}
h2 .no{color:var(--accent);margin-right:14px;font-variant-numeric:tabular-nums}
.msg{font-size:16px;font-weight:600;line-height:1.8;margin:18px 0 24px;max-width:36em}
h3{font-size:15px;margin:36px 0 8px}
p{margin:0 0 16px;max-width:42em}

/* リスト */
ul,ol{margin:0 0 16px;padding-left:1.4em;max-width:41em}
li{margin-bottom:6px}
ul{list-style:none;padding-left:1.2em}
ul li::before{content:"–";float:left;margin-left:-1.2em;color:var(--ink-3)}

/* サマリー（結論の番号付き列挙） */
.summary{list-style:none;margin:24px 0 0;padding:0;counter-reset:s;max-width:44em}
.summary li{counter-increment:s;position:relative;padding-left:2.4em;margin-bottom:14px}
.summary li::before{
  content:counter(s,decimal-leading-zero);position:absolute;left:0;top:.4em;
  font-size:12px;font-weight:700;color:var(--accent);letter-spacing:.04em;
  font-variant-numeric:tabular-nums;
}

/* KPI（数字は箱に入れず、余白と縦罫で並べる） */
.kpis{display:flex;flex-wrap:wrap;row-gap:24px;margin:32px 0 8px}
.kpi{padding:2px 32px}
.kpi:first-child{padding-left:0}
.kpi+.kpi{border-left:1px solid var(--hairline)}
.kpi .v{font-size:30px;font-weight:700;color:var(--accent);line-height:1.3;
  font-variant-numeric:tabular-nums;letter-spacing:.01em}
.kpi .v small{font-size:14px;font-weight:600;margin-left:2px}
.kpi .l{font-size:11.5px;color:var(--ink-3);letter-spacing:.06em;margin-top:6px}

/* 表（縦線なし・横の細罫のみ。数字は右揃え） */
.tbl{overflow-x:auto}
table{width:100%;border-collapse:collapse;margin:28px 0 8px;font-size:13px;line-height:1.6}
caption{text-align:left;font-size:12.5px;font-weight:600;margin-bottom:10px}
th{font-size:12px;font-weight:600;text-align:left;padding:10px 12px;
  border-top:2px solid var(--ink);border-bottom:1px solid var(--ink);vertical-align:bottom}
td{padding:10px 12px;border-bottom:1px solid var(--hairline);vertical-align:top}
th.num,td.num{text-align:right;font-variant-numeric:tabular-nums}
tr.total td{border-top:1px solid var(--ink);border-bottom:2px solid var(--ink);
  font-weight:600;background:var(--accent-tint)}

/* 図表・出所・注記 */
figure{margin:32px 0 8px}
figcaption{font-size:12.5px;font-weight:600;margin-bottom:14px}
figure svg{width:100%;height:auto;display:block}
svg text{font-family:inherit}
.fig-scroll{overflow-x:auto}
.src{font-size:11.5px;color:var(--ink-3);margin:6px 0 0}
.note{font-size:12.5px;color:var(--ink-2);border-left:2px solid var(--hairline);
  padding:2px 0 2px 14px;margin:24px 0 16px;max-width:40em}

/* 矢羽根（プロセス・バリューチェーン。主役フェーズだけ濃紺） */
.chevrons{display:flex;margin:28px 0 8px;min-width:520px}
.chev{flex:1;padding:9px 10px 9px 22px;font-size:12px;font-weight:600;line-height:1.5;
  text-align:center;background:var(--fill-gray);margin-left:4px;
  clip-path:polygon(0 0,calc(100% - 12px) 0,100% 50%,calc(100% - 12px) 100%,0 100%,12px 50%)}
.chev:first-child{margin-left:0;
  clip-path:polygon(0 0,calc(100% - 12px) 0,100% 50%,calc(100% - 12px) 100%,0 100%)}
.chev.on{background:var(--accent);color:#fff}
.chev small{display:block;font-size:10.5px;font-weight:500;opacity:.75}

/* ロードマップ（列=時間、行=ワークストリーム。縦のグリッド線は引かない） */
.roadmap{min-width:560px;margin:28px 0 8px}
.rm-row{display:grid;grid-template-columns:120px repeat(6,1fr);align-items:center}
.rm-row.rm-head{border-bottom:1px solid var(--ink)}
.rm-h{font-size:11px;font-weight:600;color:var(--ink-3);text-align:center;
  padding:0 0 8px;letter-spacing:.04em}
.rm-row:not(.rm-head){border-bottom:1px solid var(--hairline);padding:12px 0}
.rm-lane{font-size:12px;font-weight:600;padding-right:12px;line-height:1.5}
.rm-bar{font-size:11px;font-weight:600;line-height:1.4;padding:4px 10px;
  background:var(--fill-gray);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.rm-bar.on{background:var(--accent);color:#fff}
.rm-ms{font-size:11.5px;font-weight:700;color:var(--accent);white-space:nowrap}

/* フレームワーク表（左=濃色ラベル。中身は枠で囲まず、余白で整列させる） */
.matrix{display:grid;grid-template-columns:var(--mx-label,140px) repeat(var(--mx-cols,2),1fr);
  gap:18px 20px;margin:28px 0 8px;min-width:560px}
.mx-h{font-size:11.5px;font-weight:600;color:var(--ink-2);text-align:center;
  align-self:end;padding-bottom:8px;border-bottom:1px solid var(--ink)}
.mx-label{background:var(--accent);color:#fff;display:flex;flex-direction:column;
  align-items:center;justify-content:center;text-align:center;gap:2px;
  font-size:12px;font-weight:700;line-height:1.5;padding:12px 10px}
.mx-label small{font-size:10px;font-weight:600;opacity:.7;letter-spacing:.08em}
.mx-label.alt{background:var(--fill-gray);color:var(--ink)}
.mx-cell{font-size:12px;line-height:1.75}
.mx-cell ul{margin:0}
.mx-cell li{margin-bottom:5px}
/* ステージ型の列見出し（矢羽根ヘッダー。目標ステージだけ濃紺） */
.mx-h.stage{border-bottom:0;background:var(--fill-gray);color:var(--ink);
  padding:7px 8px;line-height:1.4;
  clip-path:polygon(0 0,calc(100% - 10px) 0,100% 50%,calc(100% - 10px) 100%,0 100%,10px 50%)}
.mx-h.stage.first{clip-path:polygon(0 0,calc(100% - 10px) 0,100% 50%,calc(100% - 10px) 100%,0 100%)}
.mx-h.stage.on{background:var(--accent);color:#fff}
.mx-h.stage small{display:block;font-size:9.5px;font-weight:600;opacity:.7;letter-spacing:.06em}

/* 強調（色の強調はアクセント1色・重要な数字だけ） */
b,strong{font-weight:700}
.em{color:var(--accent);font-weight:700}
a{color:inherit;text-decoration:underline;text-decoration-color:var(--hairline);text-underline-offset:3px}
a:hover{text-decoration-color:var(--accent)}

/* フッター */
.doc-footer{margin-top:88px;padding-top:20px;border-top:1px solid var(--hairline);
  font-size:11.5px;color:var(--ink-3);display:flex;justify-content:space-between;gap:16px;flex-wrap:wrap}

/* 印刷（A4で配れる） */
@media print{
  @page{size:A4;margin:16mm}
  body{border-top-width:4px}
  .page{max-width:none;padding:0}
  .page>section{margin-top:48px;padding-top:32px}
  table,figure,.kpis,.chevrons,.roadmap,.matrix{break-inside:avoid}
  a{text-decoration:none}
}
```

## 資料の骨格（HTML構造）

```html
<div class="page">

  <header class="doc-header">
    <p class="eyebrow">社外秘 ／ Draft などの取扱い表記</p>
    <h1>結論が伝わるタイトル</h1>
    <p class="lead">この資料が何を扱い、何を決めるためのものかを1〜2文で。</p>
    <div class="doc-meta"><span>日付</span><span>作成部署</span><span>宛先</span></div>
  </header>

  <section>
    <h2>エグゼクティブサマリー</h2>
    <ol class="summary">
      <li><b>結論。</b>補足1文。</li>
      <li><b>根拠の要点。</b>補足1文。</li>
      <li><b>依頼・次の判断。</b>補足1文。</li>
    </ol>
  </section>

  <section>
    <h2><span class="no">01</span>セクション見出し（トピック）</h2>
    <p class="msg">このセクションで言いたいこと1文（so what）。</p>
    <!-- 根拠: .kpis / table / figure（チャート・矢羽根・ロードマップ等の図解） / 本文 -->
  </section>

  <!-- 02, 03 … 最後は「推奨アクション」（アクション・オーナー・期限の表） -->

  <footer class="doc-footer">
    <span>資料名</span><span>出所・注記</span>
  </footer>

</div>
```

- サマリーは**結論→根拠→依頼**の3点。本文を書いてから最後に要約を書くのではなく、先に決める
- セクション見出しはトピック、`.msg` は主張。**見出しだけ読めば流れが、.msgだけ読めば結論がわかる**状態にする
- 最終セクションは必ず「次のアクション」（誰が・何を・いつまでに）

## コンポーネントの作法

**表**
- 縦罫線は引かない。ヘッダー上2px＋下1pxの黒、行間は細いグレー罫のみ
- 数字の列は `class="num"` で右揃え・桁区切り・単位はヘッダーに明記（例:「売上（億円）」）
- 強調したい行は `tr.total`（淡色背景＋太字）を1行まで

**KPI・大きい数字**
- 箱に入れない。`.kpis` で横に並べ、間は縦の細罫1本
- 数字はアクセント色・単位は `<small>`、ラベルは小さくグレー

**チャート（SVG推奨）**
- 配色は「**脇役は全部グレー、主役の1系列だけ濃紺 var(--accent)**」。虹色に塗り分けない
  （グレーの使い分け: 面 `#c9ccd1`／広い地 `#e7e9ec`／線 `#a8adb5`）
- 凡例ボックスは作らず、系列名・数値は**バーや線の近くに直接ラベル**
- 3D・影・グラデ・チャートの外枠は禁止。軸線・グリッドは細いグレーを最小限
- 負値・悪化を示すときだけレンガ色 `#a33c2e` を追加してよい（マイナスは `▲8.0` 表記）
- SVGは `viewBox` で書き、CSS側の `figure svg{width:100%;height:auto}` で可変にする

## 図解の型（コンサル図解をHTMLで作る）

「何を伝えたいか」で型を選ぶ。箱と矢印の自由描画はしない。

| 伝えたいこと | 型 | 実装 |
| --- | --- | --- |
| プロセス・バリューチェーン・フェーズ | 矢羽根 `.chevrons` | HTML/CSS |
| 計画・スケジュール・体制の時間軸 | ロードマップ `.roadmap` | HTML/CSS（grid） |
| 論点×観点の整理・文章セルの比較 | フレームワーク表 `.matrix` | HTML/CSS（grid） |
| 成熟度・ステージ比較（現状→目標） | フレームワーク表＋矢羽根見出し `.mx-h.stage` | HTML/CSS（grid） |
| 競合・市場の布置（2軸＋規模） | バブルマップ | SVG |
| 増減の内訳（なぜ増えた／減った） | ウォーターフォール | SVG |
| 推移・トレンド（実績＋予測） | 折れ線 | SVG |
| 量の比較・ランキング | 横棒 | SVG |

どの型も共通ルールは同じ: **脇役グレー・主役だけ濃紺・直接ラベル・図表番号と出所つき**。
実装見本は `assets/report.template.html`（SVG系=図表1・2・3・6、矢羽根=図表5、
フレームワーク表=図表7・8、ロードマップ=図表10）。

**矢羽根（`.chevrons`）**
- フェーズは5個まで。当社領域・注力フェーズだけ `.on`（濃紺）、他はグレー
- 補足は各羽根の中に `<small>` で1行。矢印画像や `→` 文字で代用しない

```html
<div class="fig-scroll"><div class="chevrons">
  <div class="chev">集荷・入庫</div>
  <div class="chev on">保管<small>温度管理・薬機法</small></div>
  <div class="chev on">出荷<small>当日カットオフ</small></div>
  <div class="chev">配送<small>パートナー連携</small></div>
</div></div>
```

**ロードマップ（`.roadmap`）**
- 列=時間（月・四半期）、行=ワークストリーム。列数を変えるときは `repeat(6,1fr)` を書き換える
- バーの位置は `style="grid-column:開始列/終了列"`（1列目はレーン名。時間軸は2列目から）
- 主役のバーだけ `.on`（濃紺）。マイルストーンは `.rm-ms` で `◆ 名称`（絵文字は使わない）

```html
<div class="fig-scroll"><div class="roadmap">
  <div class="rm-row rm-head">
    <div class="rm-lane"></div>
    <div class="rm-h">10月</div><div class="rm-h">11月</div><div class="rm-h">12月</div>
    <div class="rm-h">1Q</div><div class="rm-h">2Q</div><div class="rm-h">3Q</div>
  </div>
  <div class="rm-row">
    <div class="rm-lane">前提条件の充足</div>
    <div class="rm-bar" style="grid-column:2/4">採用契約・意向表明</div>
  </div>
  <div class="rm-row">
    <div class="rm-lane">投資判断</div>
    <div class="rm-ms" style="grid-column:4">◆ 最終判断</div>
  </div>
  <div class="rm-row">
    <div class="rm-lane">拠点立ち上げ</div>
    <div class="rm-bar on" style="grid-column:5/7">改修→稼働</div>
  </div>
</div></div>
```

**フレームワーク表（`.matrix`）— 左に濃色ラベル、中身は余白で整列**
- コンサル頻出の「左端に濃色ボックス＝行ラベル、右に等間隔の列」を再現する型（論点一覧・比較表・ステージ表）
- **塗るのは左の行ラベルと（あれば）目標ステージの列見出しだけ。** 中身のセルには枠も背景も付けず、
  gridの余白だけで行・列が揃って見える状態を作る。「箱を並べた感」を出さないことが本体
- 列は等幅（1fr）。列数は `--mx-cols`、ラベル幅は `--mx-label` で調整。セルは短文か「–」の箇条書き
- 濃紺の主役は1つの図で1系統まで。行ラベルを濃紺にしたらステージ見出しはグレー、
  目標ステージを濃紺 `.on` にしたら行ラベルは `.alt`（グレー）に落とす
- 使い分け: **数値の比較は `table`、文章・観点の比較は `.matrix`**

```html
<div class="fig-scroll"><div class="matrix"><!-- 列数は --mx-cols で変更（既定2列） -->
  <div class="mx-h"></div>
  <div class="mx-h">想定される影響</div>
  <div class="mx-h">対応方針</div>
  <div class="mx-label"><small>01</small>倉庫人員の未充足</div>
  <div class="mx-cell">立ち上げ遅延（最大12ヶ月）</div>
  <div class="mx-cell"><b>着手前に</b>採用パートナー2社と契約</div>
</div></div>
```

ステージ比較にする場合は、列見出しを矢羽根にする（先頭は `.first`、目標ステージだけ `.on`）:

```html
<div class="matrix" style="--mx-cols:4;--mx-label:96px">
  <div></div>
  <div class="mx-h stage first"><small>STAGE 0</small>参入準備</div>
  <div class="mx-h stage"><small>STAGE 1</small>単拠点稼働</div>
  <div class="mx-h stage on"><small>STAGE 2</small>面展開</div>
  <div class="mx-h stage"><small>STAGE 3</small>全国基盤化</div>
  <div class="mx-label alt">顧客</div>
  <div class="mx-cell">…</div><div class="mx-cell">…</div>
  <div class="mx-cell">…</div><div class="mx-cell">…</div>
</div>
```

**バブルマップ（SVG）**
- 軸は左と下の2本＋矢じり、中央に淡い十字ガイドのみ。象限の塗り分けはしない
- バブルは脇役グレー（`opacity:.85`）、当社・主役だけ濃紺。名前はバブル内か直近に直接ラベル
- 大きさの意味（売上規模など）は出所行で説明する。サイズ凡例は作らない

**ウォーターフォール（SVG）**
- 減=レンガ色（`▲`表記）、増=濃紺、合計=黒。バーの間は運用レベルを細いグレー線でつなぐ
- ゼロラインを細罫で引き、数値は各バーの外側に直接ラベル。Y軸目盛は不要

**折れ線（SVG）**
- 主役1本だけ濃紺（太め2.5px）、比較線はグレー（2px）。凡例ではなく**線の右端に系列名＋最新値**
- 予測期間は `stroke-dasharray` の破線で切り替え、出所行に「点線は予測」と明記
- 水平グリッドは3本程度の淡いグレーまで。縦グリッドは引かない

**注記・出所**
- データを見せたら `.src`（出所）を必ず添える。推計なら推計と書く
- 補足は `.note`（グレーの細い左罫）。色付き警告ボックスにしない

## 手順

1. 用途を判定する（報告書／分析メモ／提案書…）。指定があればアクセント1色だけクライアントカラーに差し替える。確認のための質問はせず、既定（濃紺）で進めてよい
2. 内容を骨格に流し込む（サマリー→番号付きセクション→推奨アクション）
3. 上記CSSを**改変せずそのまま**使う（足してよいのはレイアウト微調整のみ。新しい色・枠・影は足さない）
4. 出力前に下の品質チェックを通す

## 品質チェック（出力前）

- [ ] 枠線で囲んだカードが**0個**（罫線は「水平の罫」「注記・KPIの縦罫」のみ）
- [ ] 使用色がインク系＋アクセント1色に収まっている（3色目が出たら削る）
- [ ] グラデ0・影0・絵文字0・角丸0
- [ ] 本文は左揃え、1行の長さは42em以下
- [ ] 各セクションに `.msg`（メッセージライン）がある
- [ ] 数字は右揃え・桁区切り・単位明記、表に出所がある
- [ ] 図解が型（矢羽根・ロードマップ・フレームワーク表・バブル・ウォーターフォール・折れ線・横棒）に沿っており、
      配色は脇役グレー＋主役の濃紺（負値のみレンガ色）、凡例ボックスなしの直接ラベルになっている
- [ ] フレームワーク表で塗っているのは行ラベル（＋目標ステージ）だけで、中身のセルは枠なし・背景なし
- [ ] 印刷プレビュー（A4）で表・図が泣き別れしない

## トーン

- 簡潔、実務。装飾で盛らず、余白と階層で読ませる
- 完成見本: `assets/report.template.html`（ブラウザで開けばそのまま確認できる）
