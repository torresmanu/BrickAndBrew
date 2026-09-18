import SwiftUI
import UserNotifications

@main
struct BrickAndBrewApp: App {
    @State private var session = AppSession()

    init() {
        BrandChrome.apply()
        if LaunchEnvironment.isRunningUnitTests == false {
            UNUserNotificationCenter.current().delegate = PintReminderCenterDelegate.shared
        }
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
