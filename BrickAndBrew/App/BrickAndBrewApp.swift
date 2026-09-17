import SwiftUI

@main
struct BrickAndBrewApp: App {
    @State private var session = AppSession()

    init() {
        BrandChrome.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .preferredColorScheme(.dark)
                .tint(Palette.amber)
                .task {
                    guard LaunchEnvironment.isRunningUnitTests == false else { return }
                    await session.bootstrap()
                }
        }
    }
}
