import SwiftUI
import WebKit


struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteFinalConfirm = false

    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                VStack(spacing: 14) {
                    // Appearance
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Appearance").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            HStack {
                                Image(systemName: "paintpalette.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                Text("Theme").foregroundColor(FPColor.textPrimary)
                                Spacer()
                                Picker("Theme", selection: $app.themePref) {
                                    ForEach(ThemePref.allCases) { t in
                                        Text(t.title).tag(t)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 200)
                            }
                        }
                    }

                    // Sound & haptics
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Feedback").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            Toggle(isOn: $app.soundEnabled) {
                                HStack {
                                    Image(systemName: "speaker.wave.2.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Sound").foregroundColor(FPColor.textPrimary)
                                }
                            }.toggleStyle(SwitchToggleStyle(tint: FPColor.glow))
                            Toggle(isOn: $app.hapticsEnabled) {
                                HStack {
                                    Image(systemName: "waveform.path").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Haptics").foregroundColor(FPColor.textPrimary)
                                }
                            }.toggleStyle(SwitchToggleStyle(tint: FPColor.glow))
                            Toggle(isOn: $app.focusModeEnabled) {
                                HStack {
                                    Image(systemName: "moon.zzz.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Focus Mode").foregroundColor(FPColor.textPrimary)
                                }
                            }.toggleStyle(SwitchToggleStyle(tint: FPColor.glow))
                        }
                    }

                    // Notifications
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notifications").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            Toggle(isOn: Binding(
                                get: { app.notificationsEnabled },
                                set: { newValue in
                                    if newValue {
                                        NotificationManager.shared.requestAuthorization { granted in
                                            app.notificationsEnabled = granted
                                        }
                                    } else { app.notificationsEnabled = false }
                                })
                            ) {
                                HStack {
                                    Image(systemName: "bell.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Daily reminder").foregroundColor(FPColor.textPrimary)
                                }
                            }.toggleStyle(SwitchToggleStyle(tint: FPColor.glow))
                            if app.notificationsEnabled {
                                HStack {
                                    Image(systemName: "clock.fill").foregroundColor(FPColor.glow).frame(width: 22)
                                    Text("Time").foregroundColor(FPColor.textPrimary)
                                    Spacer()
                                    DatePicker("", selection: Binding(
                                        get: {
                                            var c = DateComponents(); c.hour = app.reminderHour; c.minute = app.reminderMin
                                            return Calendar.current.date(from: c) ?? Date()
                                        },
                                        set: { d in
                                            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                                            app.reminderHour = c.hour ?? 19
                                            app.reminderMin  = c.minute ?? 0
                                        }
                                    ), displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                }
                            }
                        }
                    }

                    // Data
                    GlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            Button {
                                Haptics.tap(app.hapticsEnabled)
                                app.history = []
                            } label: {
                                HStack {
                                    Image(systemName: "trash").foregroundColor(FPColor.warning).frame(width: 22)
                                    Text("Clear session history").foregroundColor(FPColor.textPrimary)
                                    Spacer()
                                }
                            }.buttonStyle(PlainButtonStyle())
                            Button {
                                Haptics.tap(app.hapticsEnabled)
                                app.plan = AppState.defaultPlan()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise").foregroundColor(FPColor.warning).frame(width: 22)
                                    Text("Reset training plan").foregroundColor(FPColor.textPrimary)
                                    Spacer()
                                }
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }

                    // About
                    GlowCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About").font(FPFont.body(11, weight: .bold)).foregroundColor(FPColor.textMuted)
                            HStack {
                                Text("Version").foregroundColor(FPColor.textMuted)
                                Spacer()
                                Text("1.0.0").foregroundColor(FPColor.textPrimary).font(FPFont.body(13, weight: .semibold))
                            }
                            HStack {
                                Text("Build").foregroundColor(FPColor.textMuted)
                                Spacer()
                                Text("100").foregroundColor(FPColor.textPrimary).font(FPFont.body(13, weight: .semibold))
                            }
                        }
                    }

                    // Account actions
                    if app.isLoggedIn {
                        Button {
                            Haptics.tap(app.hapticsEnabled)
                            showLogoutConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(FPColor.warning)
                                Text("Log out").foregroundColor(FPColor.warning)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(FPColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(FPColor.warning.opacity(0.6), lineWidth: 1))
                        }.buttonStyle(PlainButtonStyle())

                        Button {
                            Haptics.tap(app.hapticsEnabled)
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill").foregroundColor(FPColor.danger)
                                Text("Delete account").foregroundColor(FPColor.danger)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(FPColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(FPColor.danger.opacity(0.6), lineWidth: 1))
                        }.buttonStyle(PlainButtonStyle())
                    }
                    Spacer().frame(height: 60)
                }.padding(20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showLogoutConfirm) {
            Alert(
                title: Text("Log out?"),
                message: Text("Your data stays on this device."),
                primaryButton: .destructive(Text("Log out"), action: {
                    Haptics.success(app.hapticsEnabled)
                    app.logout()
                }),
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showDeleteConfirm) {
            Alert(
                title: Text("Delete account?"),
                message: Text("This will permanently erase your profile, history, achievements and settings on this device."),
                primaryButton: .destructive(Text("Continue"), action: {
                    showDeleteFinalConfirm = true
                }),
                secondaryButton: .cancel()
            )
        }
        .background(
            EmptyView()
                .alert(isPresented: $showDeleteFinalConfirm) {
                    Alert(
                        title: Text("Are you absolutely sure?"),
                        message: Text("This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete forever"), action: {
                            Haptics.error(app.hapticsEnabled)
                            app.deleteAccount()
                        }),
                        secondaryButton: .cancel()
                    )
                }
        )
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = FocusConstants.cookieBox
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("\(FocusConstants.logEmblem) Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}
extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ \(FocusConstants.logEmblem) Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
