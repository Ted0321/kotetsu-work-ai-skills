/**
 * 試着室で選んだチャートを、PowerPoint のネイティブチャートとしてスライドに起こす。
 *
 *   node to-pptx.js [出力先.pptx]
 *
 * 画像の貼り付けではなく addChart() を使うので、PowerPoint 側で
 * 数値の編集・色の変更・アニメーション付けがそのままできる。
 */
const path = require('path');
const pptxgen = require('pptxgenjs');

/* ---------- 試着室と同じデータ ---------- */
const PRODUCTS = [
  { id: 'X', name: '主力X', color: '2A78D6', y: [480, 440, 390] },
  { id: 'Z', name: '定番Z', color: 'EDA100', y: [320, 325, 330] },
  { id: 'Y', name: '新規Y', color: '008300', y: [60, 150, 280] },
  { id: 'W', name: '撤退W', color: 'E87BA4', y: [140, 95, 50] },
];
const TOTAL0 = PRODUCTS.reduce((s, p) => s + p.y[0], 0);
const TOTAL2 = PRODUCTS.reduce((s, p) => s + p.y[2], 0);

const INK = '0B0B0B', INK2 = '52514E', MUTED = '898781', GRID = 'E1E0D9';
const UP = '2A78D6', DOWN = 'E34948', TOTAL = '52514E';
const FONT = 'Meiryo';
const nf = n => Math.abs(n).toLocaleString('en-US');
const signed = n => (n >= 0 ? '+' : '−') + nf(n);

const pres = new pptxgen();
pres.layout = 'LAYOUT_WIDE';           // 13.3 × 7.5 inch — レイアウトはスライド追加より先に
pres.author = 'チャート試着室';
pres.title = '製品ポートフォリオ';

/** メッセージライン＋出所という、コンサル資料の基本形 */
function contentSlide(message, kicker, source) {
  const s = pres.addSlide();
  s.background = { color: 'FFFFFF' };
  s.addText(kicker, {
    x: 0.62, y: 0.36, w: 12.1, h: 0.26, margin: 0,
    fontFace: FONT, fontSize: 11, color: MUTED, charSpacing: 1.4,
  });
  s.addText(message, {
    x: 0.62, y: 0.62, w: 12.1, h: 0.92, margin: 0,
    fontFace: FONT, fontSize: 25, bold: true, color: INK, valign: 'top',
  });
  s.addText(source, {
    x: 0.62, y: 6.92, w: 9, h: 0.28, margin: 0,
    fontFace: FONT, fontSize: 10, color: MUTED,
  });
  return s;
}

/* ================================================================
   スライド1 — 表紙
   ================================================================ */
{
  const s = pres.addSlide();
  s.background = { color: '1A1A19' };
  s.addText('同じデータ、10の見せ方', {
    x: 0.9, y: 2.5, w: 11, h: 0.4, margin: 0,
    fontFace: FONT, fontSize: 13, color: '898781', charSpacing: 2,
  });
  s.addText('製品ポートフォリオの現状と、次の一手', {
    x: 0.9, y: 2.95, w: 11.5, h: 1.1, margin: 0,
    fontFace: FONT, fontSize: 36, bold: true, color: 'FFFFFF',
  });
  s.addText('全社売上は3年で+5%。ただし、その中身は入れ替わっている。', {
    x: 0.9, y: 4.1, w: 11, h: 0.4, margin: 0,
    fontFace: FONT, fontSize: 15, color: 'C3C2B7',
  });
  s.addNotes('試着室で「現場に危機感を伝える」「経営会議で現状報告する」を選んだ結果を、この2枚に落としている。');
}

/* ================================================================
   スライド2 — スロープグラフ（現場に危機感を伝える）
   ================================================================ */
{
  const s = contentSlide(
    '主力Xと新規Yの売上は、3年で交差寸前まで来ている',
    '現場共有 · 製品別売上の3年変化',
    '出所: 社内販売実績（2023–2025年、単位: 百万円）'
  );
  s.addChart(
    pres.ChartType.line,
    PRODUCTS.map(p => ({ name: p.name, labels: ['2023年', '2025年'], values: [p.y[0], p.y[2]] })),
    {
      x: 1.5, y: 1.75, w: 10.3, h: 4.95,
      chartColors: PRODUCTS.map(p => p.color),
      lineSize: 2.5, lineDataSymbol: 'circle', lineDataSymbolSize: 9,
      showTitle: true, title: '製品別売上（百万円）',
      titleFontFace: FONT, titleFontSize: 12, titleColor: INK2, titleAlign: 'left',
      showValue: true, dataLabelPosition: 'r',
      dataLabelFontFace: FONT, dataLabelFontSize: 11, dataLabelColor: INK,
      dataLabelFormatCode: '#,##0',
      showLegend: true, legendPos: 'b', legendFontFace: FONT, legendFontSize: 11,
      legendColor: INK2,
      catAxisLabelFontFace: FONT, catAxisLabelFontSize: 12, catAxisLabelColor: MUTED,
      valAxisLabelFontFace: FONT, valAxisLabelFontSize: 11, valAxisLabelColor: MUTED,
      valAxisMinVal: 0, valAxisMaxVal: 600, valAxisMajorUnit: 200,
      valGridLine: { color: GRID, size: 1 },
      catGridLine: { style: 'none' },
      catAxisLineShow: false, valAxisLineShow: false,
    }
  );
  s.addNotes('数字を追わせず一撃で伝えたい場面。落差が最も残酷に見える形式。');
}

/* ================================================================
   スライド3 — ウォーターフォール（経営会議で現状報告する）
   PowerPoint に滝グラフは無いので、透明の土台を積み上げて作る
   ================================================================ */
{
  const s = contentSlide(
    '全社+50の内訳は、主力Xの−90を新規Yの+220が埋めた結果',
    '経営会議 · 2023年から2025年への増減分解',
    '出所: 社内販売実績（2023–2025年、単位: 百万円）'
  );

  // 各バーの足元の高さ（土台）と、そこから伸びる量を求める
  const cats = [], base = [], totals = [], ups = [], downs = [];
  cats.push(`2023年  ${nf(TOTAL0)}`);
  base.push(0); totals.push(TOTAL0); ups.push(0); downs.push(0);

  let run = TOTAL0;
  for (const p of PRODUCTS) {
    const d = p.y[2] - p.y[0];
    cats.push(`${p.name} ${signed(d)}`);
    base.push(Math.min(run, run + d));
    totals.push(0);
    ups.push(d > 0 ? d : 0);
    downs.push(d < 0 ? -d : 0);
    run += d;
  }
  cats.push(`2025年  ${nf(run)}`);
  base.push(0); totals.push(run); ups.push(0); downs.push(0);

  s.addChart(
    pres.ChartType.bar,
    [
      { name: '土台',     labels: cats, values: base },   // 背景色 = 見えない
      { name: '合計',     labels: cats, values: totals },
      { name: '増益要因', labels: cats, values: ups },
      { name: '減益要因', labels: cats, values: downs },
    ],
    {
      x: 1.1, y: 1.75, w: 11.1, h: 4.9,
      barDir: 'col', barGrouping: 'stacked', barGapWidthPct: 140,
      chartColors: ['FFFFFF', TOTAL, UP, DOWN],
      showTitle: true, title: '営業ベース売上の増減（百万円）',
      titleFontFace: FONT, titleFontSize: 12, titleColor: INK2, titleAlign: 'left',
      showValue: false,                       // 土台の数値まで出てしまうため軸名に持たせる
      showLegend: false,                      // 「土台」が凡例に出てしまうので自前で置く
      catAxisLabelFontFace: FONT, catAxisLabelFontSize: 11, catAxisLabelColor: INK2,
      valAxisLabelFontFace: FONT, valAxisLabelFontSize: 11, valAxisLabelColor: MUTED,
      valAxisMinVal: 0, valAxisMaxVal: 1200, valAxisMajorUnit: 300,
      valGridLine: { color: GRID, size: 1 },
      catGridLine: { style: 'none' },
      catAxisLineShow: false, valAxisLineShow: false,
    }
  );

  // 自前の凡例（土台を隠すため chart の凡例は切っている）
  [['増益要因', UP, 9.35], ['減益要因', DOWN, 10.85]].forEach(([label, color, x]) => {
    s.addShape(pres.ShapeType.rect, {
      x, y: 1.52, w: 0.13, h: 0.13, fill: { color }, line: { color, width: 0 },
    });
    s.addText(label, {
      x: x + 0.2, y: 1.42, w: 1.2, h: 0.32, margin: 0,
      fontFace: FONT, fontSize: 11, color: INK2,
    });
  });

  s.addNotes('「全社は横ばい」で終わらせないための1枚。増えた分と減った分を並べて中身を説明する。');
}

const out = process.argv[2] || path.join(__dirname, 'portfolio.pptx');
pres.writeFile({ fileName: out }).then(f => console.log('wrote', f));
