import UserNotifications
import Combine
import SwiftUI


final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    private let reminderID = "fp.daily.reminder"

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])

        let content = UNMutableNotificationContent()
        content.title = "Focus Pick"
        content.body  = "Time to train your focus. 2 minutes is enough."
        content.sound = .default

        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let req = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        center.add(req, withCompletionHandler: nil)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID])
    }

    func pendingPreviewSummary(completion: @escaping (String) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            DispatchQueue.main.async {
                completion("Pending: \(reqs.count)")
            }
        }
    }
}


final class NotificationConsentService: ConsentService {

    func solicitPublisher() -> AnyPublisher<Bool, Never> {
        return Deferred {
            Future<Bool, Never> { promise in
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                ) { granted, _ in
                    DispatchQueue.main.async {
                        promise(.success(granted))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func arm() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
