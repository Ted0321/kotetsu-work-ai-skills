/**
 * A-4「チャート試着室」の紹介動画を無人で収録する。
 *
 *   node record.js        →  out/chart-fitting-room.mp4 (1280x720 / H.264 / 約45秒)
 *
 * ⚠ shell.html は Claude Code デスクトップアプリの画面を模した「再現」であり、
 *   実セッションのキャプチャではない。パネルの中身（demo-op-profit.html）だけが本物。
 *   投稿で使う際は、この点を踏まえて扱うこと。
 */
const { chromium } = require('/opt/node22/lib/node_modules/playwright');
const { spawn, execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const STAGE = __dirname;                      // shell.html と demo-op-profit.html を置く場所
const OUTDIR = path.join(__dirname, 'out');
// H.264 が使える ffmpeg。Playwright 同梱のものは VP8/webm しか吐けないので使わない
//   pip install imageio-ffmpeg  →  python3 -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"
const FFMPEG = process.env.FFMPEG ||
  '/usr/local/lib/python3.11/dist-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2';
const PORT = 8931;
const W = 1280, H = 720;

(async () => {
  fs.rmSync(OUTDIR, { recursive: true, force: true });
  fs.mkdirSync(OUTDIR, { recursive: true });

  // iframe を同一オリジンにするため http で配信する（file:// だとクロスオリジンになる）
  const srv = spawn('python3', ['-m', 'http.server', String(PORT), '--bind', '127.0.0.1'],
    { cwd: STAGE, stdio: 'ignore' });
  await new Promise(r => setTimeout(r, 900));

  const browser = await chromium.launch({ channel: 'chromium', args: ['--force-device-scale-factor=1'] });
  const ctx = await browser.newContext({
    viewport: { width: W, height: H },
    colorScheme: 'light',                 // パネル内の成果物はライトで固定
    deviceScaleFactor: 2,                 // 文字の輪郭を出す
    recordVideo: { dir: OUTDIR, size: { width: W, height: H } },
  });
  const page = await ctx.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push('PAGEERROR: ' + e.message));
  page.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });

  await page.goto(`http://127.0.0.1:${PORT}/shell.html`, { waitUntil: 'networkidle' });

  // 演出スクリプトが自分で完了を知らせるまで待つ
  const t0 = Date.now();
  await page.waitForFunction(() => document.title === 'DONE', null, { timeout: 120000 });
  const secs = ((Date.now() - t0) / 1000).toFixed(1);

  await ctx.close();
  await browser.close();
  srv.kill();

  const webm = fs.readdirSync(OUTDIR).find(f => f.endsWith('.webm'));
  const src = path.join(OUTDIR, webm);
  const mp4 = path.join(OUTDIR, 'chart-fitting-room.mp4');

  // X で確実に再生される形へ（H.264 / yuv420p / faststart、偶数解像度）
  execFileSync(FFMPEG, [
    '-y', '-i', src,
    '-c:v', 'libx264', '-preset', 'slow', '-crf', '20',
    '-pix_fmt', 'yuv420p', '-profile:v', 'high', '-level', '4.0',
    '-movflags', '+faststart',
    '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=30',
    '-an', mp4,
  ], { stdio: ['ignore', 'ignore', 'pipe'] });

  const st = fs.statSync(mp4);
  console.log(`収録 ${secs}s / webm ${(fs.statSync(src).size / 1e6).toFixed(2)}MB`);
  console.log(`mp4  ${mp4}  ${(st.size / 1e6).toFixed(2)}MB`);
  console.log('errors:', errs.length ? errs : 'none');
})();
