import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var latestResponse: String? = nil
    private let apiClient = GroqAPIClient()

    func sendMessage(_ message: String) {
        Task {
            do {
                let prompt = "Answer the question: \(message)"
                let response = try await apiClient.callModel(prompt: prompt)
                latestResponse = response
            } catch {
                latestResponse = "Error: \(error.localizedDescription)"
            }
        }
    }
}
