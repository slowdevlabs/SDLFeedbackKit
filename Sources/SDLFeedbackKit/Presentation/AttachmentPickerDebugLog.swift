#if DEBUG
import Foundation

enum AttachmentPickerDebugLog {
    static func log(_ message: String) {
        print("[SDLFeedbackKit] \(message)")
    }
}
#else
enum AttachmentPickerDebugLog {
    static func log(_ message: String) {}
}
#endif
