import Foundation

struct Command: Decodable {
    let command: String
    let plaintext: String
}

protocol CommandProvider {
    func getCommands() -> [RunnableCommand]
}
