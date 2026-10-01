#!/usr/bin/env python3
"""从 Codex 会话日志收图：python3 tools/art/harvest.py <raw 目录> [--since YYYY-MM-DD]
~/.codex/generated_images/<会话id>/<imagegen 调用id>.png 与会话日志里该调用的 prompt 一一对应，
prompt 以 [name] 开头（gen.py 要求）即精确归名；旧会话无标签时按场景描述词重合度归名（需唯一且足够高）。
同名多张取最新。不靠 Codex 自己拷（并行时它会拿到别的会话的图）。"""
import json, pathlib, re, shutil, sys

HERE = pathlib.Path(__file__).resolve().parent
spec = json.loads((HERE / "prompts.json").read_text())
raw = pathlib.Path(sys.argv[1]).resolve()
since = sys.argv[sys.argv.index("--since") + 1] if "--since" in sys.argv else "2026-09-29"
CODEX = pathlib.Path.home() / ".codex"
words = lambda s: set(re.findall(r"[a-z]{4,}", s.lower())) - {"with", "from", "into", "over", "under", "beside", "their", "very", "soft", "small"}
scenes = {n: words(v[1]) for n, v in spec["images"].items()}


def name_for(prompt):
    if m := re.match(r"\s*\[([a-z0-9-]+)\]", prompt):
        return m.group(1) if m.group(1) in spec["images"] else None
    w = words(prompt)
    ranked = sorted(((len(w & s) / len(s), n) for n, s in scenes.items()), reverse=True)
    (best, n), (second, _) = ranked[0], ranked[1]
    return n if best >= 0.6 and best - second >= 0.2 else None


found = {}   # name -> (mtime, path)
for log in sorted((CODEX / "sessions").rglob("rollout-*.jsonl")):
    if log.stat().st_mtime < __import__("datetime").datetime.fromisoformat(since).timestamp():
        continue
    sid = re.search(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.jsonl$", log.name)
    if not sid:
        continue
    for line in log.open():
        p = json.loads(line).get("payload", {})
        if not (isinstance(p, dict) and p.get("type") == "function_call" and p.get("name") == "imagegen"):
            continue
        img = CODEX / "generated_images" / sid.group(1) / f"{p['call_id']}.png"
        n = name_for(json.loads(p["arguments"]).get("prompt", ""))
        if n and img.exists() and img.stat().st_mtime > found.get(n, (0,))[0]:
            found[n] = (img.stat().st_mtime, img)

raw.mkdir(parents=True, exist_ok=True)
for n, (_, img) in sorted(found.items()):
    shutil.copy2(img, raw / f"{n}.png")
missing = [n for n in spec["images"] if not (raw / f"{n}.png").exists()]
print(f"harvested {len(found)}: {' '.join(sorted(found))}\nmissing {len(missing)}: {' '.join(missing)}")
