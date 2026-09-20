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
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                AvatarView(
                    userId: photo.userId,
                    displayName: displayName,
                    size: 36,
                    cache: avatars
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName.uppercased())
                        .font(Typography.label)
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                    Text("BEER  ·  \(Formatters.relative(photo.loggedAt).uppercased())")
                        .font(Typography.metadata)
                        .foregroundStyle(Palette.secondaryText)
                        .tracking(1.2)
                }
                Spacer()
                MetricView(
                    value: Formatters.compactNumber(Double(photo.count)),
                    unit: Formatters.beerUnit(photo.count),
                    valueFont: Typography.title,
                    unitFont: Typography.metadata,
                    valueColor: Palette.accent,
                    alignment: .trailing
                )
            }

            if let note = photo.note, note.isEmpty == false {
                Text(note.uppercased())
                    .font(Typography.title)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let image = currentImage {
                Button(action: showPreview) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .clipped()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, -Spacing.md)
                .accessibilityLabel("Pint photo from \(displayName)")
                .accessibilityHint("Shows a larger photo")
                .fullScreenCover(isPresented: $isPreviewPresented) {
                    PhotoPreviewView(image: image, accessibilityLabel: "Pint photo from \(displayName)")
                }
            } else {
                Text("Photo isn't available yet. Pull to refresh.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            }
        }
        .padding(.vertical, Spacing.md)
        .overlay(alignment: .bottom) {
            Hairline()
        }
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
