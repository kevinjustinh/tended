import Foundation

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily   = "daily"
    case weekly  = "weekly"
    case custom  = "custom"

    var displayName: String {
        switch self {
        case .daily:  return "Daily"
        case .weekly: return "Weekly"
        case .custom: return "Custom"
        }
    }
}

struct RecurrenceRule: Codable, Equatable {
    var frequency: RecurrenceFrequency
    /// For custom: repeat every `interval` days
    var interval: Int
    /// For weekly: which weekdays (0 = Sunday … 6 = Saturday)
    var weekdays: [Int]

    // Convenience presets
    static let daily   = RecurrenceRule(frequency: .daily,  interval: 1, weekdays: [])
    static let weekly  = RecurrenceRule(frequency: .weekly, interval: 7, weekdays: [])

    static func weekdays(_ days: [Int]) -> RecurrenceRule {
        RecurrenceRule(frequency: .weekly, interval: 1, weekdays: days)
    }

    static func every(_ days: Int) -> RecurrenceRule {
        RecurrenceRule(frequency: .custom, interval: days, weekdays: [])
    }

    /// Returns true if this rule fires on the given date
    func fires(on date: Date, startingFrom start: Date) -> Bool {
        let cal = Calendar.current
        switch frequency {
        case .daily:
            return true
        case .weekly:
            if weekdays.isEmpty {
                let diff = cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: date)).day ?? 0
                return diff >= 0 && diff % 7 == 0
            } else {
                let weekday = cal.component(.weekday, from: date) - 1  // 0-indexed
                return weekdays.contains(weekday)
            }
        case .custom:
            let diff = cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: date)).day ?? 0
            return diff >= 0 && diff % interval == 0
        }
    }

    var displayString: String {
        switch frequency {
        case .daily:
            return "Every day"
        case .weekly:
            if weekdays.isEmpty { return "Every week" }
            let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
            let dayNames = weekdays.sorted().compactMap { names[safe: $0] }.joined(separator: ", ")
            return "Every \(dayNames)"
        case .custom:
            return interval == 1 ? "Every day" : "Every \(interval) days"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
