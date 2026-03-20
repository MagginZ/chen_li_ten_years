# Kinetic Organicism

一个基于 Flutter 开发的 K-pop 应援棒控制应用，采用「生物发光」自然绿美学设计风格。

## 设计理念

**The Digital Pulse** — 从刺眼的霓虹转向精致、有机的视觉语言。界面如同音乐驱动的生命体，光感由内而外，而非生硬叠加。

## 设计特点

- **自然绿调色板**: 以 #7ABD4A 为基调，呈现「森林地表」般的柔和绿意
- **无边框规则**: 禁止 1px 实线边框，通过背景色阶划分层次
- **毛玻璃效果**: surface-variant 60% 透明度 + 20px 背景模糊
- **环境光晕**: primary 8% 透明度、40–60px 模糊，营造生物发光感

## 颜色系统

- **Primary (主绿)**: #94D962 — 主品牌色
- **Primary Container**: #7ABD4A — 渐变终点、森林绿
- **Surface (基底)**: #10140F — 背景色（禁止纯黑 #000）
- **Surface Container Low**: #191D17 — 分组层
- **Surface Container Highest**: #323630 — 可操作元素层

## 排版

- **Space Grotesk**: 标题与强调，偏科技感
- **Manrope**: 正文与标题，易读、温暖

## 页面结构

1. **Scan (扫描)** — 设备发现与连接
2. **Connect/Details (连接详情)** — 设备信息与电池状态
3. **Music (音乐)** — 音乐同步控制
4. **Light (灯光)** — 颜色轮盘与灯光模式

## 运行方式

```bash
cd chen_li_ten_years
flutter pub get
flutter run -d chrome
```

## 项目结构

```
chen_li_ten_years/
├── lib/
│   ├── main.dart
│   ├── theme/
│   │   ├── app_colors.dart    # Kinetic Organicism 颜色
│   │   └── app_theme.dart     # 主题配置
│   ├── widgets/
│   └── screens/
├── pubspec.yaml
└── README.md
```

## 依赖

- flutter: SDK
- cupertino_icons: ^1.0.6
