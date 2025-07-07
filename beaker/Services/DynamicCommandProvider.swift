import Foundation
import Combine
import AppKit
class DynamicCommandProvider: ObservableObject, CommandProvider {
    @Published private(set) var commands: [RunnableCommand] = []
    private var timer: Timer?
    private let apiClient: GroqAPIClient

    init(apiClient: GroqAPIClient) {
        self.apiClient = apiClient
    }

    func getCommands() -> [RunnableCommand] {
        return commands
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchNewCommand()
            }
        }
        timer?.fire()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func fetchNewCommand() async {
        do {
            let screenshotURL = try await ScreenshotHelper.takeScreenshot()
            let prompt = Self.systemPrompt
            let response = try await apiClient.callImageModel(withImageAt: screenshotURL, prompt: prompt)

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
      "type": "terminal" | "fileOpen" | "showDesktop" | "muteVolume" | "launchApp" | "setVolume" | "quitApp" | "sleep" | "notification",
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

    5. launchApp:
       {
         "type": "launchApp",
         "input": { 
           "appName": "Application Name"
         },
         "plaintext": "Launch Application Name"
       }

    6. setVolume:
       {
         "type": "setVolume",
         "input": { 
           "volume": "50"
         },
         "plaintext": "Set volume to 50%"
       }

    7. quitApp:
       {
         "type": "quitApp",
         "input": { 
           "appName": "Application Name"
         },
         "plaintext": "Quit Application Name"
       }

    8. sleep:
       {
         "type": "sleep",
         "input": {},
         "plaintext": "Put computer to sleep"
       }

    9. notification:
       {
         "type": "notification",
         "input": { 
           "title": "Notification Title",
           "message": "Notification message"
         },
         "plaintext": "Show notification"
       }

    ANALYSIS GUIDELINES:
    - Analyze what the user is likely trying to accomplish based on screen content
    - Look for visible applications, file browsers, terminal windows, error messages, etc.
    - Consider the current context and suggest the most helpful next action
    - Ignore a small translucent blob translating an action - that is you, don't copy that action again!
    - For terminal commands, suggest commonly useful commands like:
      * File operations: ls, cd, mkdir, rm, cp, mv
      * System info: ps, top, df, du, whoami
      * Text processing: cat, grep, find, head, tail
      * Network: ping, curl, wget
    - For file paths, use realistic Unix-style paths starting with /
    - For app names, use common macOS applications like "Safari", "Finder", "Terminal", "Xcode", etc.
    - For volume levels, use integers between 0-100
    - Keep plaintext descriptions concise and actionable (under 60 characters)

    VALIDATION CHECKLIST:
    Before responding, ensure:
    □ Response starts with { and ends with }
    □ All strings are properly quoted
    □ No trailing commas
    □ Type field matches one of the nine allowed values exactly
    □ Input object structure matches the specified format for the chosen type
    □ Plaintext is a brief, imperative description
    □ No extra text, formatting, or tokens anywhere in the response

    EXAMPLE VALID RESPONSES:

    {"type": "fileOpen", "input": {"filePath": "/Users/jay/Documents/report.pdf"}, "plaintext": "Open PDF report"}

    {"type": "showDesktop", "input": {}, "plaintext": "Show desktop"}

    {"type": "muteVolume", "input": {}, "plaintext": "Mute system volume"}

    {"type": "launchApp", "input": {"appName": "Safari"}, "plaintext": "Launch Safari"}

    {"type": "setVolume", "input": {"volume": "75"}, "plaintext": "Set volume to 75%"}

    {"type": "quitApp", "input": {"appName": "Xcode"}, "plaintext": "Quit Xcode"}

    {"type": "sleep", "input": {}, "plaintext": "Put computer to sleep"}

    {"type": "notification", "input": {"title": "Reminder", "message": "Take a break"}, "plaintext": "Show break reminder"}
    
    {"type": "terminal", "input": {"command": "ls -la"}, "plaintext": "List files and directories with details"}


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

            case "launchApp":
                guard let appName = wrapper.input["appName"] else { return nil }
                return LaunchAppCommand(appName: appName, plaintext: wrapper.plaintext)

            case "setVolume":
                guard let volumeString = wrapper.input["volume"],
                      let volume = Int(volumeString) else { return nil }
                return SetVolumeCommand(volume: volume, plaintext: wrapper.plaintext)

            case "quitApp":
                guard let appName = wrapper.input["appName"] else { return nil }
                return QuitAppCommand(appName: appName, plaintext: wrapper.plaintext)

            case "sleep":
                return SleepCommand()

            case "notification":
                guard let title = wrapper.input["title"],
                      let message = wrapper.input["message"] else { return nil }
                return NotificationCommand(title: title, message: message, plaintext: wrapper.plaintext)

            default:
                return nil
            }
        } catch {
            return nil
        }
    }
}
