import SwiftUI

public struct ParameterPanelView: View {
    @EnvironmentObject private var presetStore: PresetStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @StateObject private var capabilityStore = VideoEncoderCapabilityStore()
    @State private var selection: ParameterTab = .overview

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(ParameterTab.allCases) { tab in
                        Button {
                            selection = tab
                        } label: {
                            Text(tab.title(language: settingsStore.settings.language))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(selection == tab ? .primary : .secondary)
                        .background(selection == tab ? Color.accentColor.opacity(0.18) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(8)
            }
            .frame(width: 220)
            Divider()
            ScrollView {
                Group {
                    switch selection {
                    case .overview:
                        OverviewPane(preset: $presetStore.current)
                    case .output:
                        OutputSettingsPane(preset: $presetStore.current)
                    case .decoding:
                        DecodingPane(preset: $presetStore.current)
                    case .videoEncoder:
                        VideoEncoderPane(preset: $presetStore.current, probedCapabilities: capabilityStore.capabilities)
                    case .videoFrame:
                        VideoFramePane(preset: $presetStore.current)
                    case .videoQuality:
                        VideoQualityPane(preset: $presetStore.current, probedCapabilities: capabilityStore.capabilities)
                    case .color:
                        ColorPane(preset: $presetStore.current, probedCapabilities: capabilityStore.capabilities)
                    case .commonFilters:
                        CommonFiltersPane(preset: $presetStore.current)
                    case .frameServer:
                        FrameServerPane(preset: $presetStore.current)
                    case .audio:
                        AudioPane(preset: $presetStore.current)
                    case .image:
                        ImageParametersPane(preset: $presetStore.current)
                    case .custom:
                        CustomArgumentsPane(preset: $presetStore.current)
                    case .clip:
                        ClipPane(preset: $presetStore.current)
                    case .stream:
                        StreamControlPane(preset: $presetStore.current)
                    case .scheme:
                        SchemeManagementPane(settings: $settingsStore.settings)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .task {
            capabilityStore.refresh(settings: settingsStore.settings)
        }
        .onChange(of: settingsStore.settings.ffmpegExecutableOverride) { _ in
            capabilityStore.refresh(settings: settingsStore.settings)
        }
        .onChange(of: presetStore.current) { _ in
            presetStore.persistAsLastPreset()
        }
    }
}
