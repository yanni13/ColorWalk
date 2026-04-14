import SwiftUI
import UIKit

// MARK: - Codable Models

struct WidgetPhotoInfo: Codable {
    let imageFileName: String
    let capturedHex: String
    let colorName: String
    let locationName: String
    let createdAt: Date
}

struct WidgetDailyData: Codable {
    let dateString: String
    let missionColorHex: String
    let missionColorName: String
    let photos: [WidgetPhotoInfo]
    let dateIdentifier: String?
}

// MARK: - Data Store

final class WidgetDataStore {

    static let shared = WidgetDataStore()
    private init() {}

    func loadDailyData() -> WidgetDailyData? {
        guard let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID),
              let data = defaults.data(forKey: WidgetConstants.dailyDataKey) else { return nil }
        return try? JSONDecoder().decode(WidgetDailyData.self, from: data)
    }

    func loadWeatherSymbol() -> String? {
        UserDefaults(suiteName: WidgetConstants.appGroupID)?.string(forKey: WidgetConstants.lastWeatherSymbolKey)
    }

    func loadImage(fileName: String) -> UIImage? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WidgetConstants.appGroupID
        ) else { return nil }
        let fileURL = containerURL
            .appendingPathComponent(WidgetConstants.imageDirName)
            .appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
}

// MARK: - Color Generator

enum WidgetColorGenerator {

    private static let clearPool   = ["#FFD700", "#87CEEB", "#FFA500", "#FF7EB3", "#FDE047"]
    private static let cloudyPool  = ["#708090", "#B0C4DE", "#94A3B8", "#64748B", "#E2E8F0"]
    private static let rainyPool   = ["#34D399", "#4682B4", "#10B981", "#064E3B", "#0F172A"]
    private static let extremePool = ["#483D8B", "#FF4500", "#4B0082", "#DC2626", "#1E293B"]

    static func hex(for date: Date, weatherSymbol: String?) -> String {
        let pool: [String]
        switch weatherSymbol {
        case let s? where s.contains("sun") || s.contains("clear"):
            pool = clearPool
        case let s? where s.contains("cloud"):
            pool = cloudyPool
        case let s? where s.contains("rain") || s.contains("snow") || s.contains("drizzle"):
            pool = rainyPool
        case let s? where !s.isEmpty:
            pool = extremePool
        default:
            pool = clearPool + cloudyPool
        }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return pool[(dayOfYear - 1) % pool.count]
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
