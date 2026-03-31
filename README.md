# 果实

一个基于 Flutter 开发的 K-pop 应援棒控制应用


🧠🌟想法诞生于「陈粒十周年巡演」，带回家的应援棒只能默默放着，于是开始研究它为什么只能在演唱会期间亮，就不能手机上控制么，知道原理后开始搜类似的应用，搜到某个小程序做到了我想要的效果，但仅限xx粉丝可用，不就多一个蓝牙模块么，焊一个不就好了?开搞！！

## 设计特点

- **深色主题**: 深空背景 (#0E0E13) 配合霓虹强调色
- **毛玻璃效果**: 使用 BackdropFilter 实现玻璃态设计
- **霓虹光晕**: 绿、青、紫三色霓虹色调
- **流畅动画**: 精心设计的过渡和脉冲动画

## 颜色系统

- **Primary (粉红)**: #94D962 - 主品牌色
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
flutter run                    # 自动选择可用设备
flutter run -d chrome          # 浏览器
flutter run -d <device-id>     # 指定设备
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


### 打 Android APK

1. 安装 Android SDK（Android Studio 或 `flutter doctor` 提示的路径）。
2. 在项目根目录执行：

```bash
cd chen_li_ten_years
flutter pub get
# Release 单包（通用 arm64-v8a，体积适中）
flutter build apk --release
# 启动后端生成apk（确保在同一网关下）
flutter build apk --dart-define=API_BASE=http://<电脑IP>:8000
```

3. 生成的 APK 路径：

```
build/app/outputs/flutter-apk/app-release.apk
```

4. **可选**：按 ABI 分包（体积更小，需分别安装对应架构）：

```bash
flutter build apk --release --split-per-abi
# 输出在 build/app/outputs/flutter-apk/ 下，如 app-armeabi-v7a-release.apk 等
```

5. 首次构建前可运行 `flutter doctor -v` 检查 Android toolchain。

### 在 iPhone 真机上运行

1. **连接 iPhone**：用数据线连接 Mac，手机上信任此电脑
2. **启用开发者模式**（iOS 16+）：设置 → 隐私与安全性 → 开发者模式
3. **启动后端**（手机与电脑需在同一 WiFi）：
   ```bash
   cd backend && source .venv/bin/activate
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```
4. **查看电脑 IP**：系统设置 → 网络，或运行 `ifconfig | grep "inet "`
5. **运行到 iPhone**：
   ```bash
   flutter run -d <你的iPhone> --dart-define=API_BASE=http://<电脑IP>:8000
   ```
   例如：`flutter run -d 00008110-xxx --dart-define=API_BASE=http://192.168.1.100:8000`

   **若提示签名/provisioning 错误**：用 Xcode 打开 `ios/Runner.xcworkspace`，选中 Runner → Signing & Capabilities，确认已勾选 "Automatically manage signing" 并选择你的 Apple ID 开发团队。


## 项目结构

```
chen_li_ten_years/
├── backend/                 # FastAPI 歌单 API
├── lib/
│   ├── main.dart
│   ├── api/                 # 歌单 HTTP（API_BASE）
│   ├── ble/                 # BleController、征极/LEDnet 协议（zengge_protocol）
│   ├── settings/          # 如灯光 RGB 补偿（SharedPreferences）
│   ├── theme/
│   ├── widgets/
│   └── screens/           # scan / details / music / light 等
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
- just_audio: ^0.10.5 — 音乐播放（替代 audioplayers 解决 iOS 崩溃）
- permission_handler: ^11.3.0 — 权限请求

## 逻辑实现

### 蓝牙连接流程

- 依赖 **flutter_blue_plus**：扫描周边 BLE 广播、建立 GATT 连接。
- **扫描页**：`ScanController` 维护设备列表；用户点选某台设备后调用 `BleController.connect(BluetoothDevice)`。
- **连接**：`device.connect()` → `discoverServices()` → 在 `BleController._assignWriteCharacteristics` 中按**服务 UUID + 特征 UUID** 绑定可写特征（见下）。
- **断线**：监听 `connectionState`，断开时清理订阅并可选导航回扫描；断开前会尝试关灯（`setLampPowerOn(false)` 路径）。

### UUID 从哪里来？

**不是写死在代码里的「假协议」**。连接成功后，系统返回该外设真实的 **GATT 服务与特征**；应用按约定名称在已发现列表里**查找**并保存引用，例如：

| 用途 | 典型服务/特征（16 位短 UUID） | 说明 |
|------|------------------------------|------|
| LEDnetWF / 征极调色主写 | **FFFF** 服务下 **FF01** | 优先写入口；内层命令常套 **Transport v0** 再写入 |
| 部分荧光棒镜像写 | **FE00** 下 **FF11** | 与 FF01 并存时可能需**双写**同一条 payload |
| 旧版 0x7E 包 | **FFE0** 下 **FFE1** | 裸 `7E…` LEDnet 调色 |
| Magic Hue / 静态 0x56 | **FFE9** 等 | `56` 开头静态色包 |
| 兜底 | 任意可写特征 | 仅当上述都未匹配时 |

日志里出现的 `ff01=ff01` 等表示**当前设备上已解析到的特征短 ID**（用于调试路由），具体以实机 `discoverServices` 结果为准。

### 蓝牙状态（应用侧）

单例 **`BleController.instance`** 对外大致包括：

- **`isConnected`**：`已连接设备 != null` 且至少有一个可用的**可写特征**（能发指令即视为可操作）。
- **`isConnecting`**：正在发起连接。
- **`lampPowerOn`**：应用层的「开灯/关灯」状态；连接成功后默认开灯，并下发开机色。
- **`autoSyncEnabled`**：音乐页等与自动同步相关的开关（存于 `BleController`）。

### 发给荧光棒的指令形态（概要）

协议细节在 `lib/ble/zengge_protocol.dart`，写入路由在 `BleController`。

1. **调色（灯光页、音乐同步脚本等）**  
   - 界面逻辑 RGB →（可选）**灯光页「RGB 补偿」增益** `LightRgbCompensation` → **R↔B 线序补偿** `_rgbWireCompensateRb`（缓解部分固件/灯珠与屏幕 RGB 不一致）→ 组包下发。  
   - **LEDnetWF（存在 FF01/FF11）**：优先 **`0x31` + 校验** 的 SDK 命令，内层再套 **LEDnetWF Transport v0**（与征极 Android SDK `write(..., 0x0b, commandData)` 思路一致）；灯珠线序按 **GRB** 组 `0x31` 体。  
   - **兼容**：同路径可再发 **`0x7E 05 03 …`**（包头 `7E`，调色字节为 **GRB**）等；旧款可能走 **FFE9 的 `0x56`** 静态包。

2. **电源/开灯**  
   - 部分固件需先发 **`0x71`** 开/关，再调色；开灯默认使用品牌绿近似色，再走与调色相同的多路径写入。

3. **闪烁**  
   - **`0x7E` 闪烁预设包**（如 `buildLednetBlinkPacket`），同样经 Transport/双写落到 FF01/FF11 或 FFE1。

### 颜色偏差（为何界面/肉眼与荧光棒不一致）

屏幕上的 RGB 与棒端「看起来」的颜色很难 1:1，常见原因叠加：

| 因素 | 说明 |
|------|------|
| **线序与协议** | 灯珠多为 **GRB** 等物理顺序；`0x31` / `0x7E` 包内字节顺序与文档「R,G,B」字面可能不一致，需在 `zengge_protocol` / `BleController` 中统一。 |
| **固件与通道映射** | 部分固件对三字节解释与「逻辑 RGB」不等价（例如等效 **R↔B 交换**），代码里用 `_rgbWireCompensateRb` 在组包前做一次补偿。 |
| **光学与亮度** | 雾面外壳、混光、不同亮度下的观感不同；低亮时人眼对色相的感知也会变。 |
| **无出厂校准** | 消费级荧光棒通常没有显示器式的色准流程，官方征极类 App 也可能偏色。 |

**应用内应对**：灯光页 **RGB 补偿**（`lib/settings/light_rgb_compensation.dart`）按通道 **增益**（约 0.5～1.5）微调下发值，持久化到 **SharedPreferences**；与线序补偿**串联**：逻辑色 → 增益 → `_rgbWireCompensateRb` → `updateLightColor`。仍不满意时只能靠主观微调，无法保证与手机像素完全一致。

### 音乐节拍与灯光联动

实现主要在 `lib/screens/music/controller/music_controller.dart`，播放进度来自 **just_audio** 的 `positionStream`。

1. **总开关**  
   - **`BleController.autoSyncEnabled`**：关闭则播放时不向荧光棒发任何「跟歌」变色。

2. **两种同步方式**（灯光同步打开后，由 **`MusicController.useMetronomeBeatSync`** 区分，**默认关闭节拍器 = 时间轴模式**）  

   | 模式 | 行为 |
   |------|------|
   | **时间轴（默认）** | 使用 **`BleController.syncScript`**（`秒数 → [R,G,B]`）。播放到对应**整秒**时调用 **`triggerSyncAt`**，内部仍走 `updateLightColor`，与灯光页同一套补偿。同一秒内只触发一次；进度回到开头附近会清空已触发集合以便重播。 |
   | **节拍器** | 先对当前曲目音频做 **波形 RMS 包络**（`audio_waveforms` 的 `WaveformExtractionController.extractWaveformData`，音源需能落到本地临时文件），再在 `beat_analysis.dart` 中做**能量/起音峰值**得到一串毫秒时间戳作为「近似拍点」；若无有效拍点则按 **BPM**（默认 120，可调 60～200）做**等相位间隔**变色。每次拍点用 **HSV 色相递增** 调 `updateLightColor`。 |

3. **性能与策略**  
   - 波形解码较慢（长音频在 Android 上更明显），故 **仅在开启「节拍器」时** 才调度 **`_scheduleBeatAnalysis`**；默认时间轴模式**不做**整文件波形分析。  
   - 节拍器下的 **BPM 滑条**仅在「灯光同步 + 节拍器」同时开启时可用；已有波形拍点时 BPM 作为无波形时的回退逻辑保留在代码路径中。

4. **说明**  
   - 当前「节拍检测」基于 **包络能量峰**，不是专业鼓点/onset 算法，复杂编曲可能与真实鼓点不完全一致，属于可接受的工程折中。

### 其它

- **HTTP 歌单**：`lib/api/playlist_api.dart` 中 `API_BASE` 由 `--dart-define=API_BASE=...` 注入，默认可为局域网后端地址。
- **权限**：`main.dart` 中请求蓝牙扫描/连接及定位（Android 扫描 BLE 常需定位权限）。


## 更新日记：

- **2026年3月14号**: 看完成都场回家有了这个想法
- **2026年3月15号**: 让队友买了蓝牙模块
- **2026年3月20号**: 蓝牙模块到咯😬。生成页面，开始开发应用
- **2026年3月21号**: 队友已焊好👌。我的应用也写的差不多啦，拿回去对接试试，
- **2026年3月22号**: 😡气死了气死了，蓝牙模块搜索不到！！垃圾客服
- **2026年3月24号**: 果然是歪货模块，直接退款了😠浪费锡
- **2026年3月25号**: 新买的蓝牙模块到了，又给付师父拿去公司焊了，感觉能成，朋友给了一个测试安卓机，要试试打包
- **2026年3月30号**: 终于想起来买电池，荧光棒改造成功，app调试中，目前用征极app是可以操作的
- **2026年3月31号**: 调试调试ing，感觉快成了，但还有好多细节。颜色纠偏、节拍


