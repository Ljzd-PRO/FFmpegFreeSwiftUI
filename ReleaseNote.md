# FFmpegFreeSwiftUI Release Notes

请在发布前更新本文件。GitHub Release workflow 会从仓库根目录读取此文件，并将其内容作为 Release 正文。

## 本次更新

- 待补充。

## 使用说明

- macOS 版不内置 `ffmpeg`、`ffprobe`、`ffplay`，请先通过 Homebrew、MacPorts 或手动下载方式安装，或在设置页中指定路径。
- 当前版本以原版 FFmpegFreeUI v5 工作流为基线，Windows 专属能力已尽量替换为 macOS 原生实现。

## 已知限制

- 发布包使用 GitHub Actions 的临时签名构建，未配置 Developer ID 签名与 notarization 时，首次打开可能需要在系统设置中手动允许。
- 旧版 Windows `.3fui.dll` 插件不兼容 macOS 版本。
