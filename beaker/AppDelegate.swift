import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let provider = DynamicCommandProvider(apiClient: GroqAPIClient())
//        let provider = StaticCommandProvider()
        let viewModel = CommandViewModel(provider: provider)
        let contentView = ContentView(viewModel: viewModel)

        window = NSWindow(
            contentRect: NSRect(x: NSScreen.main!.visibleFrame.maxX - 400,
                                y: NSScreen.main!.visibleFrame.maxY - 200,
                                width: 210,  // wider width
                                height: 150),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )


        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.hasShadow = true

        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
}
