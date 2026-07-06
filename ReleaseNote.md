# FFmpegFreeSwiftUI v1.0.0

这是 `FFmpegFreeSwiftUI` 的首个 macOS 版本发布。项目以原版 FFmpegFreeUI v5 工作流为基线，使用 SwiftUI 重新实现 macOS 原生 App，并保留 `.3fui` / JSON 预设兼容思路。

## 本次更新

- 还原 v5 主导航：3FUI、编码队列、准备文件、参数面板、媒体信息、播放器、画质评测、混流、合并、性能监控、插件扩展、设置、支持者。
- 实现 v5 风格参数面板，补充说明文本、placeholder、可编辑下拉选项和 VideoToolbox 专属质量/码率提示。
- 支持编码队列的添加、开始、暂停、恢复、停止、重置、复制命令行、定位输出和进度解析。
- 支持自动查找 `ffmpeg`、`ffprobe`、`ffplay`，也可在设置页中指定自定义路径。
- 支持媒体信息、外部 `ffplay` 播放、画质评测、混流、合并、性能监控和 UDP 远程调用。
- 支持简体中文、繁体中文、英语运行时切换。
- 增加 macOS 菜单栏、Release workflow、命令行测试与 Xcode XCTest 覆盖。
- App 内已显示版本号，可在起始页和设置页查看当前版本。

## 使用说明

- macOS 版不内置 `ffmpeg`、`ffprobe`、`ffplay`。请先通过 Homebrew、MacPorts 或手动下载方式安装，或在设置页中指定路径。
- 首次打开未 notarize 的 GitHub Actions 构建包时，macOS 可能提示安全限制；可在“系统设置”中手动允许。
- 如果使用 VideoToolbox 编码器，控制文件大小优先设置 `-b:v`，省心画质可使用 `-q:v`，ProRes 则优先通过 `profile` 档位控制。

## 已知限制

- 发布包使用 GitHub Actions 的临时签名构建，未配置 Developer ID 签名与 notarization。
- 旧版 Windows `.3fui.dll` 插件不兼容 macOS 版本。
- `ffplay` 使用外部窗口，不嵌入 SwiftUI。
- AviSynth 需要用户自行准备 macOS 兼容环境。
- 部分 Windows 专属硬件监控指标在 macOS 无权限模式下不可稳定读取，当前不显示 GPU、显存、风扇、温度、功耗等指标。
