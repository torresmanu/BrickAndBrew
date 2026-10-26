import Photos
import SwiftUI
import UIKit

/// Renders a finisher card to a PNG and optionally writes it to Photos.
enum FinisherImageExport {
    @MainActor
    static func render(finish: TriathlonFinish, format: FinisherCardFormat) throws -> UIImage {
        let card = FinisherCardView(finish: finish, format: format)
            .frame(width: format.designSize.width, height: format.designSize.height)
        let renderer = ImageRenderer(content: card)
        renderer.scale = format.exportScale
        renderer.proposedSize = ProposedViewSize(format.designSize)
        guard let image = renderer.uiImage else {
            throw BrickError.finisherRenderFailed
        }
        return image
    }

    static func saveToPhotos(_ image: UIImage) async throws {
        let status = await requestedAddAccess()
        guard status == .authorized || status == .limited else {
            throw BrickError.photosDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    private static func requestedAddAccess() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        return current
    }
}
