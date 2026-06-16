# FFmpegFreeSwiftUI

macOS native SwiftUI port scaffold for FFmpegFreeUI.

## Run

```sh
swift run FFmpegFreeSwiftUIApp
```

For Xcode, open `FFmpegFreeSwiftUI.xcodeproj` and choose the `FFmpegFreeSwiftUI` scheme. This is a standard macOS `.app` target, so the Run button launches the window.

Opening only `Package.swift` may show SwiftPM executable products that build successfully but behave like command-line targets in Xcode.

## Verify

The Xcode project builds as a native macOS app. The repository also includes a small executable test runner for quick command-line verification:

```sh
swift build
swift run FFmpegFreeSwiftUITestRunner
```

The runner covers preset JSON compatibility, FFmpeg command generation, stream control, subtitle burn filters, progress parsing, output path generation, and shell argument splitting.

## Current Scope

- Native macOS SwiftUI app structure with sidebar navigation restored to the original v5 page order.
- `PresetData: Codable` using original Chinese JSON keys for `.3fui`/JSON compatibility.
- Parameter panel pages restored to the v5 tabs: overview, output, decoding, video encoder/frame/quality/color/common filters, frame server, audio, image, custom arguments, clip, stream control, and scheme management.
- v5 utility pages are split into quality assessment, muxing, merging, plugin extension, media info, and player pages.
- Encoding queue with drag-and-drop files, automatic/manual start, process progress parsing, stdin messages, pause/resume via `SIGSTOP`/`SIGCONT`, stop, remove, reset, Finder reveal, command copy, and error capture.
- `ffmpeg`, `ffprobe`, and `ffplay` are discovered from user settings, App-adjacent files, or `PATH`; they are not bundled.
- macOS replacements include Finder reveal, Trash deletion for failed output, `caffeinate` sleep prevention, UDP remote calls, and basic performance snapshots.

## Known First-Pass Limits

- Windows `.3fui.dll` plugins are intentionally not loaded on macOS.
- GPU/VRAM metrics are shown as unavailable in the first pass.
- ffplay is launched as an external process instead of embedded in SwiftUI.
- AviSynth settings are preserved but require the user to provide a macOS-compatible setup.
