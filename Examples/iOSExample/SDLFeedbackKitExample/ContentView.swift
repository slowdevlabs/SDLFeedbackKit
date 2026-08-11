import SwiftUI
import SDLFeedbackKit
#if canImport(Photos)
import Photos
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct ContentView: View {
    @State private var activeSheet: ActiveSheet?
    @State private var submissionMode: Mode = .success
    @State private var statusMessage = "Ready"

    private let feedbackContext = FeedbackContext(
        appID: "sdlfeedbackkit-example",
        appName: "SDLFeedbackKit Example",
        metadata: [
            "environment": "example"
        ]
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SDLFeedbackKit Example")
                .font(.title.weight(.semibold))

            Picker("Submission Mode", selection: $submissionMode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Button("Open Feedback Form") {
                activeSheet = .feedback
            }

#if DEBUG
            Button("Open PHPicker Isolation Diagnostic") {
                activeSheet = .isolationDiagnostic
            }
#endif

            Text(statusMessage)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .feedback:
                FeedbackFormView(
                    context: feedbackContext,
                    transport: ExampleFeedbackTransport(mode: submissionMode),
                    onSubmitted: { result in
                        statusMessage = "Submitted: \(result.clientID.uuidString.prefix(8))"
                        activeSheet = nil
                    },
                    onCancelled: {
                        statusMessage = "Cancelled"
                        activeSheet = nil
                    }
                )
#if DEBUG
            case .isolationDiagnostic:
                IsolationDiagnosticView()
#endif
            }
        }
    }
}

private enum ActiveSheet: Identifiable {
    case feedback
#if DEBUG
    case isolationDiagnostic
#endif

    var id: String {
        switch self {
        case .feedback:
            return "feedback"
#if DEBUG
        case .isolationDiagnostic:
            return "isolationDiagnostic"
#endif
        }
    }
}

#if DEBUG
private struct IsolationDiagnosticView: View {
    @State private var preset: IsolationDiagnosticPreset = .screenshotControl
    @State private var isPresentingPicker = false
    @State private var status = "idle"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Minimal PHPicker Diagnostic")
                        .font(.headline)

                    Text("Status: \(status)")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Button("Preset: Screenshot Control") {
                            preset = .screenshotControl
                            status = "preset set: screenshot control"
                        }
                        Button("Preset: P2 HEIC File") {
                            preset = .p2HeicFile
                            status = "preset set: P2 HEIC file"
                        }
                        Button("Preset: P3 HEIC Data") {
                            preset = .p3HeicData
                            status = "preset set: P3 HEIC data"
                        }
                        Button("Preset: P4 Current Concrete File") {
                            preset = .p4CurrentConcreteFile
                            status = "preset set: P4 current concrete file"
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mode: \(preset.representationModeDescription)")
                        Text("Request: \(preset.requestKind.rawValue)")
                        Text("Type: \(preset.requestedTypeDescription)")
                    }
                    .font(.system(.body, design: .monospaced))

                    Button("Select Photo") {
                        status = "picker opened"
                        isPresentingPicker = true
                    }

                    Button("Reset Status") {
                        status = "idle"
                    }
                }
                .padding(24)
            }
            .navigationBarTitle("Isolation Diagnostic")
            .sheet(isPresented: $isPresentingPicker) {
                IsolationPHPickerView(
                    configuration: preset.configuration,
                    onStatusChange: { newStatus in
                        status = newStatus
                    },
                    onDismissRequest: {
                        isPresentingPicker = false
                    }
                )
            }
        }
    }
}

private struct IsolationDiagnosticPreset {
    enum RepresentationMode: String {
        case defaultUnset = "default-unset"
        case automatic
        case current
        case compatible
    }

    enum RequestKind: String {
        case file
        case data
    }

    let representationMode: RepresentationMode
    let requestKind: RequestKind
    let requestedType: String?

    static let screenshotControl = IsolationDiagnosticPreset(
        representationMode: .defaultUnset,
        requestKind: .file,
        requestedType: "public.png"
    )

    static let p2HeicFile = IsolationDiagnosticPreset(
        representationMode: .defaultUnset,
        requestKind: .file,
        requestedType: "public.heic"
    )

    static let p3HeicData = IsolationDiagnosticPreset(
        representationMode: .defaultUnset,
        requestKind: .data,
        requestedType: "public.heic"
    )

    static let p4CurrentConcreteFile = IsolationDiagnosticPreset(
        representationMode: .current,
        requestKind: .file,
        requestedType: nil
    )

    var representationModeDescription: String {
        representationMode.rawValue
    }

    var requestedTypeDescription: String {
        requestedType ?? "resolved concrete"
    }

    var configuration: IsolationPickerConfiguration {
        IsolationPickerConfiguration(
            representationMode: representationMode,
            requestKind: requestKind,
            requestedTypeOverride: requestedType
        )
    }
}

private struct IsolationPickerConfiguration {
    let representationMode: IsolationDiagnosticPreset.RepresentationMode
    let requestKind: IsolationDiagnosticPreset.RequestKind
    let requestedTypeOverride: String?
}

private struct IsolationPHPickerView: UIViewControllerRepresentable {
    let configuration: IsolationPickerConfiguration
    let onStatusChange: (String) -> Void
    let onDismissRequest: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            configuration: configuration,
            onStatusChange: onStatusChange,
            onDismissRequest: onDismissRequest
        )
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if #available(iOS 14.0, *) {
            var pickerConfiguration = PHPickerConfiguration(photoLibrary: .shared())
            pickerConfiguration.filter = .images
            pickerConfiguration.selectionLimit = 1
            if let mode = Self.assetRepresentationMode(for: configuration.representationMode) {
                pickerConfiguration.preferredAssetRepresentationMode = mode
            }

            IsolationDiagnosticLog.log("picker.configuration.mode = \(configuration.representationMode.rawValue)")
            IsolationDiagnosticLog.log("picker.configuration.filter = images")
            IsolationDiagnosticLog.log("picker.configuration.selectionLimit = 1")

            let picker = PHPickerViewController(configuration: pickerConfiguration)
            picker.delegate = context.coordinator
            return picker
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.image"]
            picker.delegate = context.coordinator
            picker.allowsEditing = false
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate {
        private let configuration: IsolationPickerConfiguration
        private let onStatusChange: (String) -> Void
        private let onDismissRequest: () -> Void
        private var hasCompleted = false

        init(
            configuration: IsolationPickerConfiguration,
            onStatusChange: @escaping (String) -> Void,
            onDismissRequest: @escaping () -> Void
        ) {
            self.configuration = configuration
            self.onStatusChange = onStatusChange
            self.onDismissRequest = onDismissRequest
        }

        @available(iOS 14.0, *)
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !hasCompleted else { return }
            hasCompleted = true

            IsolationDiagnosticLog.log("picker.didFinishPicking")
            IsolationDiagnosticLog.log("results.count = \(results.count)")

            guard let result = results.first else {
                IsolationDiagnosticLog.log("load.error domain=IsolationDiagnostic code=0")
                onStatusChange("cancelled")
                onDismissRequest()
                return
            }

            let provider = result.itemProvider
            logProvider(provider)
            onStatusChange("selection received")
            onDismissRequest()

            Task {
                await self.request(provider)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            guard !hasCompleted else { return }
            hasCompleted = true
            IsolationDiagnosticLog.log("picker.didFinishPicking")
            IsolationDiagnosticLog.log("results.count = 0")
            onStatusChange("cancelled")
            onDismissRequest()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard !hasCompleted else { return }
            hasCompleted = true

            IsolationDiagnosticLog.log("picker.didFinishPicking")
            IsolationDiagnosticLog.log("results.count = 1")

            if let url = info[.imageURL] as? URL {
                IsolationDiagnosticLog.log("provider.registeredTypes = [UIImagePickerController.imageURL]")
                IsolationDiagnosticLog.log("provider.isLivePhoto = false")
                IsolationDiagnosticLog.log("provider.hasJPEG = true")
                IsolationDiagnosticLog.log("provider.hasHEIC = false")
                IsolationDiagnosticLog.log("provider.hasPNG = false")
                IsolationDiagnosticLog.log("request.kind = file")
                IsolationDiagnosticLog.log("requestedType = imageURL")
                IsolationDiagnosticLog.log("load.started")
                IsolationDiagnosticLog.log("load.callback elapsed=0.000")
                IsolationDiagnosticLog.log("load.success")
                onStatusChange("success")
                onDismissRequest()
                _ = url
                return
            }

            if info[.originalImage] != nil {
                IsolationDiagnosticLog.log("provider.registeredTypes = [UIImagePickerController.originalImage]")
                IsolationDiagnosticLog.log("provider.isLivePhoto = false")
                IsolationDiagnosticLog.log("provider.hasJPEG = false")
                IsolationDiagnosticLog.log("provider.hasHEIC = false")
                IsolationDiagnosticLog.log("provider.hasPNG = false")
                IsolationDiagnosticLog.log("request.kind = data")
                IsolationDiagnosticLog.log("requestedType = originalImage")
                IsolationDiagnosticLog.log("load.started")
                IsolationDiagnosticLog.log("load.callback elapsed=0.000")
                IsolationDiagnosticLog.log("load.success bytes=0")
                onStatusChange("success")
                onDismissRequest()
                return
            }

            IsolationDiagnosticLog.log("load.error domain=IsolationDiagnostic code=1")
            onStatusChange("error")
            onDismissRequest()
        }

        @available(iOS 14.0, *)
        private func request(_ provider: NSItemProvider) async {
            let requestedType = resolvedRequestedType(for: provider)
            IsolationDiagnosticLog.log("request.kind = \(configuration.requestKind.rawValue)")
            IsolationDiagnosticLog.log("requestedType = \(requestedType ?? "nil")")

            guard let requestedType else {
                await MainActor.run {
                    self.onStatusChange("error")
                }
                IsolationDiagnosticLog.log("load.error domain=IsolationDiagnostic code=2")
                return
            }

            switch configuration.requestKind {
            case .file:
                await requestFile(provider: provider, requestedType: requestedType)
            case .data:
                await requestData(provider: provider, requestedType: requestedType)
            }
        }

        @available(iOS 14.0, *)
        private func requestFile(provider: NSItemProvider, requestedType: String) async {
            let start = Date()
            IsolationDiagnosticLog.log("load.started")
            await withCheckedContinuation { continuation in
                provider.loadFileRepresentation(forTypeIdentifier: requestedType) { url, error in
                    let elapsed = Date().timeIntervalSince(start)
                    IsolationDiagnosticLog.log("load.callback elapsed=\(IsolationDiagnosticLog.formatElapsed(elapsed))")
                    if url != nil {
                        IsolationDiagnosticLog.log("load.success")
                        Task { @MainActor in
                            self.onStatusChange("success")
                        }
                    } else if let error {
                        let nsError = error as NSError
                        IsolationDiagnosticLog.log("load.error domain=\(nsError.domain) code=\(nsError.code)")
                        Task { @MainActor in
                            self.onStatusChange("error")
                        }
                    } else {
                        IsolationDiagnosticLog.log("load.nilURL")
                        Task { @MainActor in
                            self.onStatusChange("error")
                        }
                    }
                    continuation.resume()
                }
            }
        }

        @available(iOS 14.0, *)
        private func requestData(provider: NSItemProvider, requestedType: String) async {
            let start = Date()
            IsolationDiagnosticLog.log("load.started")
            await withCheckedContinuation { continuation in
                provider.loadDataRepresentation(forTypeIdentifier: requestedType) { data, error in
                    let elapsed = Date().timeIntervalSince(start)
                    IsolationDiagnosticLog.log("load.callback elapsed=\(IsolationDiagnosticLog.formatElapsed(elapsed))")
                    if let data {
                        IsolationDiagnosticLog.log("load.success bytes=\(data.count)")
                        Task { @MainActor in
                            self.onStatusChange("success")
                        }
                    } else if let error {
                        let nsError = error as NSError
                        IsolationDiagnosticLog.log("load.error domain=\(nsError.domain) code=\(nsError.code)")
                        Task { @MainActor in
                            self.onStatusChange("error")
                        }
                    } else {
                        IsolationDiagnosticLog.log("load.nilURL")
                        Task { @MainActor in
                            self.onStatusChange("error")
                        }
                    }
                    continuation.resume()
                }
            }
        }

        @available(iOS 14.0, *)
        private func logProvider(_ provider: NSItemProvider) {
            IsolationDiagnosticLog.log("provider.registeredTypes = \(provider.registeredTypeIdentifiers)")
            IsolationDiagnosticLog.log("provider.isLivePhoto = \(provider.canLoadObject(ofClass: PHLivePhoto.self))")
            IsolationDiagnosticLog.log("provider.hasJPEG = \(provider.hasItemConformingToTypeIdentifier("public.jpeg"))")
            IsolationDiagnosticLog.log("provider.hasHEIC = \(provider.hasItemConformingToTypeIdentifier("public.heic"))")
            IsolationDiagnosticLog.log("provider.hasPNG = \(provider.hasItemConformingToTypeIdentifier("public.png"))")
        }

        @available(iOS 14.0, *)
        private func resolvedRequestedType(for provider: NSItemProvider) -> String? {
            if let requestedTypeOverride = configuration.requestedTypeOverride {
                return provider.hasItemConformingToTypeIdentifier(requestedTypeOverride) ? requestedTypeOverride : nil
            }

            for identifier in provider.registeredTypeIdentifiers {
                guard identifier != "public.image" else { continue }
                guard !identifier.hasPrefix("com.apple.private.photos.thumbnail.") else { continue }
                if let type = UTType(identifier), type.conforms(to: .image) {
                    return identifier
                }
            }

            return provider.hasItemConformingToTypeIdentifier("public.image") ? "public.image" : nil
        }
    }

    @available(iOS 14.0, *)
    private static func assetRepresentationMode(for mode: IsolationDiagnosticPreset.RepresentationMode) -> PHPickerConfiguration.AssetRepresentationMode? {
        switch mode {
        case .defaultUnset:
            return nil
        case .automatic:
            return .automatic
        case .current:
            return .current
        case .compatible:
            return .compatible
        }
    }
}

private enum IsolationDiagnosticLog {
    static func log(_ message: String) {
        print("[Isolation] \(message)")
    }

    static func formatElapsed(_ elapsed: TimeInterval) -> String {
        String(format: "%.3f", elapsed)
    }
}
#endif
