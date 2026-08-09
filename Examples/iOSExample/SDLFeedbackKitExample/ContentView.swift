import SwiftUI
import SDLFeedbackKit

struct ContentView: View {
    @State private var isPresentingFeedback = false
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
                isPresentingFeedback = true
            }

            Text(statusMessage)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .sheet(isPresented: $isPresentingFeedback) {
            FeedbackFormView(
                context: feedbackContext,
                transport: ExampleFeedbackTransport(mode: submissionMode),
                onSubmitted: { result in
                    statusMessage = "Submitted: \(result.clientID.uuidString.prefix(8))"
                    isPresentingFeedback = false
                },
                onCancelled: {
                    statusMessage = "Cancelled"
                    isPresentingFeedback = false
                }
            )
        }
    }
}
