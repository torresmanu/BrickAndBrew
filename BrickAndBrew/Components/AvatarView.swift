import SwiftUI
import UIKit

struct AvatarView: View {
    let userId: String
    let displayName: String
    var size: CGFloat = 40
    var isUpdating: Bool = false
    var allowsPreview: Bool = true
    let cache: AvatarCache

    @State private var isPreviewPresented = false

    var body: some View {
        Group {
            if allowsPreview {
                Button(action: showPreview) {
                    artwork
                }
                .buttonStyle(.plain)
                .disabled(isUpdating)
                .accessibilityHint("Shows a larger profile photo")
                .fullScreenCover(isPresented: $isPreviewPresented) {
                    AvatarPreviewView(
                        userId: userId,
                        displayName: displayName,
                        cache: cache
                    )
                }
            } else {
                artwork
            }
        }
    }

    private var artwork: some View {
        ZStack {
            Group {
                if let image = currentImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Text(AvatarImageProcessor.initials(from: displayName))
                        .font(.system(size: size * 0.36, weight: .semibold))
                        .foregroundStyle(Palette.text)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Palette.surfaceElevated)
                }
            }

            if isUpdating {
                Circle()
                    .fill(Palette.background.opacity(0.55))
                ProgressView()
                    .tint(Palette.text)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Palette.hairline, lineWidth: 1)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var currentImage: UIImage? {
        _ = cache.generation
        return cache.image(for: userId)
    }

    private var accessibilityLabel: String {
        if currentImage == nil {
            return "\(displayName), initials \(AvatarImageProcessor.initials(from: displayName))"
        }
        return "Profile photo of \(displayName)"
    }

    private func showPreview() {
        Haptics.light()
        isPreviewPresented = true
    }
}

/// Large avatar on a dimmed screen. The inner `AvatarView` does not nest another preview.
private struct AvatarPreviewView: View {
    let userId: String
    let displayName: String
    let cache: AvatarCache

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Palette.background
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            VStack(spacing: Spacing.lg) {
                Spacer()
                AvatarView(
                    userId: userId,
                    displayName: displayName,
                    size: 240,
                    allowsPreview: false,
                    cache: cache
                )
                Text(displayName)
                    .font(Typography.heading2)
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)

            Button("Close", action: close)
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Palette.text)
                .padding(Spacing.md)
                .accessibilityLabel("Close profile photo")
        }
    }

    private func close() {
        dismiss()
    }
}

/// Circular tab-bar portrait. Matches PintSymbol: always-original so chrome does not tint the photo.
enum TabBarAvatar {
    static let pointSize: CGFloat = 25

    static func image(photo: UIImage?, displayName: String) -> UIImage {
        let side = pointSize
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: CGSize(width: side, height: side))
            let ringWidth: CGFloat = 1
            let photoRect = rect.insetBy(dx: ringWidth, dy: ringWidth)

            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.saveGState()
            UIBezierPath(ovalIn: photoRect).addClip()
            if let photo {
                drawAspectFill(photo, in: photoRect)
            } else {
                UIColor(Palette.surfaceElevated).setFill()
                context.fill(photoRect)
                drawInitials(AvatarImageProcessor.initials(from: displayName), in: photoRect, side: side)
            }
            context.restoreGState()

            let ring = UIBezierPath(ovalIn: rect.insetBy(dx: ringWidth / 2, dy: ringWidth / 2))
            ring.lineWidth = ringWidth
            UIColor(Palette.hairline).setStroke()
            ring.stroke()
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    private static func drawAspectFill(_ photo: UIImage, in rect: CGRect) {
        let photoSize = photo.size
        guard photoSize.width > 0, photoSize.height > 0 else { return }
        let scale = max(rect.width / photoSize.width, rect.height / photoSize.height)
        let drawSize = CGSize(width: photoSize.width * scale, height: photoSize.height * scale)
        let origin = CGPoint(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2
        )
        photo.draw(in: CGRect(origin: origin, size: drawSize))
    }

    private static func drawInitials(_ initials: String, in rect: CGRect, side: CGFloat) {
        let text = initials as NSString
        let font = UIFont.systemFont(ofSize: side * 0.36, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(Palette.paper)
        ]
        let textSize = text.size(withAttributes: attributes)
        let origin = CGPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2
        )
        text.draw(at: origin, withAttributes: attributes)
    }
}
