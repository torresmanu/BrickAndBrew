import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageJPEGProcessor {
    static let avatarMaxPixelSize = 512
    static let beerPhotoMaxPixelSize = 1080
    static let jpegQuality: CGFloat = 0.8

    enum ProcessorError: LocalizedError {
        case invalidImage
        case encodingFailed

        var errorDescription: String? {
            "We couldn't read that photo. Try another one."
        }
    }

    /// Decodes with EXIF orientation applied, optionally center-crops to a square,
    /// then caps the longest edge.
    static func makeJPEG(from data: Data, maxPixelSize: Int, squareCrop: Bool) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ProcessorError.invalidImage
        }

        let decodeOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2048
        ]
        guard let decoded = CGImageSourceCreateThumbnailAtIndex(source, 0, decodeOptions as CFDictionary) else {
            throw ProcessorError.invalidImage
        }

        let prepared = squareCrop ? squareCropped(decoded) : decoded
        let sized = scaledToFit(prepared, maxPixelSize: maxPixelSize)
        return try encodeJPEG(sized)
    }

    private static func squareCropped(_ image: CGImage) -> CGImage {
        let width = image.width
        let height = image.height
        let side = min(width, height)
        guard side > 0 else { return image }
        let xOffset = (width - side) / 2
        let yOffset = (height - side) / 2
        let rect = CGRect(x: xOffset, y: yOffset, width: side, height: side)
        return image.cropping(to: rect) ?? image
    }

    private static func scaledToFit(_ image: CGImage, maxPixelSize: Int) -> CGImage {
        let width = image.width
        let height = image.height
        let longest = max(width, height)
        guard longest > maxPixelSize else { return image }

        let scale = CGFloat(maxPixelSize) / CGFloat(longest)
        let newWidth = max(1, Int((CGFloat(width) * scale).rounded()))
        let newHeight = max(1, Int((CGFloat(height) * scale).rounded()))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return image
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage() ?? image
    }

    private static func encodeJPEG(_ image: CGImage) throws -> Data {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ProcessorError.encodingFailed
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: jpegQuality
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessorError.encodingFailed
        }
        return mutableData as Data
    }
}
