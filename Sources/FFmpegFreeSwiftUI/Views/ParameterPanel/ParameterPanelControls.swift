import AppKit
import SwiftUI

struct FormSection<Content: View>: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    var title: String
    var note: String = ""
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t(title))
                .font(.headline)
            if !note.isEmpty {
                Text(t(note))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                content
            }
        }
        .padding(.bottom, 18)
    }

    private func t(_ key: String) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }
}

struct FormRow<Content: View>: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    var label: String
    var help: String = ""
    @ViewBuilder var content: Content

    var body: some View {
        GridRow {
            Text(t(label))
                .foregroundStyle(.secondary)
                .frame(width: 170, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                content
                    .frame(maxWidth: 560, alignment: .leading)
                if !help.isEmpty {
                    Text(t(help))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: 620, alignment: .leading)
        }
    }

    private func t(_ key: String) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }
}

struct ParameterFieldInfo {
    var title: String
    var placeholder: String = ""
    var help: String = ""
    var options: [ParameterOption] = []
}

struct ParameterOption: Hashable {
    var title: String
    var value: String
    var clearsToPlaceholder: Bool

    init(_ value: String) {
        title = value
        self.value = value
        clearsToPlaceholder = false
    }

    init(title: String, value: String, clearsToPlaceholder: Bool = false) {
        self.title = title
        self.value = value
        self.clearsToPlaceholder = clearsToPlaceholder
    }
}

struct MappedOption<Value: Hashable>: Hashable {
    var title: String
    var value: Value
}

struct EditableComboBox: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var options: [ParameterOption]

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, options: options)
    }

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.usesDataSource = false
        comboBox.completes = true
        comboBox.isEditable = true
        comboBox.numberOfVisibleItems = 12
        comboBox.delegate = context.coordinator
        comboBox.translatesAutoresizingMaskIntoConstraints = false
        comboBox.setContentHuggingPriority(.defaultLow, for: .horizontal)
        comboBox.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return comboBox
    }

    func updateNSView(_ comboBox: NSComboBox, context: Context) {
        context.coordinator.text = $text
        context.coordinator.options = options
        comboBox.placeholderString = placeholder
        let displayText = options.first(where: { $0.value == text && !$0.title.isEmpty && !$0.clearsToPlaceholder })?.title ?? text
        if comboBox.stringValue != displayText {
            comboBox.stringValue = displayText
        }
        let titles = options.map(\.title)
        if comboBox.numberOfItems != titles.count || (0..<comboBox.numberOfItems).map({ comboBox.itemObjectValue(at: $0) as? String ?? "" }) != titles {
            comboBox.removeAllItems()
            comboBox.addItems(withObjectValues: titles)
        }
    }

    final class Coordinator: NSObject, NSComboBoxDelegate {
        var text: Binding<String>
        var options: [ParameterOption]
        private var isClearingPlaceholderOption = false

        init(text: Binding<String>, options: [ParameterOption]) {
            self.text = text
            self.options = options
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            let index = comboBox.indexOfSelectedItem
            if options.indices.contains(index) {
                let option = options[index]
                text.wrappedValue = option.value
                guard option.clearsToPlaceholder else {
                    comboBox.stringValue = option.title
                    return
                }

                isClearingPlaceholderOption = true
                comboBox.deselectItem(at: index)
                comboBox.stringValue = ""
                DispatchQueue.main.async { [weak self, weak comboBox] in
                    comboBox?.stringValue = ""
                    self?.isClearingPlaceholderOption = false
                }
            }
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            guard !isClearingPlaceholderOption else {
                comboBox.stringValue = ""
                text.wrappedValue = ""
                return
            }
            let visibleText = comboBox.stringValue
            if let option = options.first(where: { $0.title == visibleText }) {
                text.wrappedValue = option.value
            } else {
                text.wrappedValue = visibleText
            }
        }
    }
}

struct FieldComboBox: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @Binding var text: String
    var info: ParameterFieldInfo
    var options: [ParameterOption]? = nil
    var normalize: (String) -> String = { $0 }

    private var normalizedText: Binding<String> {
        Binding<String>(
            get: { text },
            set: { text = normalize($0) }
        )
    }

    var body: some View {
        EditableComboBox(
            text: normalizedText,
            placeholder: t(info.placeholder),
            options: localizedOptions(options ?? info.options)
        )
            .frame(height: 24)
    }

    private func localizedOptions(_ options: [ParameterOption]) -> [ParameterOption] {
        options.map {
            ParameterOption(
                title: t($0.title),
                value: $0.value,
                clearsToPlaceholder: $0.clearsToPlaceholder
            )
        }
    }

    private func t(_ key: String) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }
}

struct MappedOptionComboBox<Value: Hashable>: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @Binding var selection: Value
    var placeholder: String
    var options: [MappedOption<Value>]

    private var textBinding: Binding<String> {
        Binding<String>(
            get: {
                options.first(where: { $0.value == selection }).map { t($0.title) } ?? ""
            },
            set: { newValue in
                if let option = options.first(where: { t($0.title) == newValue }) {
                    selection = option.value
                }
            }
        )
    }

    var body: some View {
        EditableComboBox(
            text: textBinding,
            placeholder: t(placeholder),
            options: options.map { ParameterOption(title: t($0.title), value: t($0.title)) }
        )
        .frame(height: 24)
    }

    private func t(_ key: String) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }
}

struct VideoEncoderProfile {
    var presets: [ParameterOption]
    var profiles: [ParameterOption]
    var tunes: [ParameterOption]
    var pixelFormats: [ParameterOption]
}
