#if canImport(SwiftUI)
import SwiftUI

struct AttachmentPickerHost: View {
    let onOutcome: (AttachmentPickerOutcome) -> Void

    var body: some View {
        PlatformAttachmentPickerView(onOutcome: onOutcome)
    }
}
#endif
