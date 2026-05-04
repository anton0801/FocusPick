import Foundation
import Combine

@MainActor
final class FocusPickViewModel: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let hub = MediatorHub()
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        wireUpActions()
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    private func wireUpActions() {
        hub.actionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                self?.handleAction(action)
            }
            .store(in: &cancellables)
    }
    
    func boot() {
        Task {
            await hub.send(.bootstrap)
            armDeadline()
        }
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        Task {
            await hub.send(.absorbMeasurements(data))
            await hub.send(.launchSequence)
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        Task {
            await hub.send(.absorbTrails(data))
        }
    }
    
    func acceptConsent() {
        Task {
            await hub.send(.approveConsent)
            showPermissionPrompt = false
        }
    }
    
    func skipConsent() {
        Task {
            await hub.send(.dismissConsent)
            showPermissionPrompt = false
        }
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleAction(_ action: FocusAction) {
        guard !uiLocked else {
            return
        }
        
        switch action {
        case .stayOnSplash:
            break
        case .promptConsent:
            showPermissionPrompt = true
        case .voyageToWeb:
            navigateToWeb = true
        case .voyageToMain:
            navigateToMain = true
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.hub.reportDeadlineHit()
            if shouldFire {
                self.handleAction(.voyageToMain)
            }
        }
    }
}
