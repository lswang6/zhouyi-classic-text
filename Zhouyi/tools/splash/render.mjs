// node render.mjs            -> full render of both variants, encode mp4s, contact sheets
// node render.mjs --preview  -> only the 4 contact-sheet frames (fast look-dev loop)
import { chromium } from 'playwright-core';
import { mkdirSync, writeFileSync, rmSync, statSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const appDir = path.resolve(here, '../../Zhouyi');
const FFMPEG = '/opt/homebrew/bin/ffmpeg';
const FPS = 30, N = 66; // 2.2s
const SHEET = [15, 30, 45, 51]; // 0.5s 1.0s 1.5s 1.7s
const CRF = process.env.CRF || '20';
const preview = process.argv.includes('--preview');

const browser = await chromium.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' });
const page = await browser.newPage();
await page.goto(pathToFileURL(path.join(here, 'index.html')).href);

for (const variant of ['light', 'dark']) {
  const dir = path.join(here, 'frames', variant);
  rmSync(dir, { recursive: true, force: true }); mkdirSync(dir, { recursive: true });
  const info = await page.evaluate(v => init(v), variant);
  console.log(variant, 'seal font:', info.sealFont ?? 'none (textured block)');
  for (const n of preview ? SHEET : [...Array(N).keys()]) {
    const url = await page.evaluate(t => { renderFrame(t); return document.getElementById('c').toDataURL('image/png'); }, n / FPS);
    writeFileSync(path.join(dir, String(n).padStart(3, '0') + '.png'), Buffer.from(url.split(',')[1], 'base64'));
  }
  const f = n => path.join(dir, String(n).padStart(3, '0') + '.png');
  execFileSync(FFMPEG, ['-y', '-loglevel', 'error', ...SHEET.flatMap(n => ['-i', f(n)]),
    '-filter_complex', SHEET.map((_, i) => `[${i}]scale=444:960[s${i}]`).join(';') + ';' + SHEET.map((_, i) => `[s${i}]`).join('') + 'hstack=4',
    path.join(here, `contact-${variant}.png`)]);
  if (preview) continue;
  const out = path.join(appDir, `splash-${variant}.mp4`);
  execFileSync(FFMPEG, ['-y', '-loglevel', 'error', '-framerate', String(FPS), '-i', path.join(dir, '%03d.png'),
    '-vf', 'scale=out_color_matrix=bt709:out_range=tv,format=yuv420p',
    '-c:v', 'libx264', '-profile:v', 'high', '-preset', 'veryslow', '-crf', CRF, '-force_key_frames', 'expr:eq(n,61)',
    '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-color_range', 'tv',
    '-movflags', '+faststart', '-an', out]);
  console.log(out, (statSync(out).size / 1024).toFixed(0) + 'KB');
}
await browser.close();
