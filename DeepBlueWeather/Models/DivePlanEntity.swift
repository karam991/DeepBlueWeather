//
//  DivePlanEntity.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 11.04.24.
//

import Foundation
import FirebaseFirestoreSwift


struct DivePlan: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var userId: String
    var location: String
    var date: String  
    var depth: Int
    var duration: Int
    var deepDive: Bool
    var nightDive: Bool
    /// Filled in after the dive. Optional so older documents still decode.
    var log: DiveLog? = nil
}

// MARK: - Date helpers

extension DivePlan {
    private static let localizedFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    /// Plans store the date as text; try every format the app has ever written.
    var parsedDate: Date? {
        DivePlan.localizedFormatter.date(from: date)
            ?? DateFormatter.firestoreDate.date(from: date)
            ?? DateFormatter.iso8601WithSeconds.date(from: date)
            ?? DateFormatter.iso8601Full.date(from: date)
    }

    /// "Today", "Tomorrow", "In 4 days", "3 days ago".
    var countdownLabel: String? {
        guard let parsedDate else { return nil }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: parsedDate)).day ?? 0
        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case 2...: return "In \(days) days"
        case -1: return "Yesterday"
        default: return "\(-days) days ago"
        }
    }

    var isPast: Bool { (parsedDate ?? .distantFuture) < Calendar.current.startOfDay(for: Date()) }
}
