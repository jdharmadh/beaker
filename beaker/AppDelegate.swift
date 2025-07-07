import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            let appVM = await AppViewModel.create()
            let contentView = ContentView(appVM: appVM)

            window = FocusableWindow(
                contentRect: NSRect(x: NSScreen.main!.visibleFrame.maxX - 400,
                                    y: NSScreen.main!.visibleFrame.maxY - 360,
                                    width: 400,
                                    height: 350),
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
            window.isReleasedWhenClosed = false
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.hasShadow = true
            

            window.contentView = NSHostingView(rootView: contentView)
            
            window.contentResizeIncrements = NSSize(width: 1, height: 1)
            window.styleMask.insert(.resizable) // Required for autoresize to work

            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(nil) // Ensure text fields can get focus
        }
    }
}
