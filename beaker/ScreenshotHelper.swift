import Foundation
import ScreenCaptureKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers

class ScreenshotHelper {
    static func takeScreenshot() async throws -> URL {
        // Load available displays
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        guard let display = content.displays.first else {
            throw NSError(domain: "ScreenshotHelper", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No displays found"])
        }

        // Create filter for that display
        guard let ownAppBundleID = Bundle.main.bundleIdentifier else {
            throw NSError(domain: "ScreenshotHelper", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to get bundle ID"])
        }

        let ownApp = content.applications.first { $0.bundleIdentifier == ownAppBundleID }

        let filter = SCContentFilter(
            display: display,
            excludingApplications: ownApp != nil ? [ownApp!] : [],
            exceptingWindows: []
        )


        // Use the recommended preset for screenshots
        let config = SCStreamConfiguration(preset: .captureHDRScreenshotLocalDisplay)

        // Capture a CMSampleBuffer
        let sampleBuffer = try await SCScreenshotManager.captureSampleBuffer(
            contentFilter: filter,
            configuration: config
        )

        // Extract image buffer
        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            throw NSError(domain: "ScreenshotHelper", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "No image buffer in screenshot"])
        }

        // Convert to CGImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw NSError(domain: "ScreenshotHelper", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])
        }

        // Save as PNG in current directory
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("picture.png")

        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw NSError(domain: "ScreenshotHelper", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"])
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "ScreenshotHelper", code: 5,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to write PNG"])
        }

        return fileURL
    }
}
