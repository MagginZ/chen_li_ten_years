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

## 项目结构

```
chen_li_ten_years/
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
│       ├── scan_screen.dart   # 扫描页面
│       ├── details_screen.dart # 详情页面
│       ├── music_screen.dart  # 音乐页面
│       └── light_screen.dart  # 灯光控制页面
├── pubspec.yaml
└── README.md
```

## 依赖

- flutter: SDK
- cupertino_icons: ^1.0.2
- google_fonts: ^6.1.0

## 字体

- **Space Grotesk**: 标题字体，用于标题和强调文本
- **Inter**: 正文字体，用于 UI 标签和正文
