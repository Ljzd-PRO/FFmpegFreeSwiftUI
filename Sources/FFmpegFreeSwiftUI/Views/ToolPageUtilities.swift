import AppKit
import SwiftUI

enum ToolFilePanels {
    static func openFile(_ completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            completion(url.path)
        }
    }

    static func openFiles(_ completion: @escaping ([String]) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK else { return }
            completion(panel.urls.map(\.path))
        }
    }

    static func openDirectory(_ completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            completion(url.path)
        }
    }

    static func saveFile(_ completion: @escaping (String) -> Void) {
        let panel = NSSavePanel()
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            completion(url.path)
        }
    }
}

struct DropTargetModifier: ViewModifier {
    var onFiles: ([String]) -> Void

    func body(content: Content) -> some View {
        content.onDrop(of: [.fileURL], isTargeted: nil) { providers in
            var paths: [String] = []
            let group = DispatchGroup()
            for provider in providers {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    defer { group.leave() }
                    if let data = item as? Data,
                       let string = String(data: data, encoding: .utf8),
                       let url = URL(string: string) {
                        paths.append(url.path)
                    } else if let url = item as? URL {
                        paths.append(url.path)
                    }
                }
            }
            group.notify(queue: .main) {
                onFiles(paths)
            }
            return true
        }
    }
}

extension View {
    func acceptsFileDrops(_ onFiles: @escaping ([String]) -> Void) -> some View {
        modifier(DropTargetModifier(onFiles: onFiles))
    }
}

struct ToolBanner: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct StatusPill: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
