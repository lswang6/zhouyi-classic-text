#!/usr/bin/env python3
"""把 gen.py 出的 PNG 导入资源目录：python3 tools/art/import_art.py <raw 目录>
JPEG q80 按用途定宽 → Assets.xcassets/<name>.imageset；<name>-dark 为同图深色外观，存入 <name>.imageset；app-icon → AppIcon（1024 不透明 PNG）。缺图跳过。"""
import json, pathlib, sys
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2] / "Zhouyi" / "Assets.xcassets"
raw = pathlib.Path(sys.argv[1])
WIDTH = {"home-header": 1200, "cast-backdrop": 1080, "history-empty": 800,
         **{f"header-{s}": 1200 for s in ("spring", "summer", "autumn", "winter", "night-moon", "night-stars", "night-temple")},
         **{f"kb-{s}": 1080 for s in ("origins", "yinyang", "bagua", "sixtyfour", "yao", "change", "methods", "rules", "tenwings")}}   # 其余（卦图）1024

done = []
for src in sorted(raw.glob("*.png")):
    name = src.stem
    im = Image.open(src).convert("RGB")
    if name == "app-icon":
        side = min(im.size)
        l, t = (im.width - side) // 2, (im.height - side) // 2
        im.crop((l, t, l + side, t + side)).resize((1024, 1024), Image.LANCZOS).save(ROOT / "AppIcon.appiconset/AppIcon.png")
        done.append(name)
        continue
    base = name.removesuffix("-dark")   # -dark = 同名图的深色外观（header-night-* 是独立图，不算）
    w = WIDTH.get(base, 1024)
    if im.width > w:
        im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    d = ROOT / f"{base}.imageset"
    d.mkdir(exist_ok=True)
    im.save(d / f"{name}.jpg", quality=80, optimize=True, progressive=True)
    images = [{"filename": f"{base}.jpg", "idiom": "universal"}]
    if (d / f"{base}-dark.jpg").exists():   # 先导哪张都保留深色条目
        images.append({"appearances": [{"appearance": "luminosity", "value": "dark"}],
                       "filename": f"{base}-dark.jpg", "idiom": "universal"})
    (d / "Contents.json").write_text(json.dumps({
        "images": images, "info": {"author": "xcode", "version": 1}}, indent=2))
    done.append(name)

total = sum(f.stat().st_size for f in ROOT.glob("*.imageset/*.jpg"))
print(f"imported {len(done)}: {', '.join(done)}\nimagesets total {total / 1e6:.1f} MB")
