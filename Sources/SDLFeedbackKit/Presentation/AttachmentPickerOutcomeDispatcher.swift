import Foundation

struct AttachmentPickerOutcomeDispatcher {
    let selectionID: UUID?
    let dismissPicker: () -> Void
    let processData: (Data, UUID) async -> Void
    let processFile: (URL, UUID) async -> Void
    let reportFailure: (FeedbackError, UUID) -> Void

    func dispatch(_ outcome: AttachmentPickerOutcome) async {
        switch outcome {
        case let .selected(data):
            guard let selectionID else {
                AttachmentPickerDebugLog.log("picker.outcome.selected.dropped id=nil")
                return
            }
            AttachmentPickerDebugLog.log("picker.outcome.selected.dispatch id=\(selectionID.uuidString) bytes=\(data.count)")
            await processData(data, selectionID)
        case let .selectedFile(fileURL):
            guard let selectionID else {
                AttachmentPickerDebugLog.log("picker.outcome.selectedFile.dropped id=nil")
                return
            }
            AttachmentPickerDebugLog.log("picker.outcome.selectedFile.dispatch id=\(selectionID.uuidString) path=\(fileURL.lastPathComponent)")
            await processFile(fileURL, selectionID)
        case let .failed(error):
            guard let selectionID else {
                AttachmentPickerDebugLog.log("picker.outcome.failed.dropped id=nil")
                return
            }
            AttachmentPickerDebugLog.log("picker.outcome.failed.dispatch id=\(selectionID.uuidString) error=\(error)")
            reportFailure(error, selectionID)
        case .cancelled:
            dismissPicker()
            break
        }
    }
}
