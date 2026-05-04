import SwiftUI
import WebKit

struct PortalLoginView: View {
    let onCookiesCaptured: ([HTTPCookie]) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Login to Knowledge Pro")
                .font(DesignTokens.FontStyle.headline(20, weight: .bold))
                .padding(.top, 12)
            Text("Complete login and CAPTCHA in the web portal.")
                .font(DesignTokens.FontStyle.body(13, weight: .regular))
                .foregroundStyle(Color.appOnSurfaceVariant)
                .padding(.bottom, 8)
            PortalLoginWebView(onCookiesCaptured: onCookiesCaptured)
        }
        .background(Color.appSurface)
    }
}

private struct PortalLoginWebView: UIViewRepresentable {
    let onCookiesCaptured: ([HTTPCookie]) -> Void
    private let loginURL = URL(string: "https://kp.christuniversity.in/KnowledgePro/StudentLogin.do")!

    func makeCoordinator() -> Coordinator { Coordinator(onCookiesCaptured: onCookiesCaptured) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        var request = URLRequest(url: loginURL)
        request.cachePolicy = .useProtocolCachePolicy
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onCookiesCaptured: ([HTTPCookie]) -> Void
        private var handoffCompleted = false
        private var captchaHardReloadCount = 0

        private static let captchaProbeJS = """
        (function() {
          var img = document.getElementById('captcha_img');
          if (!img) { return 'missing'; }
          var src = img.getAttribute('src') || '';
          return src.trim().length > 0 ? 'ready' : 'empty';
        })();
        """

        init(onCookiesCaptured: @escaping ([HTTPCookie]) -> Void) {
            self.onCookiesCaptured = onCookiesCaptured
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url?.absoluteString else { return }

            if url.localizedCaseInsensitiveContains("StudentLogin.do") {
                scheduleCaptchaReadinessProbe(on: webView, attempt: 0)
            }

            if handoffCompleted { return }

            if url.localizedCaseInsensitiveContains("returnHomePage")
                || url.localizedCaseInsensitiveContains("StudentLoginNewAction.do")
            {
                capturePortalCookies(from: webView)
                return
            }

            detectAuthenticatedDOM(in: webView)
        }

        /// Captcha image is often filled asynchronously; on slow networks an immediate `reload()` looked like an “auth loop”.
        private func scheduleCaptchaReadinessProbe(on webView: WKWebView, attempt: Int) {
            guard !handoffCompleted else { return }
            guard attempt < 14 else {
                if captchaHardReloadCount < 1 {
                    captchaHardReloadCount += 1
                    webView.reload()
                }
                return
            }

            let delay: TimeInterval = attempt == 0 ? 0.35 : 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, !self.handoffCompleted else { return }
                guard let current = webView.url?.absoluteString,
                      current.localizedCaseInsensitiveContains("StudentLogin.do")
                else { return }

                webView.evaluateJavaScript(Self.captchaProbeJS) { [weak self] result, _ in
                    guard let self, !self.handoffCompleted else { return }
                    if let state = result as? String, state == "ready" { return }
                    self.scheduleCaptchaReadinessProbe(on: webView, attempt: attempt + 1)
                }
            }
        }

        private func detectAuthenticatedDOM(in webView: WKWebView) {
            let js = """
            (function() {
              var signOut = document.querySelector('a[href*="studentLogoutAction"]');
              if (signOut) { return 'authenticated'; }
              var text = (document.body && document.body.innerText) ? document.body.innerText : '';
              if (text.indexOf('Welcome') >= 0 && text.indexOf('Sign out') >= 0) { return 'authenticated'; }
              return 'login';
            })();
            """
            webView.evaluateJavaScript(js) { [weak self] result, _ in
                guard let self else { return }
                guard let state = result as? String, state == "authenticated", !self.handoffCompleted else { return }
                self.capturePortalCookies(from: webView)
            }
        }

        private func capturePortalCookies(from webView: WKWebView) {
            attemptPortalCookieHandoff(from: webView, attempt: 0)
        }

        private func attemptPortalCookieHandoff(from webView: WKWebView, attempt: Int) {
            guard !handoffCompleted else { return }
            let maxAttempts = 18

            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                guard let self else { return }
                let portalCookies = Self.filterPortalCookies(cookies)
                DispatchQueue.main.async {
                    guard !self.handoffCompleted else { return }
                    if !portalCookies.isEmpty {
                        self.handoffCompleted = true
                        self.onCookiesCaptured(portalCookies)
                        return
                    }
                    guard attempt < maxAttempts else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        self.attemptPortalCookieHandoff(from: webView, attempt: attempt + 1)
                    }
                }
            }
        }

        private static func filterPortalCookies(_ cookies: [HTTPCookie]) -> [HTTPCookie] {
            cookies.filter {
                let d = $0.domain.lowercased()
                return d.contains("christuniversity.in") || d.contains("knowledgepro")
            }
        }
    }
}
