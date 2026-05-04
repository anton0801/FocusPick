import Foundation

protocol Storage {
    func putMeasurements(_ data: [String: String])
    func putTrails(_ data: [String: String])
    func putAnchor(url: String, mode: String)
    func putConsent(approved: Bool, refused: Bool, at: Date?)
    func setVoyaged()
    func fetchBundle() -> StoredBundle
}

final class KeyValueWrapper: Storage {
    
    private let groupVault: UserDefaults
    private let homeVault: UserDefaults
    
    init() {
        self.groupVault = UserDefaults(suiteName: FocusConstants.groupKit)!
        self.homeVault = UserDefaults.standard
    }
    
    // MARK: - Generic typed accessors
    
    private func writeString(_ value: String, _ key: BoxKey<String>) {
        groupVault.set(value, forKey: key.raw)
    }
    
    private func writeBool(_ value: Bool, _ key: BoxKey<Bool>) {
        groupVault.set(value, forKey: key.raw)
    }
    
    private func writeDouble(_ value: Double, _ key: BoxKey<Double>) {
        groupVault.set(value, forKey: key.raw)
    }
    
    private func readString(_ key: BoxKey<String>) -> String? {
        groupVault.string(forKey: key.raw)
    }
    
    private func readBool(_ key: BoxKey<Bool>) -> Bool {
        groupVault.bool(forKey: key.raw)
    }
    
    private func readDouble(_ key: BoxKey<Double>) -> Double {
        groupVault.double(forKey: key.raw)
    }
    
    // MARK: - Domain operations
    
    func putMeasurements(_ data: [String: String]) {
        guard let serialized = encode(data) else { return }
        writeString(serialized, BoxKey<String>.measurements)
    }
    
    func putTrails(_ data: [String: String]) {
        guard let serialized = encode(data) else { return }
        let masked = mask(serialized)
        writeString(masked, BoxKey<String>.trails)
    }
    
    func putAnchor(url: String, mode: String) {
        writeString(url, BoxKey<String>.anchorURL)
        homeVault.set(url, forKey: BoxKey<String>.anchorURL.raw)
        writeString(mode, BoxKey<String>.anchorMode)
    }
    
    func putConsent(approved: Bool, refused: Bool, at: Date?) {
        writeBool(approved, BoxKey<Bool>.consentApproved)
        writeBool(refused, BoxKey<Bool>.consentRefused)
        
        if let when = at {
            let ms = when.timeIntervalSince1970 * 1000
            writeDouble(ms, BoxKey<Double>.consentTime)
        }
    }
    
    func setVoyaged() {
        writeBool(true, BoxKey<Bool>.voyaged)
    }
    
    func fetchBundle() -> StoredBundle {
        let measurementsRaw = readString(BoxKey<String>.measurements) ?? ""
        let measurements = decode(measurementsRaw) ?? [:]
        
        let trailsMasked = readString(BoxKey<String>.trails) ?? ""
        let trailsRaw = unmask(trailsMasked) ?? ""
        let trails = decode(trailsRaw) ?? [:]
        
        let anchorURL = readString(BoxKey<String>.anchorURL)
        let anchorMode = readString(BoxKey<String>.anchorMode)
        let voyaged = readBool(BoxKey<Bool>.voyaged)
        
        let approved = readBool(BoxKey<Bool>.consentApproved)
        let refused = readBool(BoxKey<Bool>.consentRefused)
        let timeMs = readDouble(BoxKey<Double>.consentTime)
        let consentTime = timeMs > 0 ? Date(timeIntervalSince1970: timeMs / 1000) : nil
        
        return StoredBundle(
            measurements: measurements,
            trails: trails,
            anchorURL: anchorURL,
            anchorMode: anchorMode,
            virgin: !voyaged,
            consentApproved: approved,
            consentRefused: refused,
            consentTime: consentTime
        )
    }
    
    // MARK: - Encode / Decode
    
    private func encode(_ dict: [String: String]) -> String? {
        let any = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: any),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
    
    private func decode(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let any = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return any.mapValues { "\($0)" }
    }
    
    // MARK: - Masking
    
    private func mask(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "=", with: "[")
            .replacingOccurrences(of: "+", with: "]")
    }
    
    private func unmask(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "[", with: "=")
            .replacingOccurrences(of: "]", with: "+")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
}
