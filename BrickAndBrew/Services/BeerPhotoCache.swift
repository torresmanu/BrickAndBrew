import Foundation
import UIKit

/// Disk cache for pint photos. CloudKit asset temp files disappear after fetch,
/// so JPEG bytes are copied here and keyed by beer id.
@MainActor
@Observable
final class BeerPhotoCache {
    private(set) var generation: Int = 0
    private var images: [String: UIImage] = [:]

    private let fileManager: FileManager
    private let directory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = support.appendingPathComponent("BeerPhotos", isDirectory: true)
    }

    func image(for beerId: String) -> UIImage? {
        if let cached = images[beerId] {
            return cached
        }
        guard let url = fileURLIfPresent(for: beerId),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        images[beerId] = image
        return image
    }

    func store(beerId: String, jpeg: Data) {
        guard beerId.isEmpty == false, jpeg.isEmpty == false else { return }
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try jpeg.write(to: fileURL(for: beerId), options: .atomic)
            images[beerId] = UIImage(data: jpeg)
            generation += 1
        } catch {
            return
        }
    }

    func remove(beerId: String) {
        let hadImage = images[beerId] != nil || fileURLIfPresent(for: beerId) != nil
        images[beerId] = nil
        try? fileManager.removeItem(at: fileURL(for: beerId))
        if hadImage {
            generation += 1
        }
    }

    func removeAll() {
        images.removeAll()
        try? fileManager.removeItem(at: directory)
        generation += 1
    }

    private func fileURL(for beerId: String) -> URL {
        let safe = beerId.replacingOccurrences(of: "/", with: "-")
        return directory.appendingPathComponent("\(safe).jpg")
    }

    private func fileURLIfPresent(for beerId: String) -> URL? {
        let url = fileURL(for: beerId)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return url
    }
}
