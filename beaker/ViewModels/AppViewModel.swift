import SwiftUI
import Foundation
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var selectedMode: ModeType = .none {
        didSet {
            updateModeState()
        }
    }

    let commandVM: CommandViewModel
    let chatVM: ChatViewModel

    private init(commandVM: CommandViewModel, chatVM: ChatViewModel) {
        self.commandVM = commandVM
        self.chatVM = chatVM
    }

    static func create() async -> AppViewModel {
        let apiClient = GroqAPIClient()
        let provider = DynamicCommandProvider(apiClient: apiClient)
        let commandVM = CommandViewModel(provider: provider)
        let chatVM = ChatViewModel()
        let appVM = AppViewModel(commandVM: commandVM, chatVM: chatVM)
        appVM.updateModeState()
        return appVM
    }

    private func updateModeState() {
        if let dynamic = commandVM.provider as? DynamicCommandProvider {
            if selectedMode == .command {
                dynamic.start()
            } else {
                dynamic.stop()
            }
        }
    }

    func switchTo(_ mode: ModeType) {
        selectedMode = mode
    }
}
