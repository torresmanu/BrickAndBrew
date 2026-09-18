import SwiftUI
import UIKit

struct CrewPintRowView: View {
    let photo: BeerPhoto
    let displayName: String
    let avatars: AvatarCache
    let photos: BeerPhotoCache
    @State private var isPreviewPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                AvatarView(
                    userId: photo.userId,
                    displayName: displayName,
                    size: 36,
                    cache: avatars
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundStyle(Palette.cream)
                        .lineLimit(1)
                    Text(Formatters.relative(photo.loggedAt))
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }
                Spacer()
                Text(Formatters.beerCount(photo.count))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.amber)
            }

            if let note = photo.note, note.isEmpty == false {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
            }

            if let image = currentImage {
                Button(action: showPreview) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pint photo from \(displayName)")
                .accessibilityHint("Shows a larger photo")
                .fullScreenCover(isPresented: $isPreviewPresented) {
                    PhotoPreviewView(image: image, accessibilityLabel: "Pint photo from \(displayName)")
                }
            } else {
                Text("Photo isn't available yet. Pull to refresh.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            }
        }
        .padding(Spacing.md)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
    }

    private var currentImage: UIImage? {
        _ = photos.generation
        return photos.image(for: photo.beerId)
    }

    private func showPreview() {
        Haptics.light()
        isPreviewPresented = true
    }
}
