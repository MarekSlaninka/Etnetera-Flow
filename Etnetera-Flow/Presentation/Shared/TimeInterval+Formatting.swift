import Foundation

extension TimeInterval {
    var formattedDuration: String {
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        return hours > 0
            ? String(format: String(localized: "duration.hoursAndMinutes"), hours, minutes)
            : String(format: String(localized: "duration.minutes"), minutes)
    }
}
