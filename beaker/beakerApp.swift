import SwiftUI

@main
struct beakerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No default WindowGroup — window will be managed manually
        Settings {
            EmptyView()
        }
    }
}
