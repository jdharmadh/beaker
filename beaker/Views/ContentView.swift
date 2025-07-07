import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject var appVM: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Spacer(minLength: 0)
                SettingsMenuView(selectedMode: $appVM.selectedMode)
            }
            
            // Main content directly in the same VStack
            switch appVM.selectedMode {
            case .command:
                CommandModeView(viewModel: appVM.commandVM)
            case .chat:
                ChatModeView(viewModel: appVM.chatVM)
            case .none:
                EmptyView()
            }
            
            Spacer()
        }
        .padding() // Single padding for the entire VStack
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size) { newSize in
                        resizeWindow(to: newSize)
                    }
            }
        )
        .frame(minWidth: 1, minHeight: 1)
    }

    @ViewBuilder
    var content: some View {
        VStack(spacing: 12) {
            switch appVM.selectedMode {
            case .command:
                CommandModeView(viewModel: appVM.commandVM)
            case .chat:
                ChatModeView(viewModel: appVM.chatVM)
            case .none:
                EmptyView()
            }
        }
        .padding()
    }

    private func resizeWindow(to size: CGSize) {
        guard let window = NSApp.windows.first else { return }
        var frame = window.frame

        let contentHeight = window.contentView?.frame.height ?? 0
        let contentWidth = window.contentView?.frame.width ?? 0

        let deltaHeight = size.height - contentHeight
        let deltaWidth = size.width - contentWidth

        frame.size.height += deltaHeight
        frame.size.width += deltaWidth
        frame.origin.y -= deltaHeight // Move origin up to keep top edge fixed

        window.setFrame(frame, display: true, animate: true)
    }
}



