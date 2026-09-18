import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import BrickAndBrew

struct AvatarImageProcessorTests {
    @Test func initialsUseFirstLettersOfFirstTwoWords() {
        #expect(AvatarImageProcessor.initials(from: "Alex Rivera") == "AR")
        #expect(AvatarImageProcessor.initials(from: "Alex") == "A")
        #expect(AvatarImageProcessor.initials(from: "  ") == "?")
        #expect(AvatarImageProcessor.initials(from: "") == "?")
    }

    @Test func cropsNonSquareImageToSquareJPEGWithinMaxSize() throws {
        let source = try makeTestJPEG(width: 80, height: 40)
        let jpeg = try AvatarImageProcessor.makeAvatarJPEG(from: source)
        let image = try imageFromJPEG(jpeg)
        #expect(image.width == image.height)
        #expect(image.width <= AvatarImageProcessor.maxPixelSize)
    }

    @Test func downscalesLargeSquareToMaxPixelSize() throws {
        let source = try makeTestJPEG(width: 800, height: 800)
        let jpeg = try AvatarImageProcessor.makeAvatarJPEG(from: source)
        let image = try imageFromJPEG(jpeg)
        #expect(image.width == AvatarImageProcessor.maxPixelSize)
        #expect(image.height == AvatarImageProcessor.maxPixelSize)
    }
}

struct BeerPhotoProcessorTests {
    @Test func keepsAspectRatioAndCapsLongestEdge() throws {
        let source = try makeTestJPEG(width: 160, height: 80)
        let jpeg = try ImageJPEGProcessor.makeJPEG(
            from: source,
            maxPixelSize: ImageJPEGProcessor.beerPhotoMaxPixelSize,
            squareCrop: false
        )
        let image = try imageFromJPEG(jpeg)
        #expect(image.width != image.height)
        #expect(max(image.width, image.height) <= ImageJPEGProcessor.beerPhotoMaxPixelSize)
        #expect(image.width / image.height == 2)
    }

    @Test func downscalesLongestEdgeTo1080() throws {
        let source = try makeTestJPEG(width: 2160, height: 1080)
        let jpeg = try ImageJPEGProcessor.makeJPEG(
            from: source,
            maxPixelSize: ImageJPEGProcessor.beerPhotoMaxPixelSize,
            squareCrop: false
        )
        let image = try imageFromJPEG(jpeg)
        #expect(image.width == ImageJPEGProcessor.beerPhotoMaxPixelSize)
        #expect(image.height == ImageJPEGProcessor.beerPhotoMaxPixelSize / 2)
    }
}

private func makeTestJPEG(width: Int, height: Int) throws -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw AvatarImageProcessor.ProcessorError.encodingFailed
    }
    context.setFillColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    guard let image = context.makeImage() else {
        throw AvatarImageProcessor.ProcessorError.encodingFailed
    }
    return try encodeJPEG(image)
}

private func imageFromJPEG(_ data: Data) throws -> CGImage {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw AvatarImageProcessor.ProcessorError.invalidImage
    }
    return image
}

private func encodeJPEG(_ image: CGImage) throws -> Data {
    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        mutableData,
        UTType.jpeg.identifier as CFString,
        1,
        nil
    ) else {
        throw AvatarImageProcessor.ProcessorError.encodingFailed
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw AvatarImageProcessor.ProcessorError.encodingFailed
    }
    return mutableData as Data
}
