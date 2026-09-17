import Foundation

/// Compile-time and bundle values. Secrets never live here: the Strava client
/// secret stays on the Cloudflare Worker.
enum AppConfig {
    static let cloudKitContainerID = "iCloud.com.brickandbrew.app"
    static let stravaRedirectURI = "brickandbrew://localhost/oauth"
    static let stravaAuthScopes = "read,activity:read_all,profile:read_all"
    static let defaultTeamName = "Brick & Brew Crew"
    static let stravaActivitiesPerPage = 100
    static let cloudKitPageLimit = 200
    static let cacheStaleInterval: TimeInterval = 60 * 60

    static var stravaClientID: String {
        bundleString(for: "STRAVA_CLIENT_ID")
    }

    static var stravaOAuthWorkerURL: URL? {
        let raw = bundleString(for: "STRAVA_OAUTH_WORKER_URL")
        guard raw.isEmpty == false, raw.contains("YOUR_ACCOUNT") == false else {
            return nil
        }
        return URL(string: raw)
    }

    static var isStravaConfigured: Bool {
        stravaClientID.isEmpty == false
            && stravaClientID.contains("YOUR_STRAVA_CLIENT_ID") == false
            && stravaOAuthWorkerURL != nil
    }

    private static func bundleString(for key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }
}
