# FFmpegFreeSwiftUI

`FFmpegFreeSwiftUI` 是 `FFmpegFreeUI` 的 macOS 原生 SwiftUI 迁移版本。项目目标是尽量还原原版 v5 的页面顺序、参数面板和常用工作流，同时用 macOS 原生能力替代 Windows 专属实现。

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

## 许可与来源

本项目是对仓库中 `FFmpegFreeUI` 原项目的 macOS 原生迁移尝试。原项目的设计、页面顺序、参数命名和预设兼容策略是本项目的重要参考。
