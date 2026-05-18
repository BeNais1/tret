import Foundation

enum DateFormatterHelper {

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private static let absoluteFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func shortRelative(from date: Date, now: Date = Date()) -> String {
        let interval = now.timeIntervalSince(date)
        if interval < 60 { return "сейчас" }
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) мин"
        }
        if interval < 86_400 {
            let hours = Int(interval / 3600)
            return "\(hours) ч"
        }
        if interval < 7 * 86_400 {
            let days = Int(interval / 86_400)
            return "\(days) дн"
        }
        return absoluteFormatter.string(from: date)
    }
}
