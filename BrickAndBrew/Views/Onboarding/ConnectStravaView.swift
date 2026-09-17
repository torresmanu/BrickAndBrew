import SwiftUI

struct ConnectStravaView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "figure.run")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Palette.stravaOrange)
            Text("Connect with Strava")
                .font(Typography.heading1)
                .foregroundStyle(Palette.cream)
            Text("We read your swim, bike, and run so they land on the crew board. Brick & Brew never posts to Strava.")
                .font(Typography.body)
                .foregroundStyle(Palette.muted)

            if session.isBusy {
                LoadingView(message: "Talking to Strava…")
                    .frame(maxHeight: 140)
            } else {
                if AppConfig.isStravaConfigured {
                    Button("Connect with Strava", action: connect)
                        .buttonStyle(PrimaryButtonStyle(fill: Palette.stravaOrange, foreground: .white))
                } else {
                    Text(BrickError.missingStravaConfiguration.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(Palette.danger)
                }
                Button("I'll connect later", action: session.skipStrava)
                    .buttonStyle(SecondaryButtonStyle())
            }
            Spacer()
        }
        .padding(Spacing.lg)
    }

    private func connect() {
        Task {
            await session.connectStrava()
        }
    }
}
