import SwiftUI

struct ChatModeView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var input: String = ""
    @State private var responseOpacity: Double = 0
    @State private var responseScale: CGFloat = 0.8
    @State private var responseOffset: CGFloat = 20
    @State private var responseID = UUID()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Type a command...", text: $input, onCommit: submit)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 14))
                    .disableAutocorrection(true)
                    .background(.ultraThinMaterial)
                    .padding(.horizontal)
            }

            if let response = viewModel.latestResponse {
                ScrollView {
                    Text(response)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(minHeight: 180)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .opacity(responseOpacity)
                .scaleEffect(responseScale)
                .offset(y: responseOffset)
                .id(responseID)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                        responseOpacity = 1
                        responseScale = 1
                        responseOffset = 0
                    }
                }
                .onChange(of: response) { _ in
                    // Reset animation state for new response
                    responseOpacity = 0
                    responseScale = 0.8
                    responseOffset = 20
                    responseID = UUID()
                    
                    // Animate in the new response
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                        responseOpacity = 1
                        responseScale = 1
                        responseOffset = 0
                    }
                }
            }
        }
        .padding(.vertical)
    }

    private func submit() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        viewModel.sendMessage(input)
        input = ""
    }
}
