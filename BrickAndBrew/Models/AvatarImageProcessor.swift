import Foundation

enum AvatarImageProcessor {
    static let maxPixelSize = ImageJPEGProcessor.avatarMaxPixelSize

    typealias ProcessorError = ImageJPEGProcessor.ProcessorError

    /// Center-crops to a square, caps at 512px, and returns JPEG bytes.
    static func makeAvatarJPEG(from data: Data) throws -> Data {
        try ImageJPEGProcessor.makeJPEG(
            from: data,
            maxPixelSize: ImageJPEGProcessor.avatarMaxPixelSize,
            squareCrop: true
        )
    }

    /// First letters of the first two words, or "?" when the name is empty.
    static func initials(from displayName: String) -> String {
        let parts = displayName
            .split { $0.isWhitespace || $0.isNewline }
            .prefix(2)
        let letters = parts.compactMap { part -> String? in
            guard let first = part.first else { return nil }
            return String(first).uppercased()
        }
        return letters.isEmpty ? "?" : letters.joined()
    }
}
