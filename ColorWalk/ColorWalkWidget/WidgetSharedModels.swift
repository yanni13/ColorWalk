import SwiftUI
import UIKit

// MARK: - Constants

enum WidgetConstants {
    static let appGroupID = "group.com.yanni13.ColorWalk"
    static let dailyDataKey = "widgetDailyData"
    static let imageDirName = "WidgetImages"
}

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
