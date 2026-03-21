# Neon Pulse Music API

FastAPI 后端，为 Flutter 应用提供歌单接口。搜索 **陈粒 (Chen Li)** 音乐。

## 环境

- Python 3.10+
- FastAPI, uvicorn, ytmusicapi

## 安装

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

## 运行

```bash
# 开发模式（自动重载）
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# 或
python main.py
```

- 服务地址: `http://0.0.0.0:8000`
- 同一局域网内 iPhone: `http://<你的电脑IP>:8000`

## 接口

### GET /api/playlist

返回歌单列表。

**响应**:
```json
[
  {
    "id": "uuid",
    "title": "小半",
    "artist": "陈粒",
    "coverUrl": "https://...",
    "streamUrl": "https://...",
    "duration_ms": 256000
  }
]
```

### GET /health

健康检查。

## CORS

已配置 `allow_origins=["*"]`，支持跨域访问。

## 数据源

- **ytmusicapi**: 搜索「陈粒」获取实时数据；封面优先使用高分辨率
- **Mock**: 当 ytmusicapi 不可用或限流时，返回内置陈粒歌单
