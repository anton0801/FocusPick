import Foundation
import AppsFlyerLib
import Combine

final class MediatorHub {
    
    private var writeModel: WriteModel = .blank
    
    private(set) var readModel: ReadModel = ReadModel.project(from: .blank) {
        didSet {
            readModelSubject.send(readModel)
        }
    }
    
    private let readModelSubject = CurrentValueSubject<ReadModel, Never>(ReadModel.project(from: .blank))
    var readModelPublisher: AnyPublisher<ReadModel, Never> {
        readModelSubject.eraseToAnyPublisher()
    }
    
    private let actionSubject = PassthroughSubject<FocusAction, Never>()
    var actionPublisher: AnyPublisher<FocusAction, Never> {
        actionSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    
    private let container = FocusContainer.shared
    private var cancellables = Set<AnyCancellable>()
    
    func send(_ command: FocusCommand) async {
        switch command {
        case .bootstrap:
            await CommandBootstrapHandler(hub: self).handle()
            
        case .absorbMeasurements(let data):
            CommandAbsorbMeasurementsHandler(hub: self).handle(data)
            
        case .absorbTrails(let data):
            CommandAbsorbTrailsHandler(hub: self).handle(data)
            
        case .launchSequence:
            await CommandLaunchSequenceHandler(hub: self).handle()
            
        case .approveConsent:
            await CommandApproveConsentHandler(hub: self).handle()
            
        case .dismissConsent:
            CommandDismissConsentHandler(hub: self).handle()
        }
    }
    
    func ask(_ query: FocusQuery) -> QueryResult {
        switch query {
        case .currentReadModel:
            return .readModel(readModel)
        case .isSequenceDone:
            return .bool(sequenceCompleted)
        }
    }
    
    func updateWrite(_ mutate: (inout WriteModel) -> Void) {
        mutate(&writeModel)
        readModel = ReadModel.project(from: writeModel)
    }
    
    func emit(_ action: FocusAction) {
        actionSubject.send(action)
    }
    
    func markSequenceCompleted() {
        sequenceCompleted = true
    }
    
    var currentWrite: WriteModel { writeModel }
    var dependencies: FocusContainer { container }
    
    func reportDeadlineHit() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
}

final class CommandBootstrapHandler {
    private weak var hub: MediatorHub?
    
    init(hub: MediatorHub) { self.hub = hub }
    
    func handle() async {
        guard let hub = hub else { return }
        
        let bundle = hub.dependencies.storage.fetchBundle()
        
        hub.updateWrite { write in
            write.measurements = bundle.measurements
            write.trails = bundle.trails
            write.anchorURL = bundle.anchorURL
            write.anchorMode = bundle.anchorMode
            write.virgin = bundle.virgin
            write.consentApproved = bundle.consentApproved
            write.consentRefused = bundle.consentRefused
            write.consentTime = bundle.consentTime
        }
    }
}

final class CommandAbsorbMeasurementsHandler {
    private weak var hub: MediatorHub?
    
    init(hub: MediatorHub) { self.hub = hub }
    
    func handle(_ raw: [String: Any]) {
        guard let hub = hub else { return }
        
        let mapped = raw.mapValues { "\($0)" }
        
        hub.updateWrite { write in
            write.measurements = mapped
        }
        
        hub.dependencies.storage.putMeasurements(mapped)
    }
}

final class CommandAbsorbTrailsHandler {
    private weak var hub: MediatorHub?
    
    init(hub: MediatorHub) { self.hub = hub }
    
    func handle(_ raw: [String: Any]) {
        guard let hub = hub else { return }
        
        let mapped = raw.mapValues { "\($0)" }
        
        hub.updateWrite { write in
            write.trails = mapped
        }
        
        hub.dependencies.storage.putTrails(mapped)
    }
}

final class CommandLaunchSequenceHandler {
    private weak var hub: MediatorHub?
    
    init(hub: MediatorHub) { self.hub = hub }
    
    func handle() async {
        guard let hub = hub else { return }
        
        if case .bool(let done) = hub.ask(.isSequenceDone), done {
            return
        }
        
        if let tempURL = UserDefaults.standard.string(forKey: BoxKey<String>.pushURL.raw),
           !tempURL.isEmpty {
            await finalizeAnchor(hub: hub, url: tempURL)
            return
        }
        
        guard hub.readModel.hasMeasurements else {
            return
        }
        
        let verificationOK = await runVerification(hub: hub)
        
        if !verificationOK {
            hub.markSequenceCompleted()
            hub.emit(.voyageToMain)
            return
        }
        
        if hub.readModel.isOrganic && hub.readModel.isVirgin && !hub.currentWrite.organicVisited {
            hub.updateWrite { $0.organicVisited = true }
            await performOrganicRefetch(hub: hub)
        }
        
        let seed = hub.currentWrite.measurements.mapValues { $0 as Any }
        
        do {
            let url = try await hub.dependencies.discovery.discoverEndpoint(seed: seed)
            await finalizeAnchor(hub: hub, url: url)
        } catch {
            hub.markSequenceCompleted()
            hub.emit(.voyageToMain)
        }
    }
    
    private func runVerification(hub: MediatorHub) async -> Bool {
        let op = hub.dependencies.verification.runVerification()
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            op.completionBlock = {
                if case .success(let value) = op.result {
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func performOrganicRefetch(hub: MediatorHub) async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !hub.currentWrite.sealed else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await hub.dependencies.refetcher.refetchAttribution(deviceID: deviceID)
            
            for (k, v) in hub.currentWrite.trails {
                if fetched[k] == nil {
                    fetched[k] = v
                }
            }
            
            let mapped = fetched.mapValues { "\($0)" }
            hub.updateWrite { $0.measurements = mapped }
            hub.dependencies.storage.putMeasurements(mapped)
        } catch {
        }
    }
    
    private func finalizeAnchor(hub: MediatorHub, url: String) async {
        let needsConsent = hub.readModel.consentEligible
        
        hub.updateWrite { write in
            write.anchorURL = url
            write.anchorMode = "Active"
            write.virgin = false
            write.sealed = true
        }
        
        hub.dependencies.storage.putAnchor(url: url, mode: "Active")
        hub.dependencies.storage.setVoyaged()
        
        UserDefaults.standard.removeObject(forKey: BoxKey<String>.pushURL.raw)
        
        hub.markSequenceCompleted()
        
        hub.emit(needsConsent ? .promptConsent : .voyageToWeb)
    }
}

final class CommandApproveConsentHandler {
    private weak var hub: MediatorHub?
    private var cancellable: AnyCancellable?
    
    init(hub: MediatorHub) { self.hub = hub }
    
    func handle() async {
        guard let hub = hub else { return }
        
        let priorApproved = hub.currentWrite.consentApproved
        let priorRefused = hub.currentWrite.consentRefused
        
        let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            cancellable = hub.dependencies.consent.solicitPublisher()
                .first()
                .sink { [weak self] granted in
                    self?.cancellable?.cancel()
                    continuation.resume(returning: granted)
                }
        }
        
        let now = Date()
        
        if granted {
            hub.updateWrite { write in
                write.consentApproved = true
                write.consentRefused = false
                write.consentTime = now
            }
            hub.dependencies.consent.arm()
        } else {
            hub.updateWrite { write in
                write.consentApproved = false
                write.consentRefused = true
                write.consentTime = now
            }
        }
        
        _ = priorApproved
        _ = priorRefused
        
        hub.dependencies.storage.putConsent(
            approved: hub.currentWrite.consentApproved,
            refused: hub.currentWrite.consentRefused,
            at: hub.currentWrite.consentTime
        )
        
        hub.emit(.voyageToWeb)
    }
}

final class CommandDismissConsentHandler {
    private weak var hub: MediatorHub?
    
    init(hub: MediatorHub) { self.hub = hub }
    
    func handle() {
        guard let hub = hub else { return }
        
        let now = Date()
        hub.updateWrite { write in
            write.consentTime = now
        }
        
        hub.dependencies.storage.putConsent(
            approved: hub.currentWrite.consentApproved,
            refused: hub.currentWrite.consentRefused,
            at: now
        )
        
        hub.emit(.voyageToWeb)
    }
}
