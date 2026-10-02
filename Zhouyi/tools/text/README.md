经文/传文对校脚本。依赖：`pip install opencc-python-reimplemented`。
参照本放在本目录 `ref/`（不入库）：`fetch_ws.py` 下载 Wikisource《周易》64 卦页到 `ref/ws/`；
freizl/yijing 的 `64gua.json`、`wen-yan.json`（zh-CN / zh-TW）放 `ref/freizl_*`；Kanripo KR1a0001 放 `ref/kr/`。
- `verify_text.py`：卦辞/爻辞三源对校，报告见 `docs/text-verification.md`
- `build_commentary.py [--write]`：生成 `*/Commentary.strings`，取舍见 `docs/commentary-sources.md`
- `check_commentary.py`：Commentary 表自检（键集、非空、繁简用字）
