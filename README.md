# Neon Pulse

一个基于 Flutter 开发的 K-pop 应援棒控制应用，具有赛博朋克霓虹美学设计风格。

## 设计特点

- **深色主题**: 深空背景 (#0E0E13) 配合霓虹强调色
- **毛玻璃效果**: 使用 BackdropFilter 实现玻璃态设计
- **霓虹光晕**: 粉、青、紫三色霓虹色调
- **流畅动画**: 精心设计的过渡和脉冲动画

## 颜色系统

- **Primary (粉红)**: #FF89AB - 主品牌色
- **Secondary (青色)**: #00E3FD - 辅助色
- **Tertiary (紫色)**: #AC89FF - 第三色
- **Surface (深空)**: #0E0E13 - 背景色

## 页面结构

1. **Scan (扫描)** - 设备发现和连接页面
2. **Connect/Details (连接详情)** - 设备信息和电池状态
3. **Music (音乐)** - 音乐同步控制
4. **Light (灯光)** - 颜色轮盘和灯光模式

## 运行方式

```bash
cd chen_li_ten_years
flutter pub get
flutter run
flutter run -d chrome(浏览器)

```

## 后端 API

FastAPI 歌单服务，提供 `/api/playlist` 接口（陈粒音乐）。

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

- 服务地址: `http://localhost:8000`
- 局域网访问: `http://<电脑IP>:8000`（如 iPhone 同网访问）

## 项目结构

```
chen_li_ten_years/
├── backend/                 # FastAPI 歌单 API
│   ├── main.py
│   ├── requirements.txt
│   └── README.md
├── lib/
│   ├── main.dart              # 应用入口
│   ├── theme/
│   │   ├── app_colors.dart    # 颜色定义
│   │   └── app_theme.dart     # 主题配置
│   ├── widgets/
│   │   ├── app_header.dart    # 顶部导航栏
│   │   ├── bottom_nav_bar.dart # 底部导航栏
│   │   └── glass_container.dart # 毛玻璃组件
│   └── screens/
│       ├── scan.dart   # 扫描页面
│       ├── details.dart # 详情页面
│       ├── music.dart  # 音乐页面
│       └── light.dart  # 灯光控制页面
├── pubspec.yaml
└── README.md
```

## 字体

- **Space Grotesk**: 标题字体，用于标题和强调文本
- **Inter**: 正文字体，用于 UI 标签和正文


## 依赖

- flutter: SDK
- cupertino_icons: ^1.0.6
- flutter_blue_plus: ^1.32.0 — 蓝牙扫描与连接
- audioplayers: ^6.0.0 — 音乐播放
- permission_handler: ^11.3.0 — 权限请求

## 逻辑实现 (Mock 协议)

- **Mock UUID**: 0000FFE0 / 0000FFE1
- **Scan**: Re-scan 调用 flutter_blue_plus 扫描，列表顶部硬编码 "Official Lightstick V2"，点击 CONNECT 模拟连接并跳转
- **Details**: Auto-Sync 开关存储在 BleController
- **Music**: 播放 assets/audio/mock_music.mp3，时间轴 Map (5s/10s/15s/20s/25s) 触发 RGB 指令
- **Light**: 色盘选择实时转 RGB 发送，Fandom Presets (粉/白/蓝/紫) 点击发送预设指令
