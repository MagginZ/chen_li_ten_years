"""
FastAPI backend for 果实 - Music Playlist API
使用网易云音乐 (pyncm) 获取陈粒歌单及直接音频播放链接

参考 pyncm 文档: https://github.com/mos9527/pyncm
- 海外用户需设置 X-Real-IP 避免 460 Cheating
- GetTrackAudio 需先匿名登录
"""
import asyncio
from concurrent.futures import ThreadPoolExecutor
from contextlib import asynccontextmanager
from typing import List, Dict, Any
from urllib.parse import urlparse

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response, StreamingResponse
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

NCM_TIMEOUT_SEC = 12  # pyncm 调用超时
PAGE_SIZE_DEFAULT = 20

# 代理网易云请求时伪装浏览器（与 App 端防盗链说明一致）
_NCM_PROXY_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
    "Referer": "https://music.163.com/",
}


def _allowed_proxy_url(url: str, *, kind: str) -> bool:
    """防止开放代理：仅允许常见网易云 CDN / 占位图域名。"""
    try:
        p = urlparse(url.strip())
        if p.scheme not in ("http", "https") or not p.hostname:
            return False
        host = p.hostname.lower()
        if kind == "audio":
            return "126.net" in host or "163.com" in host
        # image: 网易封面 + mock 占位
        return (
            "126.net" in host
            or "163.com" in host
            or host.endswith("picsum.photos")
        )
    except Exception:
        return False


@asynccontextmanager
async def _lifespan(app: FastAPI):
    timeout = httpx.Timeout(120.0, connect=30.0)
    async with httpx.AsyncClient(timeout=timeout, follow_redirects=True) as client:
        app.state.http_client = client
        yield


app = FastAPI(title="果实 Music API", version="1.0.0", lifespan=_lifespan)

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


def _fetch_from_ncm_sync(keyword: str, limit: int, offset: int) -> List[PlaylistItem]:
    """从网易云音乐搜索歌单（同步，可能较慢）"""
    if not PYNCM_AVAILABLE:
        return []

    try:
        _configure_pyncm_session()
        _ensure_login()

        # 1. 搜索（支持任意歌手/关键词）
        search = GetSearchResult(keyword, stype=SONG, limit=limit, offset=offset)
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
            # Android 9+ 默认禁止明文 HTTP；网易云 CDN 通常同时支持 HTTPS
            if url.startswith("http://"):
                url = "https://" + url[7:]
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
async def get_playlist(keyword: str = "陈粒", limit: int = PAGE_SIZE_DEFAULT, offset: int = 0):
    """
    GET /api/playlist?keyword=xxx&limit=20&offset=0
    搜索任意歌手/关键词，支持分页。
    """
    loop = asyncio.get_running_loop()
    try:
        items = await asyncio.wait_for(
            loop.run_in_executor(
                _executor,
                lambda: _fetch_from_ncm_sync(keyword, limit, offset),
            ),
            timeout=NCM_TIMEOUT_SEC,
        )
    except asyncio.TimeoutError:
        print("[pyncm] Timeout")
        items = []

    if not items and offset == 0 and keyword == "陈粒":
        items = _get_mock_playlist()
    return items


@app.get("/health")
async def health():
    return {"status": "ok", "service": "neon-pulse-music-api", "source": "ncm"}


@app.get("/api/proxy/audio")
async def proxy_audio(request: Request, url: str):
    """
    代理音频流：服务端带网易云防盗链头拉取 CDN，再流式转给 Flutter（手机不直连网易 CDN）。
    用法: GET /api/proxy/audio?url=<encodeURIComponent(原始 streamUrl)>
    """
    if not url or not url.strip():
        raise HTTPException(status_code=400, detail="missing url")
    if not _allowed_proxy_url(url, kind="audio"):
        raise HTTPException(status_code=400, detail="url not allowed for audio proxy")

    client: httpx.AsyncClient = request.app.state.http_client

    async def stream():
        async with client.stream("GET", url, headers=_NCM_PROXY_HEADERS) as r:
            if r.status_code >= 400:
                raise HTTPException(status_code=502, detail=f"upstream {r.status_code}")
            async for chunk in r.aiter_bytes():
                yield chunk

    return StreamingResponse(
        stream(),
        media_type="audio/mpeg",
        headers={"Cache-Control": "no-store"},
    )


@app.get("/api/proxy/image")
async def proxy_image(request: Request, url: str):
    """
    代理封面图：同上，破解防盗链；占位图域名亦在白名单内。
    封面体积通常较小，整包缓冲可避免流式与 async with 生命周期问题。
    """
    if not url or not url.strip():
        raise HTTPException(status_code=400, detail="missing url")
    if not _allowed_proxy_url(url, kind="image"):
        raise HTTPException(status_code=400, detail="url not allowed for image proxy")

    client: httpx.AsyncClient = request.app.state.http_client
    r = await client.get(url, headers=_NCM_PROXY_HEADERS)
    if r.status_code >= 400:
        raise HTTPException(
            status_code=502,
            detail=f"upstream {r.status_code}",
        )
    media_type = r.headers.get("content-type", "image/jpeg")
    return Response(
        content=r.content,
        media_type=media_type,
        headers={"Cache-Control": "public, max-age=3600"},
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
