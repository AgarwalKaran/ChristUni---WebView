import Foundation
import WebKit

struct PersistedCookie: Codable {
    let properties: [String: String]
}

final class PortalAuthSessionStore {
    private let keychain = PortalKeychainStore()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var hasActiveSession: Bool {
        (try? keychain.read()) != nil
    }

    func persist(cookies: [HTTPCookie]) throws {
        let entries = Self.serialize(cookies: cookies)
        let data = try encoder.encode(entries)
        try keychain.save(data)
    }

    func loadCookies() -> [HTTPCookie] {
        guard
            let data = try? keychain.read(),
            let decoded = try? decoder.decode([PersistedCookie].self, from: data)
        else { return [] }

        return Self.deserialize(entries: decoded)
    }

    func clear() {
        keychain.clear()
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                WKWebsiteDataStore.default().httpCookieStore.delete(cookie)
            }
        }
    }

    static func serialize(cookies: [HTTPCookie]) -> [PersistedCookie] {
        cookies.compactMap { cookie in
            guard let properties = cookie.properties else { return nil }
            let stringMap = properties.reduce(into: [String: String]()) { result, pair in
                result[pair.key.rawValue] = "\(pair.value)"
            }
            return PersistedCookie(properties: stringMap)
        }
    }

    static func deserialize(entries: [PersistedCookie]) -> [HTTPCookie] {
        entries.compactMap { entry in
            let properties = entry.properties.reduce(into: [HTTPCookiePropertyKey: Any]()) { partial, pair in
                partial[HTTPCookiePropertyKey(pair.key)] = pair.value
            }
            return HTTPCookie(properties: properties)
        }
    }
}
