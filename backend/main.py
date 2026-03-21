"""
FastAPI backend for Neon Pulse - Music Playlist API
Search: Chen Li (陈粒)
"""
import uuid
from typing import Optional, List, Dict, Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Optional: ytmusicapi for real-time data
try:
    from ytmusicapi import YTMusic
    YTMUSIC_AVAILABLE = True
except ImportError:
    YTMUSIC_AVAILABLE = False


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


# Mock data: Chen Li (陈粒) - high-quality metadata for Kinetic Organicism UI
# High-res cover URLs (512px) for vibrant visual
MOCK_PLAYLIST: List[Dict[str, Any]] = [
    {
        "id": "cl-1",
        "title": "小半",
        "artist": "陈粒",
        "coverUrl": "https://picsum.photos/512/512?random=1",
        "streamUrl": "https://www.youtube.com/watch?v=placeholder1",
        "duration_ms": 256000,
    },
    {
        "id": "cl-2",
        "title": "奇妙能力歌",
        "artist": "陈粒",
        "coverUrl": "https://picsum.photos/512/512?random=2",
        "streamUrl": "https://www.youtube.com/watch?v=placeholder2",
        "duration_ms": 243000,
    },
    {
        "id": "cl-3",
        "title": "易燃易爆炸",
        "artist": "陈粒",
        "coverUrl": "https://picsum.photos/512/512?random=3",
        "streamUrl": "https://www.youtube.com/watch?v=placeholder3",
        "duration_ms": 198000,
    },
    {
        "id": "cl-4",
        "title": "走马",
        "artist": "陈粒",
        "coverUrl": "https://picsum.photos/512/512?random=4",
        "streamUrl": "https://www.youtube.com/watch?v=placeholder4",
        "duration_ms": 231000,
    },
    {
        "id": "cl-5",
        "title": "历历万乡",
        "artist": "陈粒",
        "coverUrl": "https://picsum.photos/512/512?random=5",
        "streamUrl": "https://www.youtube.com/watch?v=placeholder5",
        "duration_ms": 278000,
    },
]


def _parse_duration(duration_str: Optional[str] = None) -> int:
    """Parse '3:45' or '1:23:45' to milliseconds."""
    if not duration_str:
        return 240000  # default 4 min
    parts = duration_str.split(":")
    total_sec = 0
    for i, p in enumerate(reversed(parts)):
        try:
            total_sec += int(p) * (60**i)
        except ValueError:
            pass
    return total_sec * 1000


def _get_high_res_thumbnail(thumbnails: Optional[List[Dict[str, Any]]], video_id: str) -> str:
    """Prefer maxres/high-res thumbnail for Kinetic Organicism UI."""
    if thumbnails:
        for t in thumbnails:
            w = t.get("width", 0) or 0
            if w >= 512:
                return t.get("url", "")
        if thumbnails:
            return thumbnails[-1].get("url", "")
    return f"https://i.ytimg.com/vi/{video_id}/hqdefault.jpg"


def _fetch_from_ytmusic() -> List[PlaylistItem]:
    """Fetch Chen Li songs from YouTube Music."""
    if not YTMUSIC_AVAILABLE:
        return []

    try:
        yt = YTMusic()
        results = yt.search("陈粒", filter="songs", limit=10)
        if not results:
            results = yt.search("Chen Li", filter="songs", limit=10)

        items: List[PlaylistItem] = []
        for r in results:
            if r.get("resultType") != "song":
                continue
            vid = r.get("videoId", "")
            if not vid:
                continue
            artists = r.get("artists", [])
            artist = artists[0].get("name", "陈粒") if artists else "陈粒"
            title = r.get("title", "Unknown")
            duration = r.get("duration") or r.get("duration_seconds")
            if isinstance(duration, str):
                duration_ms = _parse_duration(duration)
            elif isinstance(duration, int):
                duration_ms = duration * 1000 if duration < 10000 else duration
            else:
                duration_ms = 240000

            thumbnails = r.get("thumbnails", [])
            cover_url = _get_high_res_thumbnail(thumbnails, vid)
            stream_url = f"https://www.youtube.com/watch?v={vid}"

            items.append(
                PlaylistItem(
                    id=str(uuid.uuid4()),
                    title=title,
                    artist=artist,
                    coverUrl=cover_url,
                    streamUrl=stream_url,
                    duration_ms=duration_ms,
                )
            )
        return items
    except Exception as e:
        print(f"[ytmusicapi] Fallback to mock: {e}")
        return []


def _get_mock_playlist() -> List[PlaylistItem]:
    """Return mock playlist with Chen Li metadata."""
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
    Returns a list of Chen Li (陈粒) songs.
    Uses ytmusicapi when available; falls back to high-quality mock data if rate-limited.
    """
    items = _fetch_from_ytmusic()
    if not items:
        items = _get_mock_playlist()
    return items


@app.get("/health")
async def health():
    return {"status": "ok", "service": "neon-pulse-music-api"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
