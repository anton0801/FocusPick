import Foundation

final class FocusContainer {
    
    static let shared = FocusContainer()
    
    private init() {}
    
    lazy var storage: Storage = KeyValueWrapper()
    lazy var verification: VerificationService = SupabaseVerificationService()
    lazy var refetcher: RefetchService = AppsFlyerRefetchService()
    lazy var discovery: DiscoveryService = HTTPDiscoveryService()
    lazy var consent: ConsentService = NotificationConsentService()
}
