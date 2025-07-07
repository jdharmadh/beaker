import Foundation

protocol RunnableCommand {
    var plaintext: String { get }
    func run()
}

struct TerminalCommand: RunnableCommand, Decodable {
    let command: String
    let plaintext: String

    func run() {
        let script = """
        tell application "Terminal"
            activate
            if (count of windows) > 0 then
                do script "\(command)" in front window
            else
                do script "\(command)"
            end if
        end tell
        """
        runAppleScript(script)
    }
}

struct FileOpenCommand: RunnableCommand, Decodable {
    let filePath: String
    let plaintext: String

    func run() {
        let script = "tell application \"Finder\" to open POSIX file \"\(filePath)\""
        runAppleScript(script)
    }
}

struct ShowDesktopCommand: RunnableCommand, Decodable {
    let plaintext: String = "Show the desktop by hiding all apps"

    func run() {
        let script = """
        tell application "System Events"
            set visible of every process whose visible is true and name is not "Finder" to false
        end tell
        """
        runAppleScript(script)
    }
}

struct MuteVolumeCommand: RunnableCommand, Decodable {
    let plaintext: String = "Mute the system volume"

    func run() {
        let script = "set volume with output muted"
        runAppleScript(script)
    }
}

struct LaunchAppCommand: RunnableCommand, Decodable {
    let appName: String
    let plaintext: String

    func run() {
        let script = "tell application \"\(appName)\" to activate"
        runAppleScript(script)
    }
}

struct SetVolumeCommand: RunnableCommand, Decodable {
    let volume: Int
    let plaintext: String

    func run() {
        let clampedVolume = max(0, min(100, volume))
        let script = "set volume output volume \(clampedVolume)"
        runAppleScript(script)
    }
}

struct QuitAppCommand: RunnableCommand, Decodable {
    let appName: String
    let plaintext: String

    func run() {
        let script = "tell application \"\(appName)\" to quit"
        runAppleScript(script)
    }
}

struct SleepCommand: RunnableCommand, Decodable {
    let plaintext: String = "Put the computer to sleep"

    func run() {
        let script = """
        tell application "System Events"
            sleep
        end tell
        """
        runAppleScript(script)
    }
}

struct NotificationCommand: RunnableCommand, Decodable {
    let title: String
    let message: String
    let plaintext: String

    func run() {
        let script = """
        display notification "\(message)" with title "\(title)"
        """
        runAppleScript(script)
    }
}

private func runAppleScript(_ script: String) {
    let process = Process()
    process.launchPath = "/usr/bin/osascript"
    process.arguments = ["-e", script]
    process.launch()
}
