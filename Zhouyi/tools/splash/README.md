Launch splash renderer (canvas in headless Chrome, frames at t = N/30, encoded with ffmpeg).
Re-run: `cd tools/splash && npm install && node render.mjs` (writes Zhouyi/splash-{light,dark}.mp4 and contact-{light,dark}.png; `--preview` renders only the contact-sheet frames; `CRF=20 node render.mjs` to change quality). Preview one frame in a browser: `index.html?variant=dark&t=1.2` or `?play`.
