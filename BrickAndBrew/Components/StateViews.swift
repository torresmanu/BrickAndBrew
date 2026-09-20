import SwiftUI

struct LoadingView: View {
    var message: String = "Loading…"

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Palette.paper)
                .scaleEffect(1.1)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
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
        VStack(alignment: .leading, spacing: Spacing.md) {
            icon
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Palette.paper)
            Text(title)
                .font(Typography.title)
                .foregroundStyle(Palette.text)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.lg)
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
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Palette.danger)
            Text("Couldn't load this")
                .font(Typography.title)
                .foregroundStyle(Palette.text)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button(retryTitle, action: retry)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.lg)
    }
}

/// Strong rectangle. Orange fill, ink type. Not a pill.
struct PrimaryButtonStyle: ButtonStyle {
    var fill: Color = Palette.accent
    var foreground: Color = Palette.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.plexSans(size: 14, weight: .semibold, relativeTo: .body))
            .textCase(.uppercase)
            .tracking(1.1)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(configuration.isPressed ? fill.opacity(0.82) : fill)
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }
}

/// Outlined control on ink. Paper type.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.plexSans(size: 14, weight: .semibold, relativeTo: .body))
            .textCase(.uppercase)
            .tracking(1.1)
            .foregroundStyle(Palette.text)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(Palette.surfaceElevated.opacity(configuration.isPressed ? 0.7 : 1))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .stroke(Palette.hairlineStrong, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }
}

struct BrandFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.body)
            .foregroundStyle(Palette.text)
            .padding(Spacing.md)
            .background(Palette.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            }
    }
}

extension View {
    func brandField() -> some View {
        modifier(BrandFieldModifier())
    }
}
