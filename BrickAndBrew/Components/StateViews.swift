import SwiftUI

struct LoadingView: View {
    var message: String = "Loading…"

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Palette.amber)
                .scaleEffect(1.15)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView<Icon: View>: View {
    let title: String
    let message: String
    var icon: Icon
    var actionTitle: String?
    var action: (() -> Void)?

    init(
        title: String,
        message: String,
        icon: Icon,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            icon
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Palette.amber)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.cream)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension EmptyStateView where Icon == Image {
    init(
        title: String,
        message: String,
        systemImage: String = "tray",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            message: message,
            icon: Image(systemName: systemImage),
            actionTitle: actionTitle,
            action: action
        )
    }
}

struct ErrorStateView: View {
    let message: String
    var retryTitle: String = "Try again"
    var retry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Palette.danger)
            Text("Couldn't load this")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.cream)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
            Button(retryTitle, action: retry)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var fill: Color = Palette.amber
    var foreground: Color = Palette.background

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm + 2)
            .background(fill.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Palette.cream)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm + 2)
            .background(Palette.surfaceElevated.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
    }
}
