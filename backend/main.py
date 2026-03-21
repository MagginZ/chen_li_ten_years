"""
FastAPI backend for Neon Pulse - Music Playlist API
使用网易云音乐 (pyncm) 获取陈粒歌单及直接音频播放链接

参考 pyncm 文档: https://github.com/mos9527/pyncm
- 海外用户需设置 X-Real-IP 避免 460 Cheating
- GetTrackAudio 需先匿名登录
"""
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor
from typing import List, Dict, Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# pyncm: 网易云音乐 Python API
try:
    from pyncm import GetCurrentSession
    from pyncm.apis.cloudsearch import GetSearchResult, SONG
    from pyncm.apis.login import LoginViaAnonymousAccount
    from pyncm.apis.track import GetTrackAudio
    PYNCM_AVAILABLE = True
except ImportError:
    PYNCM_AVAILABLE = False

# 线程池，避免阻塞事件循环
_executor = ThreadPoolExecutor(max_workers=2)

# 歌单缓存，减少对网易云 API 的频繁请求
_playlist_cache: List[Dict[str, Any]] = []
_cache_time: float = 0
CACHE_TTL_SEC = 300  # 5 分钟
NCM_TIMEOUT_SEC = 12  # pyncm 调用超时


app = FastAPI(title="Neon Pulse Music API", version="1.0.0")

# CORS: allow all origins for Flutter app (web, iOS, Android)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class PlaylistItem(BaseModel):
    id: str
    title: str
    artist: str
    coverUrl: str
    streamUrl: str
    duration_ms: int


# Mock data: 陈粒 - 当 pyncm 不可用或失败时兜底
MOCK_PLAYLIST: List[Dict[str, Any]] = [
    {"id": "cl-1", "title": "小半", "artist": "陈粒", "coverUrl": "https://picsum.photos/512/512?random=1", "streamUrl": "", "duration_ms": 256000},
    {"id": "cl-2", "title": "奇妙能力歌", "artist": "陈粒", "coverUrl": "https://picsum.photos/512/512?random=2", "streamUrl": "", "duration_ms": 243000},
    {"id": "cl-3", "title": "易燃易爆炸", "artist": "陈粒", "coverUrl": "https://picsum.photos/512/512?random=3", "streamUrl": "", "duration_ms": 198000},
    {"id": "cl-4", "title": "走马", "artist": "陈粒", "coverUrl": "https://picsum.photos/512/512?random=4", "streamUrl": "", "duration_ms": 231000},
    {"id": "cl-5", "title": "历历万乡", "artist": "陈粒", "coverUrl": "https://picsum.photos/512/512?random=5", "streamUrl": "", "duration_ms": 278000},
]


def _configure_pyncm_session():
    """配置 pyncm Session：海外用户需 X-Real-IP 避免 460 Cheating"""
    if not PYNCM_AVAILABLE:
        return
    try:
        session = GetCurrentSession()
        session.headers["X-Real-IP"] = "118.88.88.88"
    except Exception as e:
        print(f"[pyncm] Session config: {e}")


def _ensure_login():
    """确保已匿名登录，GetTrackAudio 需要登录才能拿到音频 URL"""
    if not PYNCM_AVAILABLE:
        return
    try:
        LoginViaAnonymousAccount()
        print("[pyncm] Anonymous login OK")
    except Exception as e:
        print(f"[pyncm] Login failed: {e}")


def _fetch_from_ncm_sync() -> List[PlaylistItem]:
    """从网易云音乐获取陈粒歌单（同步，可能较慢）"""
    if not PYNCM_AVAILABLE:
        return []

    try:
        _configure_pyncm_session()
        _ensure_login()

        # 1. 搜索陈粒歌曲
        search = GetSearchResult("陈粒", stype=SONG, limit=10, offset=0)
        songs = (search.get("result") or {}).get("songs") or []
        if not songs:
            return []

        # 2. 批量获取音频 URL（网易云返回直接可播放的 mp3/m4a 链接）
        song_ids = [s["id"] for s in songs]
        audio_resp = GetTrackAudio(song_ids)
        url_map: Dict[int, str] = {}
        for item in (audio_resp.get("data") or []):
            uid = item.get("id")
            url = (item.get("url") or "").strip()
            if uid and url:
                url_map[uid] = url

        # 3. 构建 PlaylistItem
        items: List[PlaylistItem] = []
        for s in songs:
            sid = s.get("id")
            stream_url = url_map.get(sid, "") if sid else ""
            # 若无版权或未获取到 URL，跳过该曲（不加入列表）
            if not stream_url:
                continue

            artists = s.get("ar") or []
            artist = artists[0].get("name", "陈粒") if artists else "陈粒"
            al = s.get("al") or {}
            cover_url = (al.get("picUrl") or "").replace("http://", "https://")
            if not cover_url:
                cover_url = f"https://picsum.photos/512/512?random={sid}"
            duration_ms = s.get("dt") or 240000
            if duration_ms > 1000000:  # 若单位是微秒
                duration_ms = duration_ms // 1000

            items.append(
                PlaylistItem(
                    id=str(sid),
                    title=s.get("name") or "Unknown",
                    artist=artist,
                    coverUrl=cover_url or "https://picsum.photos/512/512",
                    streamUrl=stream_url,
                    duration_ms=int(duration_ms),
                )
            )
        return items
    except Exception as e:
        print(f"[pyncm] Fallback to mock: {e}")
        return []


def _get_mock_playlist() -> List[PlaylistItem]:
    """返回 mock 歌单（无真实播放链接）"""
    return [
        PlaylistItem(
            id=m["id"],
            title=m["title"],
            artist=m["artist"],
            coverUrl=m["coverUrl"],
            streamUrl=m["streamUrl"],
            duration_ms=m["duration_ms"],
        )
        for m in MOCK_PLAYLIST
    ]


@app.get("/api/playlist", response_model=List[PlaylistItem])
async def get_playlist():
    """
    GET /api/playlist
    返回陈粒歌单。使用缓存与超时控制，避免 pyncm 阻塞。
    """
    global _playlist_cache, _cache_time

    # 1. 缓存命中
    if _playlist_cache and (time.time() - _cache_time) < CACHE_TTL_SEC:
        return [PlaylistItem(**x) for x in _playlist_cache]

    # 2. 在线程池中执行，带超时
    loop = asyncio.get_running_loop()
    try:
        items = await asyncio.wait_for(
            loop.run_in_executor(_executor, _fetch_from_ncm_sync),
            timeout=NCM_TIMEOUT_SEC,
        )
    except asyncio.TimeoutError:
        print("[pyncm] Timeout, using mock")
        items = []

    if not items:
        items = _get_mock_playlist()
    else:
        _playlist_cache = [i.model_dump() for i in items]
        _cache_time = time.time()

    return items


@app.get("/health")
async def health():
    return {"status": "ok", "service": "neon-pulse-music-api", "source": "ncm"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
