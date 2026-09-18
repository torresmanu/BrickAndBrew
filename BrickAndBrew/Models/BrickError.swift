import Foundation

enum BrickError: LocalizedError, Equatable {
    case iCloudUnavailable
    case notSignedIn
    case appleSignInCancelled
    case appleSignInFailed
    case missingDisplayName
    case displayNameTooLong
    case invalidInviteCode
    case missingStravaConfiguration
    case stravaDenied
    case strava(String)
    case cloudKit(String)
    case network
    case keychain
    case missingProfile
    case accountDeletionFailed
    case cameraUnavailable
    case cameraDenied

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            "Brick & Brew stores the crew board in iCloud. Sign in to iCloud in Settings, then come back."
        case .notSignedIn:
            "Sign in with Apple to join the crew."
        case .appleSignInCancelled:
            "Sign in was cancelled. Try again when you're ready."
        case .appleSignInFailed:
            "Apple couldn't complete sign in. Use a physical iPhone signed into iCloud, then try again."
        case .missingDisplayName:
            "Pick a name your teammates will recognize."
        case .displayNameTooLong:
            "Use \(DisplayName.maxLength) characters or fewer."
        case .invalidInviteCode:
            "Use 4–20 letters or numbers for the invite code."
        case .missingStravaConfiguration:
            "Strava is not configured yet. Add your Client ID and Worker URL in Info.plist."
        case .stravaDenied:
            "Strava access was cancelled. You can connect later from the Me tab."
        case .strava(let message):
            message
        case .cloudKit(let message):
            message
        case .network:
            "We couldn't reach the network. Check your connection and try again."
        case .keychain:
            "We couldn't store your session securely. Restart the app and try again."
        case .missingProfile:
            "We couldn't find your crew profile. Sign in again."
        case .accountDeletionFailed:
            "We couldn't delete your account. Check your connection and iCloud, then try again."
        case .cameraUnavailable:
            "Camera isn't available on this device. You can still log the pint without a photo."
        case .cameraDenied:
            "Camera access is off. Turn it on in iOS Settings if you want to snap a pint, or log without a photo."
        }
    }
}
