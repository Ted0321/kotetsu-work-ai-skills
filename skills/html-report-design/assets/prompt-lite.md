# コンサル品質HTML資料 — X配布用・凝縮プロンプト

[SKILL.md（フル版）](../SKILL.md)から、コピペ1発で効く部分だけを抜いた約4,500字版。

- 使い方: 下の区切り線から先を**丸ごとAIに貼り**、末尾の「# 案件メモ」を書き替える
- フル版との差: ロードマップ・ステージ比較表・SVGチャート（滝/バブル/折れ線）の実装見本はフル版のみ

---（ここから下をコピー）---

あなたはHTMLで「そのまま配布できるコンサル品質の資料」を作る。以下を厳守する。

## 原則

- 構造は「余白と文字の階層」で作る。**線と箱で作らない**
- 区切りは余白＋横の細罫1本まで。カードUI（枠＋角丸＋影）は禁止
- 色は白＋黒グレー系＋濃紺1色だけ。グラデ・絵文字・色付き情報ボックスは禁止
- 各セクションは「見出し →言いたいこと1文（.msg）→ 根拠（表・図・本文）」の順
- 白背景・A4印刷前提。本文は左揃え

## 出力

単一HTMLファイル。下のCSSを**改変せずそのまま**使う（変えてよいのは `--accent` の1色だけ）。
構成: 表紙ブロック → エグゼクティブサマリー（結論・根拠・依頼の3点）→ 01, 02, … → 最後は「次のアクション（誰が・何を・いつまでに）」。

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
b,strong{font-weight:700}
.doc-footer{margin-top:88px;padding-top:20px;border-top:1px solid var(--hairline);font-size:11.5px;color:var(--ink-3);display:flex;justify-content:space-between;flex-wrap:wrap;gap:16px}
@media print{@page{size:A4;margin:16mm}.page{max-width:none;padding:0}table,figure,.kpis,.chevrons,.matrix{break-inside:avoid}}
```

## HTML骨格

```html
<div class="page">
  <header class="doc-header">
    <p class="eyebrow">社外秘 などの取扱い表記</p>
    <h1>結論が伝わるタイトル</h1>
    <p class="lead">何を扱い、何を決める資料かを1〜2文で。</p>
    <div class="doc-meta"><span>日付</span><span>作成部署</span><span>宛先</span></div>
  </header>
  <section>
    <h2>エグゼクティブサマリー</h2>
    <ol class="summary"><li><b>結論。</b>補足1文。</li><li><b>根拠。</b>補足1文。</li><li><b>依頼。</b>補足1文。</li></ol>
  </section>
  <section>
    <h2><span class="no">01</span>セクション見出し</h2>
    <p class="msg">このセクションで言いたいこと1文（so what）。</p>
    <!-- 根拠: .kpis / table / .chevrons / .matrix / figure -->
  </section>
  <footer class="doc-footer"><span>資料名</span><span>出所・注記</span></footer>
</div>
```

## 図解の型（自由描画しない）

- **数値の比較 = table** — 縦罫なし。数字列は `class="num"` で右揃え、単位はヘッダーに、直下に `<p class="src">出所: …</p>`
- **KPI** — `<div class="kpis"><div class="kpi"><div class="v">1,530<small>億円</small></div><div class="l">市場規模</div></div>…</div>`（箱に入れない）
- **プロセス = 矢羽根** — `<div class="chevrons"><div class="chev">工程</div><div class="chev on">主役の工程<small>補足</small></div>…</div>`（主役だけ `.on`）
- **論点×観点 = フレームワーク表** — 塗るのは左の行ラベルだけ。セルは枠も背景もなし、余白で整列させる:
  `<div class="matrix"><div class="mx-h"></div><div class="mx-h">列見出し1</div><div class="mx-h">列見出し2</div><div class="mx-label"><small>01</small>行ラベル</div><div class="mx-cell">…</div><div class="mx-cell">…</div>…</div>`（3列なら `style="--mx-cols:3"`）
- **チャートはSVG直書き** — 脇役は全部グレー `#c9ccd1`、主役の1系列だけ濃紺。凡例ボックスを作らず数値・系列名を直接ラベル。負値のみ `#a33c2e`（`▲8.0` 表記）

## 出力前チェック

- 枠で囲んだカードが0個（罫線は水平の細罫と注記の左罫のみ）
- 色が黒グレー系＋濃紺の1色に収まっている。グラデ・影・絵文字・角丸が0
- 全セクションに `.msg` がある。数字は右揃え・単位明記・出所つき

# 案件メモ

（ここに資料にしたい内容・宛先・決めたいことを書く。例: 競合3社の調査結果を経営会議向けに。市場は年12%成長、化粧品領域だけ競合が薄い。最後は条件付き参入の承認をもらう流れで）
