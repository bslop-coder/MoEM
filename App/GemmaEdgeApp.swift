import SwiftUI

@main
struct GemmaEdgeApp: App {
    var body: some Scene {
        WindowGroup {
            Phase1DiagnosticsView()
                .preferredColorScheme(.dark)
        }
    }
}
