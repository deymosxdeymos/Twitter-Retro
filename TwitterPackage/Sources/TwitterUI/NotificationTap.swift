import Foundation

@MainActor
package enum NotificationTap {
    package static let didTap = Notification.Name("NotificationTap.didTap")
    private static var isPending = false

    package static func record() {
        isPending = true
        NotificationCenter.default.post(name: didTap, object: nil)
    }

    package static func consume() -> Bool {
        defer { isPending = false }
        return isPending
    }
}
