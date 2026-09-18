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
                        .foregroundStyle(Palette.cream)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Palette.surfaceElevated)
                }
            }

            if isUpdating {
                Circle()
                    .fill(Palette.background.opacity(0.55))
                ProgressView()
                    .tint(Palette.amber)
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
                    .foregroundStyle(Palette.cream)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)

            Button("Close", action: close)
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Palette.cream)
                .padding(Spacing.md)
                .accessibilityLabel("Close profile photo")
        }
    }

    private func close() {
        dismiss()
    }
}
