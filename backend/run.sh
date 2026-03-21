#!/bin/bash
# 启动 Neon Pulse Music API
# 监听 0.0.0.0:8000，同一局域网 iPhone 可通过 http://<电脑IP>:8000 访问
cd "$(dirname "$0")"
source .venv/bin/activate 2>/dev/null || python3 -m venv .venv && source .venv/bin/activate
pip install -q -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
