//
//  DiveReminderService.swift
//  DeepBlueWeather
//
//  Local notifications: a reminder the evening before each dive
//  (or a short-notice one if the dive was planned for the same day).
//

import Foundation
import UserNotifications

enum DiveReminderService {
    private static let prefix = "dive-reminder-"
    static let enabledKey = "diveRemindersEnabled"

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    /// Asks for permission once; returns whether reminders may be shown.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    /// Re-creates reminders for all upcoming plans and removes stale ones.
    static func sync(with plans: [DivePlan]) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ours = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: ours)

            guard isEnabled else { return }

            for plan in plans {
                guard let id = plan.id, let date = plan.parsedDate, date > Date(), plan.log == nil else { continue }
                guard let (fireDate, body) = schedule(for: plan, diveDate: date) else { continue }

                let content = UNMutableNotificationContent()
                content.title = "🤿 \(plan.location.capitalized) \(Calendar.current.isDate(date, inSameDayAs: fireDate) ? "today" : "tomorrow")"
                content.body = body
                content.sound = .default

                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                center.add(UNNotificationRequest(identifier: prefix + id, content: content, trigger: trigger))
            }
        }
    }

    private static func schedule(for plan: DivePlan, diveDate: Date) -> (Date, String)? {
        let cal = Calendar.current
        let time = diveDate.formatted(date: .omitted, time: .shortened)
        var extras: [String] = []
        if plan.nightDive { extras.append("torches") }
        if plan.deepDive || plan.depth > 30 { extras.append("SMB & redundant air") }
        let extraText = extras.isEmpty ? "" : " Don't forget: \(extras.joined(separator: ", "))."

        // Evening before at 19:00
        if let dayBefore = cal.date(byAdding: .day, value: -1, to: diveDate),
           let evening = cal.date(bySettingHour: 19, minute: 0, second: 0, of: dayBefore),
           evening > Date() {
            return (evening, "Dive at \(time), \(plan.depth) m for \(plan.duration) min. Open your smart gear list to pack.\(extraText)")
        }
        // Planned at short notice: 2 hours before
        let shortNotice = diveDate.addingTimeInterval(-2 * 3600)
        if shortNotice > Date().addingTimeInterval(60) {
            return (shortNotice, "Dive at \(time) — time to pack your gear.\(extraText)")
        }
        return nil
    }
}
