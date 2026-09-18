import Foundation
import UIKit

/// Disk cache for crew avatars. CloudKit asset temp files disappear after fetch,
/// so JPEG bytes are copied here and keyed by profile id.
@MainActor
@Observable
final class AvatarCache {
    private(set) var generation: Int = 0
    private var images: [String: UIImage] = [:]

    private let fileManager: FileManager
    private let directory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = support.appendingPathComponent("Avatars", isDirectory: true)
    }

    func image(for userId: String) -> UIImage? {
        if let cached = images[userId] {
            return cached
        }
        guard let url = fileURLIfPresent(for: userId),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        images[userId] = image
        return image
    }

    func store(userId: String, jpeg: Data) {
        guard userId.isEmpty == false, jpeg.isEmpty == false else { return }
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try jpeg.write(to: fileURL(for: userId), options: .atomic)
            images[userId] = UIImage(data: jpeg)
            generation += 1
        } catch {
            return
        }
    }

    func remove(userId: String) {
        let hadImage = images[userId] != nil || fileURLIfPresent(for: userId) != nil
        images[userId] = nil
        try? fileManager.removeItem(at: fileURL(for: userId))
        if hadImage {
            generation += 1
        }
    }

    func removeAll() {
        images.removeAll()
        try? fileManager.removeItem(at: directory)
        generation += 1
    }

    private func fileURL(for userId: String) -> URL {
        let safe = userId.replacingOccurrences(of: "/", with: "-")
        return directory.appendingPathComponent("\(safe).jpg")
    }

    private func fileURLIfPresent(for userId: String) -> URL? {
        let url = fileURL(for: userId)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return url
    }
}
