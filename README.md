# FFmpegFreeSwiftUI

`FFmpegFreeSwiftUI` 是 [FFmpegFreeUI](https://github.com/Lake1059/FFmpegFreeUI) 的 macOS 原生 SwiftUI 迁移版本。项目目标是尽量还原原版 v5 的页面顺序、参数面板和常用工作流，同时用 macOS 原生能力替代 Windows 专属实现。

当前仓库仍保留原 Windows 项目作为迁移参考；macOS App 本体位于 `Sources/FFmpegFreeSwiftUI` 与 `Sources/FFmpegFreeSwiftUIApp`。

## 项目定位

- 目标平台：macOS 13.0 及以上。
- UI 技术：SwiftUI 原生 macOS App。
- 功能基线：对齐原版 v5，不保留 v6 的 Agent、社区浏览、集成工具等新增入口。
- FFmpeg 策略：不内置 `ffmpeg`、`ffprobe`、`ffplay`，由用户自行安装或指定路径。
- 预设兼容：继续使用原版中文 JSON key，保持 `.3fui` / JSON 预设兼容思路。

## 与原版 FFmpegFreeUI 的主要差异

### 平台与界面

原版 `FFmpegFreeUI` 主要面向 Windows，使用 WinForms / LakeUI 及 Windows API。`FFmpegFreeSwiftUI` 改为 macOS 原生 SwiftUI，使用侧边栏导航和 macOS 标准菜单栏。

当前主导航按 v5 顺序恢复为：

`3FUI`、编码队列、准备文件、参数面板、媒体信息、播放器、画质评测、混流、合并、性能监控、插件扩展、设置、支持者。

### FFmpeg 工具查找

macOS 版不捆绑 FFmpeg，也不负责安装 Homebrew 或下载二进制。工具查找优先级为：

1. 设置页中用户指定的路径。
2. App 同级目录、`bin` 目录或 App bundle 内资源目录。
3. 当前环境 `PATH`。
4. 常见目录，例如 `/opt/homebrew/bin`、`/usr/local/bin`、`/opt/local/bin`。

如果只设置了 `ffmpeg` 路径，程序会自动尝试在同目录推导 `ffprobe` 和 `ffplay`。

### Windows 专属能力替换

- 暂停/恢复编码：使用 Unix signal `SIGSTOP` / `SIGCONT`。
- 防睡眠：使用 `/usr/bin/caffeinate`。
- Finder 定位：使用 `NSWorkspace.shared.activateFileViewerSelecting`。
- 删除失败输出：使用 macOS 回收站接口 `FileManager.trashItem`。
- 文件时间保留：尽量写入 macOS 支持的文件属性，不可写字段会降级跳过。
- 性能监控：使用 macOS 无权限可读指标，保留 CPU、内存、磁盘、队列负载等信息。

### 插件系统

原版 Windows `.3fui.dll` 插件依赖 .NET 反射接口，macOS 首版不加载这类插件。当前保留“插件扩展”入口用于说明兼容限制，后续如需扩展会设计 Swift / macOS 原生插件机制。

### 播放器

原版相关调试播放能力在 macOS 版首版中通过外部 `ffplay` 独立窗口启动。SwiftUI 内嵌播放器不是首版目标。

### AviSynth / VapourSynth

参数面板保留相关设置项。VapourSynth 可按用户本机可执行环境使用；AviSynth 在 macOS 上需要用户自行准备兼容方案。

### 硬件监控

Windows 版可依赖 Windows 侧硬件监控能力。macOS 版不引入私有 API 或提权采样，默认不显示 GPU、显存、风扇、温度、功耗等不可稳定读取的指标。

## 当前功能

- v5 风格参数面板，包含输出、解码、视频编码器、画面帧、质量、色彩、常见滤镜、帧服务器、音频、图片、自定义参数、剪辑区间、流控制、方案管理等页面。
- 字符串参数支持可编辑下拉输入，既可选择候选项，也可手动输入 FFmpeg 参数。
- VideoToolbox 编码器使用 macOS 专属选项提示，避免把 x264/x265 的 `preset`、`tune`、`threads`、`gpu` 等参数误用于 VideoToolbox。
- 编码队列支持拖拽加入、自动/手动开始、并发上限、暂停、恢复、停止、移除、重置、复制命令行、定位输出、错误捕获和 stdin 消息。
- 进度解析支持 `Duration`、`frame`、`size`、`time`、`bitrate`、`speed` 等 FFmpeg 输出。
- 媒体信息页调用 `ffprobe -hide_banner`。
- 播放器页调用外部 `ffplay`。
- 画质评测支持 PSNR、SSIM、XPSNR、VMAF，具体可用性取决于本机 FFmpeg 编译的滤镜。
- 混流、合并页面按 v5 基础工作流迁移，生成任务加入编码队列。
- 设置页支持工具路径、语言、界面显示、并发数、自动开始、远程调用等配置。
- 支持简体中文、繁体中文、英语运行时切换。
- UDP 远程调用保留原参数风格，默认端口 `10591`。

## VideoToolbox 视频质量与大小控制指南

VideoToolbox 是 Apple 提供的硬件视频编码能力，优点是速度快、功耗低，适合 macOS 上的日常转码。它和 x264 / x265 的参数体系不同：想控制文件大小，优先设置视频码率；想省心控制画质，可以设置视频质量等级。

### 关键名词

- `-b:v`：`video bitrate`，视频码率，也就是每秒给视频多少数据量。它主要控制文件大小。
- `-q:v`：`video quality` / `video quality scale`，视频质量等级。在 VideoToolbox 中可以理解为“画质优先级”。它主要控制清晰程度，但文件大小不精确。

### 普通用户怎么选

| 目标 | 推荐做法 |
| --- | --- |
| 想控制文件多大 | 设置 `-b:v` |
| 想简单保证画质 | 设置 `-q:v` |
| 想兼容所有设备 | 用 H.264 VideoToolbox |
| 想文件更小 | 用 HEVC VideoToolbox |
| 想后期剪辑 | 用 ProRes VideoToolbox |

在参数面板的“视频参数质量”页中，VideoToolbox 会直接按参数名显示控制目标：

| 控制目标 | 作用 |
| --- | --- |
| `-b:v` | 按视频码率控制文件大小 |
| `-q:v` | 按质量等级控制画质，文件大小由编码器决定 |
| `-maxrate / -bufsize` | 限制峰值码率和码率波动，适合直播、网页或设备兼容 |

VideoToolbox 模式下不会显示“质量参数名”输入框。H.264 / HEVC 的质量值会自动按 `-q:v` 生成命令；旧预设里残留的 `-crf`、`-cq`、`-qp`、`-global_quality` 会被跳过并在参数总览提示。ProRes VideoToolbox 不使用 `-q:v` 控制压缩质量，主要在“视频参数编码器”的 `profile` 中选择 `proxy`、`lt`、`standard`、`hq`、`4444` 或 `xq`。

使用 `-b:v` 时，可以这样估算文件大小：

```text
文件大小 MB ≈ 视频码率 Mbps × 时长分钟 × 7.5
```

例如 10 分钟视频设置 `-b:v 4M`，大小大约是 `4 × 10 × 7.5 = 300 MB`，再加一点音频大小。

### 推荐码率

| 分辨率 | H.264 VideoToolbox | HEVC VideoToolbox |
| --- | ---: | ---: |
| 720p30 | 2.5-4 Mbps | 1.5-2.8 Mbps |
| 1080p30 | 6-10 Mbps | 3-6 Mbps |
| 1080p60 | 10-16 Mbps | 6-10 Mbps |
| 4K30 | 35-55 Mbps | 18-35 Mbps |
| 4K60 | 55-85 Mbps | 35-60 Mbps |

如果视频内容很简单，例如课件、屏幕录制、动画，可以从表格低值开始；如果是运动、噪点、暗光、游戏画面，可以适当提高。

### `-q:v` 怎么填

`-q:v` 适合“不想计算文件大小，只想要大致清晰”的场景：

| `-q:v` | 效果 |
| ---: | --- |
| 50 | 文件较小，画质一般 |
| 65 | 平衡，推荐默认 |
| 75 | 高质量 |
| 80+ | 文件明显变大，画质提升开始变少 |

不知道怎么选时，建议先用 `-q:v 65`。觉得文件太大就降到 `55`，觉得画面不够清楚就升到 `75`。

### 编码器选择

| 编码器 | 适合场景 |
| --- | --- |
| `h264_videotoolbox` | 最通用，适合发给别人、上传平台 |
| `hevc_videotoolbox` | 同等观感下文件更小，适合较新设备 |
| `prores_videotoolbox` | 剪辑中间文件，文件很大，不适合压小视频 |

推荐命令片段：

```sh
# H.264，兼容优先
-c:v h264_videotoolbox -profile:v high -b:v 8M

# HEVC，体积优先
-c:v hevc_videotoolbox -tag:v hvc1 -b:v 5M

# 省心画质模式
-c:v hevc_videotoolbox -tag:v hvc1 -q:v 65
```

### 不建议用于 VideoToolbox 的参数

这些参数属于 x264 / x265 常见习惯，不适合直接用于 VideoToolbox：

```sh
-crf
-preset
-tune
-threads:v
-gpu
```

`CRF` 是 x264 / x265 常用的质量控制方式，不是 VideoToolbox 的主要控制方式。`preset`、`tune`、线程数和 GPU 选择也不会按 x264 / x265 的语义影响 VideoToolbox。

### 其他常见参数

- `-maxrate`：限制峰值码率，适合直播、网页、设备兼容。普通转码可以不填；要填时可设为 `-b:v` 的 1.5 到 2 倍。
- `-bufsize`：和 `-maxrate` 配合使用，影响码率波动缓冲。普通转码可以不填；要填时可设为 `-b:v` 的 2 倍左右。
- `-constant_bit_rate 1`：固定码率，只在平台明确要求 CBR 时开启；普通导出通常不需要。
- `-realtime 1`：直播、录屏实时编码用，普通转码建议关闭。
- `-power_efficient 1`：请求更省电的编码方式，适合电池模式或批量任务，但不保证更好画质。
- `-prio_speed 1`：速度优先，可能牺牲一点质量；普通用户通常不需要开启。
- `-spatial_aq 1`：可尝试改善低码率观感，实际效果取决于机器、系统和素材。

一句话总结：普通用户优先用 `-b:v` 控制大小；不想算大小就用 `-q:v 65`。

## 构建与运行

### Xcode

打开：

```sh
open FFmpegFreeSwiftUI.xcodeproj
```

选择 `FFmpegFreeSwiftUI` scheme 后点击 Run，即可启动 macOS App。

如果只打开 `Package.swift`，Xcode 可能把 SwiftPM executable 当作命令行目标显示，表现为“构建成功但没有窗口”。建议使用 `.xcodeproj`。

### SwiftPM

```sh
swift build
swift run FFmpegFreeSwiftUIApp
```

## 测试

项目包含两类测试：

- `command-only`：不需要 FFmpeg，只验证命令生成、状态流转、解析、持久化等逻辑。
- `with-ffmpeg`：使用本机 FFmpeg 生成短小测试媒体并执行真实转码、ffprobe、画质评测、混流、合并等冒烟测试。

命令行运行：

```sh
swift run FFmpegFreeSwiftUITestRunner --mode command-only
swift run FFmpegFreeSwiftUITestRunner --mode with-ffmpeg
```

指定 FFmpeg 路径：

```sh
swift run FFmpegFreeSwiftUITestRunner --mode with-ffmpeg --ffmpeg /opt/homebrew/bin/ffmpeg
```

Xcode 测试：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project FFmpegFreeSwiftUI.xcodeproj \
  -scheme FFmpegFreeSwiftUI-CommandOnlyTests \
  -configuration Debug \
  -destination 'platform=macOS' test

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project FFmpegFreeSwiftUI.xcodeproj \
  -scheme FFmpegFreeSwiftUI-FFmpegTests \
  -configuration Debug \
  -destination 'platform=macOS' test
```

`with-ffmpeg` 测试会根据本机 FFmpeg 能力自动跳过缺失滤镜或编码器，例如 `subtitles`、`libvmaf`、`xpsnr`、VideoToolbox 等。

## 自动构建

仓库提供 GitHub Actions workflow，可在 macOS runner 上构建 Release App、运行 command-only 测试并上传构建产物。当前默认使用本地签名 / ad-hoc 签名，不包含 Developer ID 公证流程。

## 已知限制

- 不加载 Windows `.3fui.dll` 插件。
- 不内置 FFmpeg，也不自动安装 FFmpeg。
- `ffplay` 使用外部窗口，不内嵌到 SwiftUI。
- AviSynth 需要用户自行准备 macOS 兼容环境。
- 部分旧版 Windows 硬件指标在 macOS 无权限模式下不可稳定读取，已从 UI 中移除或不作为首版目标。
- 预设兼容以 v5 旧版行为为主，v6 新增 UI 和模型不作为当前版本目标。

## 仓库结构

```text
Sources/FFmpegFreeSwiftUI        App 核心代码
Sources/FFmpegFreeSwiftUIApp     macOS App 入口与资源
Sources/FFmpegFreeSwiftUITestSupport
                                 共享测试用例与测试工具
Sources/FFmpegFreeSwiftUITestRunner
                                 命令行测试 runner
Tests                            XCTest target
FFmpegFreeSwiftUI.xcodeproj      Xcode 工程
FFmpegFreeUI                     原 Windows 项目参考代码
```

## 原项目引用与致谢

本项目是对 [Lake1059/FFmpegFreeUI](https://github.com/Lake1059/FFmpegFreeUI) 的 macOS 原生迁移尝试。原项目的设计、页面顺序、参数命名、预设兼容策略和大量功能行为是 `FFmpegFreeSwiftUI` 的重要参考。

感谢 `FFmpegFreeUI` 原作者及其项目贡献者长期维护 3FUI，也感谢原项目为本迁移版提供的设计基础、功能语义和兼容性参照。若需要 Windows 原版、最新发布包或原项目文档，请访问原仓库：[https://github.com/Lake1059/FFmpegFreeUI](https://github.com/Lake1059/FFmpegFreeUI)。
