import Foundation
import WebKit

@MainActor
final class PortalRenderedPageFetcher: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private var continuation: CheckedContinuation<EndpointHTMLResponse, Error>?
    private var currentEndpointKey: String = ""
    private var latestStatusCode: Int = 0
    private var latestFinalURL: URL?

    override init() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        webView.navigationDelegate = self
    }

    func fetch(
        endpointKey: String,
        endpointMap: KnowledgeProEndpointMap,
        method: String = "GET",
        form: [String: String]? = nil
    ) async throws -> EndpointHTMLResponse {
        guard let url = endpointMap.url(for: endpointKey) else {
            throw PortalNetworkError.missingEndpoint(endpointKey)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if method.uppercased() == "GET", let form, var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            let existing = components.queryItems ?? []
            let additions = form.map { URLQueryItem(name: $0.key, value: $0.value) }
            components.queryItems = existing + additions
            if let resolvedURL = components.url {
                request.url = resolvedURL
            }
        } else if method.uppercased() == "POST", let form {
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

        currentEndpointKey = endpointKey
        latestStatusCode = 0
        latestFinalURL = nil

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.webView.load(request)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let http = navigationResponse.response as? HTTPURLResponse {
            latestStatusCode = http.statusCode
            latestFinalURL = http.url
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, error in
            guard let self else { return }
            if let error {
                self.continuation?.resume(throwing: error)
                self.continuation = nil
                return
            }
            guard let html = result as? String else {
                self.continuation?.resume(throwing: PortalNetworkError.invalidResponse)
                self.continuation = nil
                return
            }
            let response = EndpointHTMLResponse(
                endpointKey: self.currentEndpointKey,
                requestURL: webView.url ?? URL(string: "about:blank")!,
                finalURL: self.latestFinalURL ?? webView.url,
                statusCode: self.latestStatusCode,
                html: html
            )
            self.continuation?.resume(returning: response)
            self.continuation = nil
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
