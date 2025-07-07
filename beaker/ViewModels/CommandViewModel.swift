import Foundation
import Combine

class CommandViewModel: ObservableObject {
    @Published var currentCommand: RunnableCommand = TerminalCommand(command: "", plaintext: "")

    var cancellables = Set<AnyCancellable>()
    let provider: CommandProvider

    init(provider: CommandProvider) {
        self.provider = provider

        let commands = provider.getCommands()
        self.currentCommand = commands.first ?? TerminalCommand(command: "", plaintext: "")

        if let dynamic = provider as? DynamicCommandProvider {
            dynamic.$commands
                .compactMap { $0.first }
                .map { $0 as RunnableCommand }
                .receive(on: DispatchQueue.main)
                .assign(to: \.currentCommand, on: self)
                .store(in: &cancellables)
        }
    }

    func runCurrentCommand() {
        currentCommand.run()
    }
}

