import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var launchStrategies: [LaunchStrategy] = []
    
    private let attributionWell = AttributionWell()
    private let pushDispatcher = PushDispatcher()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        attributionWell.measurementsForwarder = { [weak self] data in
            self?.broadcastMeasurements(data)
        }
        attributionWell.trailsForwarder = { [weak self] data in
            self?.broadcastTrails(data)
        }
        
        launchStrategies = [
            FirebaseLaunchStrategy(),
            MessagingLaunchStrategy(messagingDelegate: self, notificationDelegate: self),
            AppsFlyerLaunchStrategy(delegate: self, deeplinkDelegate: self)
        ]
        
        for strategy in launchStrategies {
            strategy.execute()
        }
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushDispatcher.dispatch(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        AppsFlyerLaunchStrategy.startTracking()
    }
    
    private func broadcastMeasurements(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func broadcastTrails(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            
            UserDefaults.standard.set(t, forKey: BoxKey<String>.fcmToken.raw)
            UserDefaults.standard.set(t, forKey: BoxKey<String>.pushToken.raw)
            UserDefaults(suiteName: FocusConstants.groupKit)?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        pushDispatcher.dispatch(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pushDispatcher.dispatch(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushDispatcher.dispatch(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        attributionWell.acceptMeasurements(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        attributionWell.acceptMeasurements([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let link = result.deepLink else { return }
        
        attributionWell.acceptTrails(link.clickEvent)
    }
}

protocol LaunchStrategy {
    func execute()
}

final class FirebaseLaunchStrategy: LaunchStrategy {
    func execute() {
        FirebaseApp.configure()
    }
}

final class MessagingLaunchStrategy: LaunchStrategy {
    
    private weak var messagingDelegate: MessagingDelegate?
    private weak var notificationDelegate: UNUserNotificationCenterDelegate?
    
    init(messagingDelegate: MessagingDelegate, notificationDelegate: UNUserNotificationCenterDelegate) {
        self.messagingDelegate = messagingDelegate
        self.notificationDelegate = notificationDelegate
    }
    
    func execute() {
        Messaging.messaging().delegate = messagingDelegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UIApplication.shared.registerForRemoteNotifications()
    }
}

// MARK: - Strategy #3: AppsFlyer

final class AppsFlyerLaunchStrategy: LaunchStrategy {
    
    private weak var delegate: AppsFlyerLibDelegate?
    private weak var deeplinkDelegate: DeepLinkDelegate?
    
    init(delegate: AppsFlyerLibDelegate, deeplinkDelegate: DeepLinkDelegate) {
        self.delegate = delegate
        self.deeplinkDelegate = deeplinkDelegate
    }
    
    func execute() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = FocusConstants.trailKey
        sdk.appleAppID = FocusConstants.appNumeric
        sdk.delegate = delegate
        sdk.deepLinkDelegate = deeplinkDelegate
        sdk.isDebug = false
    }
    
    static func startTracking() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

// MARK: - Attribution Well (буферизация)

final class AttributionWell: NSObject {
    
    var measurementsForwarder: (([AnyHashable: Any]) -> Void)?
    var trailsForwarder: (([AnyHashable: Any]) -> Void)?
    
    private var measurementsBuffer: [AnyHashable: Any] = [:]
    private var trailsBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func acceptMeasurements(_ data: [AnyHashable: Any]) {
        measurementsBuffer = data
        scheduleFuse()
        
        if !trailsBuffer.isEmpty {
            performFuse()
        }
    }
    
    func acceptTrails(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: BoxKey<Bool>.voyaged.raw) else { return }
        
        trailsBuffer = data
        trailsForwarder?(data)
        fuseTimer?.invalidate()
        
        if !measurementsBuffer.isEmpty {
            performFuse()
        }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(
            withTimeInterval: 2.5,
            repeats: false
        ) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = measurementsBuffer
        
        for (k, v) in trailsBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        
        measurementsForwarder?(combined)
    }
}

final class PushDispatcher: NSObject {
    
    func dispatch(_ payload: [AnyHashable: Any]) {
        guard let url = trace(payload) else { return }
        
        UserDefaults.standard.set(url, forKey: BoxKey<String>.pushURL.raw)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func trace(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String {
            return direct
        }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String {
            return url
        }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String {
            return url
        }
        return nil
    }
}
