import Foundation

@MainActor
class GroqAPIClient {
    let apiKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"] ?? ""
    
    func callModel(withImageAt imageURL: URL, prompt: String) async throws -> String {
        guard let imageData = try? Data(contentsOf: imageURL) else {
            throw NSError(domain: "GroqAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to read image data"])
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Create the request payload
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": prompt
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "meta-llama/llama-4-scout-17b-16e-instruct",
            "messages": messages,
            "temperature": 0.7
        ]
        
        // Create URL and request
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            throw NSError(domain: "GroqAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw NSError(domain: "GroqAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request body"])
        }
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GroqAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "GroqAPIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "GroqAPIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return content
    }
}
