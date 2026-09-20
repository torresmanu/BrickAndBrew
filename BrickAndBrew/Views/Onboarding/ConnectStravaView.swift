import SwiftUI

struct ConnectStravaView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer()
            Text("CONNECT\nSTRAVA")
                .font(Typography.displayL)
                .foregroundStyle(Palette.text)
                .minimumScaleFactor(0.7)
            Text("We read your swim, bike, and run so they land on the crew board. Brick & Brew never posts to Strava.")
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)

            if session.isBusy {
                LoadingView(message: "Talking to Strava…")
                    .frame(maxHeight: 140)
            } else {
                if AppConfig.isStravaConfigured {
                    Button("Connect with Strava", action: connect)
                        .buttonStyle(PrimaryButtonStyle(fill: Palette.stravaOrange, foreground: .white))
                } else {
                    Text(BrickError.missingStravaConfiguration.localizedDescription)
                        .font(Typography.body)
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
