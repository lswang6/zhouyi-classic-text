#!/usr/bin/env python3
"""用 Codex CLI（gpt-image）批量出水墨画：python3 tools/art/gen.py <raw 输出目录> [批次号…]
缺的图每 PER 张一个 codex 会话（会话常在 3–5 分钟后断，批小损失小），最多 MAX 个同时跑
（ChatGPT 网页后端限 5 个并发，且并发高时易断，取 2）。
已存在的 <name>.png 跳过；图由 harvest.py 从会话日志收（带 [name] 标签）。风格以 tools/art/reference.png 为准。"""
import json, pathlib, subprocess, sys, time

HERE = pathlib.Path(__file__).resolve().parent
spec = json.loads((HERE / "prompts.json").read_text())
raw = pathlib.Path(sys.argv[1]).resolve()
pick = {int(a) for a in sys.argv[2:]}
MAX = 2
PER = 2

procs, running = [], []
missing = [n for n in spec["images"] if not (raw / f"{n}.png").exists()]
for bi, todo in enumerate(missing[i:i + PER] for i in range(0, len(missing), PER)):
    if pick and bi not in pick:
        continue
    wd = raw / f"b{bi:02d}"
    wd.mkdir(parents=True, exist_ok=True)
    items = "\n".join(f"- [{n}] aspect {spec['images'][n][0]}: {spec['images'][n][1]}" for n in todo)
    prompt = (f"Use your image generation tool to create {len(todo)} separate images, one per line below, one tool call each. "
              f"IMPORTANT: begin every image-generation prompt with the exact tag in square brackets shown for that line "
              f"(e.g. \"[gua-01] ...\"), then the full description. Do NOT copy, move, rename or look for the generated files; "
              f"harvest.py collects them. Generate each image exactly once; only retry if the tool returns an error. Style for every image: {spec['style']}\n\n{items}\n\n"
              f"When all are done, reply 'done'.")
    while len(running) >= MAX:   # 等出一个空位
        running = [p for p in running if p.poll() is None]
        if len(running) >= MAX:
            time.sleep(5)
    log = open(wd / "codex.log", "w")
    procs.append((bi, subprocess.Popen(
        ["codex", "exec", "--skip-git-repo-check", "-s", "workspace-write", "-C", str(wd),
         "-i", str(HERE / "reference.png"), "-o", str(wd / "reply.txt"), prompt],
        stdout=log, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)))
    running.append(procs[-1][1])
    print(f"batch {bi}: {len(todo)} images", flush=True)

for bi, p in procs:
    print(f"batch {bi} exit {p.wait()}", flush=True)
missing = [n for n in spec["images"] if not (raw / f"{n}.png").exists()]
print("missing:", missing or "none")
