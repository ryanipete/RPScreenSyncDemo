import Foundation
import UIKit
import ReplayKit

final class ScreenRecorder: NSObject {

    static let screenshotDirectoryURL = documentDirectoryURL.appendingPathComponent("screenshots", isDirectory: true)
    private static let documentDirectoryURL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0]
    var isRecording: Bool {
        recorder.isRecording
    }
    private let recorder = RPScreenRecorder.shared()
    private var frame = 0

    func start(completion: @escaping () -> Void) {

        guard !recorder.isRecording else {
            return
        }

        resetDirectory()
        recorder.startCapture(handler: { buffer, bufferType, error in
            if let error = error {
                print("Error during capture: \(error)")
            }

            switch bufferType {
            case .video:
                guard let imageBuffer = buffer.imageBuffer else {
                    return
                }
                CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)

                assert(buffer.isValid)
                assert(buffer.dataReadiness == .ready)
                assert(buffer.presentationTimeStamp.timescale == 1_000_000_000)
                assert(buffer.presentationTimeStamp == buffer.outputPresentationTimeStamp)
                assert(buffer.decodeTimeStamp.seconds.isNaN)
                assert(buffer.outputDecodeTimeStamp.seconds.isNaN)
                assert(buffer.duration.seconds.isNaN)

                assert(buffer.numSamples == 1)
                let sampleTimingInfo = try! buffer.sampleTimingInfo(at: 0)
                assert(sampleTimingInfo.decodeTimeStamp == buffer.decodeTimeStamp)
                assert(sampleTimingInfo.presentationTimeStamp == buffer.presentationTimeStamp)
                assert(sampleTimingInfo.duration == buffer.duration)

                autoreleasepool {
                    let ciImage = CIImage(cvImageBuffer: imageBuffer)
                    let uiImage = UIImage(ciImage: ciImage)
                    let data = uiImage.jpegData(compressionQuality: 0.5)
                    let filename = String(format: "%.3f", buffer.presentationTimeStamp.seconds)
                    let url = Self.screenshotDirectoryURL.appendingPathComponent(filename)
                    FileManager.default.createFile(atPath: url.path, contents: data)
                }

                CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            default:
                break
            }
        }, completionHandler: { error in
            if let error = error {
                print("Error while starting capture: \(error)")
            } else {
                print("Capture started successfully")
            }
            completion()
        })
    }

    func stop(completion: @escaping () -> Void) {
        guard recorder.isRecording else {
            return
        }
        recorder.stopCapture { error in
            if let error = error {
                print("Error while stopping capture: \(error)")
            }
            completion()
        }
    }

    private func resetDirectory() {
        deleteItem(at: Self.screenshotDirectoryURL)
        createDirectory(at: Self.screenshotDirectoryURL)
    }

    private func deleteItem(at url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch  {
                print("Failed to remove item at \(url): \(error)")
            }
        }
    }

    private func createDirectory(at url: URL) {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print("Failed to create directory at \(url): \(error)")
        }
    }
}
