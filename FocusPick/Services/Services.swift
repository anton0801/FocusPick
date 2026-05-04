import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications
import Combine

protocol VerificationService {
    func runVerification() -> AsyncOperation<Bool>
}

protocol RefetchService {
    func refetchAttribution(deviceID: String) async throws -> [String: Any]
}

protocol DiscoveryService {
    func discoverEndpoint(seed: [String: Any]) async throws -> String
}

protocol ConsentService {
    func solicitPublisher() -> AnyPublisher<Bool, Never>
    func arm()
}

final class AsyncOperation<Result>: Operation {
    
    private let lock = NSLock()
    private var _isExecuting = false
    private var _isFinished = false
    
    var result: Swift.Result<Result, Error>?
    
    private let work: (@escaping (Swift.Result<Result, Error>) -> Void) -> Void
    
    init(work: @escaping (@escaping (Swift.Result<Result, Error>) -> Void) -> Void) {
        self.work = work
        super.init()
    }
    
    override var isAsynchronous: Bool { true }
    
    override var isExecuting: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isExecuting
    }
    
    override var isFinished: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isFinished
    }
    
    override func start() {
        if isCancelled {
            markFinished()
            return
        }
        
        markExecuting()
        
        work { [weak self] result in
            guard let self = self else { return }
            self.result = result
            self.markFinished()
        }
    }
    
    private func markExecuting() {
        willChangeValue(forKey: "isExecuting")
        lock.lock()
        _isExecuting = true
        lock.unlock()
        didChangeValue(forKey: "isExecuting")
    }
    
    private func markFinished() {
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        lock.lock()
        _isExecuting = false
        _isFinished = true
        lock.unlock()
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
}

final class SupabaseVerificationService: VerificationService {
    
    private let queue: OperationQueue
    
    init() {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInitiated
        self.queue = q
    }
    
    func runVerification() -> AsyncOperation<Bool> {
        let op = AsyncOperation<Bool> { [weak self] completion in
            completion(.success(true))
        }
        
        queue.addOperation(op)
        return op
    }
}

final class AppsFlyerRefetchService: RefetchService {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    func refetchAttribution(deviceID: String) async throws -> [String: Any] {
        var components = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(FocusConstants.appNumeric)")
        components?.queryItems = [
            URLQueryItem(name: "devkey", value: FocusConstants.trailKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = components?.url else {
            throw FocusError.packetMangled
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw FocusError.wireDown
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FocusError.packetMangled
        }
        
        return json
    }
}

final class HTTPDiscoveryService: DiscoveryService {
    
    private let session: URLSession
    private let waits: [Double] = [52.0, 104.0, 208.0]
    
    private var browserAgent: String = ""
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
        
        DispatchQueue.main.sync {
            self.browserAgent = WKWebView().value(forKey: "userAgent") as? String ?? ""
        }
    }
        
    func discoverEndpoint(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: FocusConstants.backendBay) else {
            throw FocusError.packetMangled
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(FocusConstants.appNumeric)"
        body["push_token"] = UserDefaults.standard.string(forKey: BoxKey<String>.pushToken.raw)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastError: Error?
        
        for (idx, wait) in waits.enumerated() {
            do {
                return try await singleAttempt(request)
            } catch FocusError.backendDeclined {
                throw FocusError.backendDeclined
            } catch FocusError.ceiling {
                let waitTime = wait * Double(idx + 1)
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                continue
            } catch {
                lastError = error
                if idx < waits.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? FocusError.wireDown
    }
    
    private func singleAttempt(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw FocusError.wireDown
        }
        
        if http.statusCode == 404 {
            throw FocusError.backendDeclined
        }
        
        if http.statusCode == 429 {
            throw FocusError.ceiling
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw FocusError.wireDown
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FocusError.packetMangled
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw FocusError.packetMangled
        }
        
        if !ok {
            throw FocusError.backendDeclined
        }
        
        guard let url = json["url"] as? String else {
            throw FocusError.packetMangled
        }
        
        return url
    }
}

