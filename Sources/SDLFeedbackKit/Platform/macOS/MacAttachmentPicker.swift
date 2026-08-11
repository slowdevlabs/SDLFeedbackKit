#if os(macOS)
import AppKit
import Foundation
import SwiftUI

struct PlatformAttachmentPickerView: NSViewRepresentable {
    let onSelectionAccepted: () -> Void
    let onOutcome: (AttachmentPickerOutcome) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectionAccepted: onSelectionAccepted, onOutcome: onOutcome)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            context.coordinator.presentOpenPanel()
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class Coordinator {
        private let onSelectionAccepted: () -> Void
        private let onOutcome: (AttachmentPickerOutcome) -> Void
        private var didPresent = false

        init(
            onSelectionAccepted: @escaping () -> Void,
            onOutcome: @escaping (AttachmentPickerOutcome) -> Void
        ) {
            self.onSelectionAccepted = onSelectionAccepted
            self.onOutcome = onOutcome
        }

        func presentOpenPanel() {
            guard !didPresent else { return }
            didPresent = true

            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.allowedFileTypes = ["jpg", "jpeg", "png", "heic", "heif"]
            panel.title = NSLocalizedString("feedback.attachment.title", bundle: .module, comment: "")

            let result = panel.runModal()
            guard result == .OK, let url = panel.url else {
                onOutcome(.cancelled)
                return
            }
            onSelectionAccepted()

            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                onOutcome(.selected(data))
            } catch {
                onOutcome(.failed(.attachmentProcessingFailed))
            }
        }
    }
}
#endif
