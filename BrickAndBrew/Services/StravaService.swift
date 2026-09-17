import AuthenticationServices
import Foundation
import UIKit

@MainActor
final class StravaService {
    private let session: URLSession
    private var authSession: ASWebAuthenticationSession?
    private let presentation = StravaPresentationContext()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func storedCredentials() throws -> StravaCredentials? {
        try KeychainStore.decode(StravaCredentials.self, for: .stravaCredentials)
    }

    func disconnect() throws {
        try KeychainStore.delete(.stravaCredentials)
    }

    func connect() async throws -> StravaCredentials {
        guard AppConfig.isStravaConfigured, let clientID = optionalClientID else {
            throw BrickError.missingStravaConfiguration
        }

        let code = try await authorize(clientID: clientID)
        let tokens = try await exchange(code: code)
        let credentials = makeCredentials(from: tokens)
        try KeychainStore.set(credentials, for: .stravaCredentials)
        return credentials
    }

    func validAccessToken() async throws -> String {
        guard var credentials = try storedCredentials() else {
            throw BrickError.strava("Connect Strava to sync your training.")
        }
        if credentials.isExpired {
            credentials = try await refresh(credentials)
            try KeychainStore.set(credentials, for: .stravaCredentials)
        }
        return credentials.accessToken
    }

    func fetchActivities(after: Date) async throws -> [StravaActivityDTO] {
        let token = try await validAccessToken()
        var page = 1
        var all: [StravaActivityDTO] = []
        let afterEpoch = Int(after.timeIntervalSince1970)

        while true {
            var components = URLComponents(string: "https://www.strava.com/api/v3/athlete/activities")
            components?.queryItems = [
                URLQueryItem(name: "after", value: String(afterEpoch)),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(AppConfig.stravaActivitiesPerPage))
            ]
            guard let url = components?.url else {
                throw BrickError.strava("We couldn't build the Strava request.")
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let batch: [StravaActivityDTO] = try await decoded(request)
            all.append(contentsOf: batch)
            if batch.count < AppConfig.stravaActivitiesPerPage {
                break
            }
            page += 1
        }

        return all
    }

    private var optionalClientID: String? {
        let value = AppConfig.stravaClientID
        guard value.isEmpty == false, value.contains("YOUR_STRAVA_CLIENT_ID") == false else {
            return nil
        }
        return value
    }

    private func authorize(clientID: String) async throws -> String {
        var components = URLComponents(string: "https://www.strava.com/oauth/mobile/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: AppConfig.stravaRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: AppConfig.stravaAuthScopes)
        ]
        guard let url = components?.url else {
            throw BrickError.strava("We couldn't start Strava sign-in.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "brickandbrew"
            ) { callbackURL, error in
                if let error {
                    let cancelled = (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue
                    continuation.resume(throwing: cancelled ? BrickError.stravaDenied : BrickError.strava(error.localizedDescription))
                    return
                }
                guard
                    let callbackURL,
                    let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?
                        .first(where: { $0.name == "code" })?
                        .value
                else {
                    continuation.resume(throwing: BrickError.strava("Strava did not return an authorization code."))
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self.presentation
            session.prefersEphemeralWebBrowserSession = false
            self.authSession = session
            if session.start() == false {
                continuation.resume(throwing: BrickError.strava("We couldn't open Strava sign-in."))
            }
        }
    }

    private func exchange(code: String) async throws -> StravaTokenResponse {
        try await postToWorker(path: "/token", body: ["code": code])
    }

    private func refresh(_ credentials: StravaCredentials) async throws -> StravaCredentials {
        let tokens = try await postToWorker(
            path: "/refresh",
            body: ["refresh_token": credentials.refreshToken]
        )
        var updated = makeCredentials(from: tokens)
        if updated.athleteId == 0 {
            updated.athleteId = credentials.athleteId
            updated.athleteName = credentials.athleteName
        }
        return updated
    }

    private func postToWorker(path: String, body: [String: String]) async throws -> StravaTokenResponse {
        guard let base = AppConfig.stravaOAuthWorkerURL else {
            throw BrickError.missingStravaConfiguration
        }
        let url = base.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await decoded(request)
    }

    private func makeCredentials(from tokens: StravaTokenResponse) -> StravaCredentials {
        StravaCredentials(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(tokens.expiresAt)),
            athleteId: tokens.athlete?.id ?? 0,
            athleteName: tokens.athlete?.displayName ?? ""
        )
    }

    private func decoded<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw BrickError.network
            }
            guard (200..<300).contains(http.statusCode) else {
                throw BrickError.strava(Self.friendlyMessage(status: http.statusCode, data: data))
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch let error as BrickError {
            throw error
        } catch is DecodingError {
            throw BrickError.strava("Strava sent data we couldn't read. Try again in a moment.")
        } catch {
            throw BrickError.network
        }
    }

    private static func friendlyMessage(status: Int, data: Data) -> String {
        if status == 401 || status == 403 {
            return "Strava access expired. Reconnect from the Me tab."
        }
        if status == 429 {
            return "Strava asked us to slow down. Try again in a few minutes."
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String,
           message.isEmpty == false {
            return message
        }
        return "Strava is unavailable right now. Try again shortly."
    }
}

private final class StravaPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}
