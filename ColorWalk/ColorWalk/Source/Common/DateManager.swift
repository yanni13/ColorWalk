import Foundation

struct DateManager {

    static func storedString(from date: Date) -> String {
        formatter(format: AppConstants.DateFormat.stored).string(from: date)
    }

    static func displayShortString(from date: Date) -> String {
        let fmt = formatter(format: AppConstants.DateFormat.displayShort)
        fmt.locale = Locale(identifier: "ko_KR")
        return fmt.string(from: date)
    }

    static func date(byAddingDays offset: Int, to base: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: base) ?? base
    }

    static func date(fromStoredString string: String) -> Date? {
        formatter(format: AppConstants.DateFormat.stored).date(from: string)
    }

    private static func formatter(format: String) -> DateFormatter {
        let fmt = DateFormatter()
        fmt.dateFormat = format
        return fmt
    }
}
