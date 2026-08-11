#if canImport(SwiftUI)
import SwiftUI

struct AttachmentPickerHost: View {
    let onSelectionAccepted: () -> Void
    let onOutcome: (AttachmentPickerOutcome) -> Void

    var body: some View {
        PlatformAttachmentPickerView(onSelectionAccepted: onSelectionAccepted, onOutcome: onOutcome)
    }
}
#endif
