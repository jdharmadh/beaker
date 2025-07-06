import Foundation
import Combine
import AppKit

class DynamicCommandProvider: ObservableObject, CommandProvider {
    @Published private(set) var commands: [RunnableCommand] = []

    private var timer: Timer?
    private let apiClient: GroqAPIClient

    init(apiClient: GroqAPIClient) {
        self.apiClient = apiClient
        startPolling()
    }

    func getCommands() -> [RunnableCommand] {
        return commands
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchNewCommand()
            }
        }
        timer?.fire()
    }

    func fetchNewCommand() async {
        do {
            let screenshotURL = try await ScreenshotHelper.takeScreenshot()
            let prompt = Self.systemPrompt
            let response = try await apiClient.callModel(withImageAt: screenshotURL, prompt: prompt)

            if let command = Self.parseCommand(from: response) {
                DispatchQueue.main.async {
                    self.commands = [command]
                }
            } else {
                print("Failed to parse JSON from model response:\n\(response)")
            }
        } catch {
            print("Error fetching new command: \(error)")
        }
    }

    static let systemPrompt = """
    You are a screen analysis assistant that examines images of user screens and recommends appropriate commands to execute.

    CRITICAL OUTPUT REQUIREMENTS:
    - Your response MUST be valid JSON only
    - Do NOT include any text before or after the JSON
    - Do NOT include markdown code blocks, backticks, or formatting
    - Do NOT include explanatory text, comments, or additional context
    - Do NOT include any header tokens, chat formatting, or special characters
    - Your entire response must be parseable by a JSON parser

    REQUIRED JSON FORMAT:
    {
      "type": "terminal" | "fileOpen" | "showDesktop" | "muteVolume",
      "input": { ... },
      "plaintext": "A short imperative description of what the command does."
    }

    COMMAND TYPES AND THEIR EXACT INPUT FORMATS:

    1. terminal:
       {
         "type": "terminal",
         "input": { 
           "command": "exact_command_string_here"
         },
         "plaintext": "Brief description of what this terminal command does"
       }

    2. fileOpen:
       {
         "type": "fileOpen",
         "input": { 
           "filePath": "/full/absolute/path/to/file.ext"
         },
         "plaintext": "Brief description of what file will be opened"
       }

    3. showDesktop:
       {
         "type": "showDesktop",
         "input": {},
         "plaintext": "Show the desktop"
       }

    4. muteVolume:
       {
         "type": "muteVolume",
         "input": {},
         "plaintext": "Mute system volume"
       }

    ANALYSIS GUIDELINES:
    - Analyze what the user is likely trying to accomplish based on screen content
    - Look for visible applications, file browsers, terminal windows, error messages, etc.
    - Consider the current context and suggest the most helpful next action
    - For terminal commands, suggest commonly useful commands like:
      * File operations: ls, cd, mkdir, rm, cp, mv
      * System info: ps, top, df, du, whoami
      * Text processing: cat, grep, find, head, tail
      * Network: ping, curl, wget
    - For file paths, use realistic Unix-style paths starting with /
    - Keep plaintext descriptions concise and actionable (under 60 characters)

    VALIDATION CHECKLIST:
    Before responding, ensure:
    □ Response starts with { and ends with }
    □ All strings are properly quoted
    □ No trailing commas
    □ Type field matches one of the four allowed values exactly
    □ Input object structure matches the specified format for the chosen type
    □ Plaintext is a brief, imperative description
    □ No extra text, formatting, or tokens anywhere in the response

    EXAMPLE VALID RESPONSES:

    {"type": "terminal", "input": {"command": "ls -la"}, "plaintext": "List files and directories with details"}

    {"type": "fileOpen", "input": {"filePath": "/Users/jay/Documents/report.pdf"}, "plaintext": "Open PDF report"}

    {"type": "showDesktop", "input": {}, "plaintext": "Show desktop"}

    {"type": "muteVolume", "input": {}, "plaintext": "Mute system volume"}

    Remember: Your response must be valid JSON that can be parsed directly. Any deviation from this format will cause system errors.
    """

    static func parseCommand(from response: String) -> RunnableCommand? {
        guard let data = response.data(using: .utf8) else { return nil }

        struct Wrapper: Decodable {
            let type: String
            let input: [String: String]
            let plaintext: String
        }

        do {
            let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
            print(wrapper)

            switch wrapper.type {
            case "terminal":
                guard let cmd = wrapper.input["command"] else { return nil }
                return TerminalCommand(command: cmd, plaintext: wrapper.plaintext)

            case "fileOpen":
                guard let path = wrapper.input["filePath"] else { return nil }
                return FileOpenCommand(filePath: path, plaintext: wrapper.plaintext)

            case "showDesktop":
                return ShowDesktopCommand()

            case "muteVolume":
                return MuteVolumeCommand()

            default:
                return nil
            }
        } catch {
            return nil
        }
    }
}
