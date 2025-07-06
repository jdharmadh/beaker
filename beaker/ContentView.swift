import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: CommandViewModel
    @State private var dragStart: CGPoint?
    @State private var dragMoved = false
    @State private var glow = false
    @State private var lastText = ""

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .gesture(dragGesture)

            Text(viewModel.currentCommand.plaintext)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: glow ? Color.accentColor.opacity(0.8) : .clear,
                        radius: glow ? 12 : 0)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if dragStart == nil {
                                dragStart = value.startLocation
                                dragMoved = false
                            }
                            let distance = hypot(value.translation.width, value.translation.height)
                            if distance > 4 {
                                dragMoved = true
                                moveWindow(by: value.translation)
                            }
                        }
                        .onEnded { _ in
                            if !dragMoved {
                                viewModel.runCurrentCommand()
                            }
                            dragStart = nil
                            dragMoved = false
                        }
                )
                .onChange(of: viewModel.currentCommand.plaintext) { newText in
                    lastText = newText
                    withAnimation(.easeOut(duration: 0.4)) {
                        glow = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.easeIn(duration: 0.2)) {
                            glow = false
                        }
                    }
                }
        }
        .frame(minWidth: 50, minHeight: 30)
    }

    private func moveWindow(by translation: CGSize) {
        if let window = NSApp.windows.first {
            let currentOrigin = window.frame.origin
            let newOrigin = CGPoint(
                x: currentOrigin.x + translation.width,
                y: currentOrigin.y - translation.height
            )
            window.setFrameOrigin(newOrigin)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                moveWindow(by: value.translation)
            }
    }
}
