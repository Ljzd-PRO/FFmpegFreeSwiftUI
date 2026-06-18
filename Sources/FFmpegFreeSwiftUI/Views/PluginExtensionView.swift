import SwiftUI

public struct PluginExtensionView: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("插件扩展")
                .font(.title2.weight(.semibold))
            Text("旧版 Windows .3fui.dll 反射插件不兼容 macOS SwiftUI 首版。当前保留页面和内部队列 API，后续可设计 Swift 原生插件方案。")
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
