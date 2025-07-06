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

private func runAppleScript(_ script: String) {
    let process = Process()
    process.launchPath = "/usr/bin/osascript"
    process.arguments = ["-e", script]
    process.launch()
}
