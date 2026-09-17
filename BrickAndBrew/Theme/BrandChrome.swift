import SwiftUI
import UIKit

/// Navigation and tab chrome for Finalist B negative polarity: `#111` ground, white type.
enum BrandChrome {
    @MainActor
    static func apply() {
        let onGround = UIColor.white
        let ground = UIColor(Palette.ground)
        let meta = UIColor(Palette.meta)
        let title = UIFont(name: "IBMPlexSans-Bold", size: 17) ?? .systemFont(ofSize: 17, weight: .bold)
        let large = UIFont(name: "IBMPlexSans-Bold", size: 32) ?? .systemFont(ofSize: 32, weight: .bold)

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
        UITabBar.appearance().tintColor = onGround
        UITabBar.appearance().unselectedItemTintColor = meta

        UITextField.appearance().tintColor = onGround
        UISwitch.appearance().onTintColor = onGround
    }
}
