import Foundation

enum PortalNetworkError: Error {
    case missingEndpoint(String)
    case unauthorized
    case invalidResponse
}

struct EndpointHTMLResponse {
    let endpointKey: String
    let requestURL: URL
    let finalURL: URL?
    let statusCode: Int
    let html: String
}

struct AuthenticatedHTTPClient {
    let endpointMap: KnowledgeProEndpointMap
    let sessionStore: PortalAuthSessionStore
    let session: URLSession

    init(
        endpointMap: KnowledgeProEndpointMap = KnowledgeProEndpointMap(),
        sessionStore: PortalAuthSessionStore = PortalAuthSessionStore(),
        session: URLSession = .shared
    ) {
        self.endpointMap = endpointMap
        self.sessionStore = sessionStore
        self.session = session
    }

    func fetchHTML(endpointKey: String) async throws -> String {
        try await fetchResponse(endpointKey: endpointKey).html
    }

    func fetchResponse(
        endpointKey: String,
        method: String = "GET",
        form: [String: String]? = nil
    ) async throws -> EndpointHTMLResponse {
        guard let url = endpointMap.url(for: endpointKey) else {
            throw PortalNetworkError.missingEndpoint(endpointKey)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        if method.uppercased() == "POST", let form {
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let payload = form
                .map { key, value in
                    let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                    let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                    return "\(escapedKey)=\(escapedValue)"
                }
                .joined(separator: "&")
            request.httpBody = payload.data(using: .utf8)
        }

        let cookies = sessionStore.loadCookies()
        if !cookies.isEmpty {
            let header = HTTPCookie.requestHeaderFields(with: cookies)
            for (name, value) in header {
                request.setValue(value, forHTTPHeaderField: name)
            }
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PortalNetworkError.invalidResponse
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw PortalNetworkError.unauthorized
        }
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1252) else {
            throw PortalNetworkError.invalidResponse
        }
        if html.localizedCaseInsensitiveContains("StudentLoginAction.do")
            && html.localizedCaseInsensitiveContains("Welcome Christite")
        {
            throw PortalNetworkError.unauthorized
        }
        return EndpointHTMLResponse(
            endpointKey: endpointKey,
            requestURL: url,
            finalURL: http.url,
            statusCode: http.statusCode,
            html: html
        )
    }
}
