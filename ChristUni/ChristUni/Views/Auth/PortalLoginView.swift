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
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onCookiesCaptured: ([HTTPCookie]) -> Void
        private var fired = false
        private var captchaReloadAttempted = false

        init(onCookiesCaptured: @escaping ([HTTPCookie]) -> Void) {
            self.onCookiesCaptured = onCookiesCaptured
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let url = webView.url?.absoluteString else { return }

            // On the login page, captcha is JS-driven and can race the first render.
            if url.localizedCaseInsensitiveContains("StudentLogin.do") {
                validateCaptchaPresence(in: webView)
            }

            if fired { return }

            if url.localizedCaseInsensitiveContains("returnHomePage")
                || url.localizedCaseInsensitiveContains("StudentLoginNewAction.do")
            {
                capturePortalCookies(from: webView)
                return
            }

            // Some Knowledge Pro flows keep a similar URL after login.
            // Detect authenticated shell markers in rendered DOM and transition.
            detectAuthenticatedDOM(in: webView)
        }

        private func validateCaptchaPresence(in webView: WKWebView) {
            let js = """
            (function() {
              var img = document.getElementById('captcha_img');
              if (!img) { return 'missing'; }
              var src = img.getAttribute('src') || '';
              return src.trim().length > 0 ? 'ready' : 'empty';
            })();
            """
            webView.evaluateJavaScript(js) { [weak self] result, _ in
                guard let self else { return }
                guard let state = result as? String else { return }
                guard state != "ready", !self.captchaReloadAttempted else { return }
                self.captchaReloadAttempted = true
                webView.reload()
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
                guard let state = result as? String, state == "authenticated", !self.fired else { return }
                self.capturePortalCookies(from: webView)
            }
        }

        private func capturePortalCookies(from webView: WKWebView) {
            guard !fired else { return }
            fired = true
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                let portalCookies = cookies.filter { ($0.domain).contains("christuniversity.in") }
                DispatchQueue.main.async {
                    self.onCookiesCaptured(portalCookies)
                }
            }
        }
    }
}
