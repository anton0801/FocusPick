import Foundation

struct WriteModel {
    var measurements: [String: String]
    var trails: [String: String]
    var anchorURL: String?
    var anchorMode: String?
    var virgin: Bool
    var sealed: Bool
    var consentApproved: Bool
    var consentRefused: Bool
    var consentTime: Date?
    var organicVisited: Bool
    
    static let blank = WriteModel(
        measurements: [:],
        trails: [:],
        anchorURL: nil,
        anchorMode: nil,
        virgin: true,
        sealed: false,
        consentApproved: false,
        consentRefused: false,
        consentTime: nil,
        organicVisited: false
    )
}

struct ReadModel {
    let hasMeasurements: Bool
    let isOrganic: Bool
    let isVirgin: Bool
    let consentEligible: Bool
    let anchorURL: String?
    
    static func project(from write: WriteModel) -> ReadModel {
        let isOrganic = write.measurements["af_status"] == "Organic"
        
        let consentEligible: Bool = {
            guard !write.consentApproved && !write.consentRefused else { return false }
            if let date = write.consentTime {
                let elapsed = Date().timeIntervalSince(date) / 86400
                return elapsed >= 3
            }
            return true
        }()
        
        return ReadModel(
            hasMeasurements: !write.measurements.isEmpty,
            isOrganic: isOrganic,
            isVirgin: write.virgin,
            consentEligible: consentEligible,
            anchorURL: write.anchorURL
        )
    }
}

struct StoredBundle {
    let measurements: [String: String]
    let trails: [String: String]
    let anchorURL: String?
    let anchorMode: String?
    let virgin: Bool
    let consentApproved: Bool
    let consentRefused: Bool
    let consentTime: Date?
}

enum FocusCommand {
    case bootstrap
    case absorbMeasurements([String: Any])
    case absorbTrails([String: Any])
    case launchSequence
    case approveConsent
    case dismissConsent
}

enum FocusQuery {
    case currentReadModel
    case isSequenceDone
}

enum QueryResult {
    case readModel(ReadModel)
    case bool(Bool)
}

enum FocusAction {
    case stayOnSplash
    case promptConsent
    case voyageToWeb
    case voyageToMain
}

struct ErrorTag {}
struct NetworkTag {}
struct ValidationTag {}
struct ServerTag {}

enum FocusError: Error {
    case dryInput
    case verificationFell
    case backendDeclined
    case packetMangled
    case wireDown
    case ceiling
    case watchOut
}

// MARK: - Constants

struct FocusConstants {
    static let appNumeric = "6764559400"
    static let trailKey = "KsWDUYx9P7WuLY2fRoVH2Y"
    static let groupKit = "group.focuspick.kit"
    static let cookieBox = "focuspick_box"
    static let backendBay = "https://focuspiick.com/config.php"
    static let logEmblem = "🎯 [FocusPick]"
}

enum BoxKey<T> {
    case measurements
    case trails
    case anchorURL
    case anchorMode
    case voyaged
    case consentApproved
    case consentRefused
    case consentTime
    case pushURL
    case fcmToken
    case pushToken
    
    var raw: String {
        switch self {
        case .measurements: return "fpk_measurements"
        case .trails: return "fpk_trails"
        case .anchorURL: return "fpk_anchor_url"
        case .anchorMode: return "fpk_anchor_mode"
        case .voyaged: return "fpk_voyaged"
        case .consentApproved: return "fpk_consent_yes"
        case .consentRefused: return "fpk_consent_no"
        case .consentTime: return "fpk_consent_at"
        case .pushURL: return "temp_url"
        case .fcmToken: return "fcm_token"
        case .pushToken: return "push_token"
        }
    }
}
