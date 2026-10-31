import BackgroundTasks
import ComposableArchitecture
import Foundation
import Models
import SwiftUI
import TwitterClient
import TwitterUI
import UserNotifications

enum NotificationCheck {
    static let taskID = "gold.samhenri.Twitter.notifications"
    private static let lastUnreadCountKey = "lastNotifiedUnreadCount"
    private static let individualLimit = 3

    static var isOn: Bool { UserDefaults.standard.bool(forKey: RetroSettings.notifiesKey) }

    static func schedule() {
        guard isOn else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskID)
            return
        }
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        Task { try? await BGTaskScheduler.shared.submitTaskRequest(request) }
    }

    static func run() async {
        schedule()
        guard isOn else { return }
        @Dependency(TwitterClient.self) var client
        guard (try? await client.restoreSession()) != nil,
            let unread = try? await client.unreadNotificationCount()
        else { return }

        let defaults = UserDefaults.standard
        let lastUnread = defaults.integer(forKey: lastUnreadCountKey)
        defaults.set(unread, forKey: lastUnreadCountKey)
        try? await UNUserNotificationCenter.current().setBadgeCount(unread)
        guard unread > lastUnread else { return }

        let arrived = unread - lastUnread
        let page = try? await client.feed(.notifications(.all), nil)
        let newest = (page?.items ?? []).compactMap { item -> TwitterNotification? in
            guard case .notification(let notification) = item, notification.isUnread else { return nil }
            return notification
        }
        if arrived <= individualLimit, !newest.isEmpty {
            for notification in newest.prefix(arrived) {
                await post(id: notification.id, body: notification.message)
            }
        } else {
            await post(
                id: "unread-\(unread)",
                body: String(localized: "You have \(arrived) new notifications.")
            )
        }
    }

    static func appBecameActive() {
        Task { try? await UNUserNotificationCenter.current().setBadgeCount(0) }
    }

    private static func post(id: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = .default
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: nil))
    }
}

extension View {
    func schedulesNotificationChecks() -> some View {
        modifier(SchedulesNotificationChecks())
    }
}

private struct SchedulesNotificationChecks: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background: NotificationCheck.schedule()
                case .active: NotificationCheck.appBecameActive()
                default: break
                }
            }
            .task {
                #if DEBUG
                    let arguments = ProcessInfo.processInfo.arguments
                    if let index = arguments.firstIndex(of: "--check-notifications-in"), index + 1 < arguments.count,
                        let seconds = Double(arguments[index + 1])
                    {
                        try? await Task.sleep(for: .seconds(seconds))
                        await NotificationCheck.run()
                    }
                #endif
            }
    }
}
