import SwiftUI

public struct SupportersView: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("支持者")
                .font(.title2.weight(.semibold))
            Text("macOS 版保留支持者页面与 Supporter Pack 个性化入口。Windows 的 DLL 解锁器不迁移；后续可设计原生 macOS 授权/个性化方案。")
                .foregroundStyle(.secondary)
            Link("赞助一下（afdian）", destination: URL(string: "https://afdian.com/a/1059Studio")!)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
