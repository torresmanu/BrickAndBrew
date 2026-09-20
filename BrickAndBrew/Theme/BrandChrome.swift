import SwiftUI
import UIKit

/// Navigation and tab chrome: ink bars, paper type, signal orange for the selected tab.
enum BrandChrome {
    @MainActor
    static func apply() {
        let onGround = UIColor(Palette.paper)
        let ground = UIColor(Palette.ink)
        let meta = UIColor(Palette.inkMute)
        let accent = UIColor(Palette.signal)
        let title = Typography.uiDisplay(size: 17)
        let large = Typography.uiDisplay(size: 32, italic: true)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = ground
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: onGround, .font: title]
        nav.largeTitleTextAttributes = [.foregroundColor: onGround, .font: large]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = onGround
        UINavigationBar.appearance().barTintColor = ground

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = ground
        tab.shadowColor = .clear
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = accent
        UITabBar.appearance().unselectedItemTintColor = meta

        UITextField.appearance().tintColor = accent
        UISwitch.appearance().onTintColor = accent
        UITableView.appearance().separatorColor = UIColor(Palette.hairline)
    }
}
