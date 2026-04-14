import Foundation
import UIKit
import WidgetKit
import RxCocoa
internal import Realm

// MARK: - Shared Widget Models (Main App Side)

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

// MARK: - WidgetDataWriter

final class WidgetDataWriter {

    static let shared = WidgetDataWriter()

    private enum Constants {
        static let appGroupID = "group.com.yanni13.ColorWalk"
        static let dailyDataKey = "widgetDailyData"
        static let imageDirName = "WidgetImages"
        static let lastWeatherSymbolKey = "lastWeatherSymbol"
        static let thumbnailSize = CGSize(width: 300, height: 300)
        static let maxPhotoCount = 3
    }

    private init() {}

    func writeWeatherSymbol(_ symbol: String) {
        guard let defaults = UserDefaults(suiteName: Constants.appGroupID) else { return }
        defaults.set(symbol, forKey: Constants.lastWeatherSymbolKey)
    }

    func updateWidgetData(with mission: ColorMission? = nil) {
        let photos = Array(RealmManager.shared.fetchAllPhotos().prefix(Constants.maxPhotoCount))
        let currentMission = mission ?? ColorMissionStore.shared.mission.value

        let formatter = DateFormatter()
        formatter.dateFormat = AppConstants.DateFormat.widgetDisplayShort
        let dateString = formatter.string(from: Date())

        let photoInfos: [WidgetPhotoInfo] = photos.compactMap { photo in
            let thumbnailFileName = "widget_\(photo.id.stringValue).jpg"
            createAndSaveWidgetThumbnail(imagePath: photo.imagePath, fileName: thumbnailFileName)
            return WidgetPhotoInfo(
                imageFileName: thumbnailFileName,
                capturedHex: photo.capturedHex,
                colorName: colorName(for: photo.capturedHex),
                locationName: photo.locationName,
                createdAt: photo.createdAt
            )
        }

        let missionHex = currentMission.hexColor
        let missionName = currentMission.name

        let storedFormatter = DateFormatter()
        storedFormatter.dateFormat = "yyyy-MM-dd"
        let dateIdentifier = storedFormatter.string(from: Date())

        let dailyData = WidgetDailyData(
            dateString: dateString,
            missionColorHex: missionHex,
            missionColorName: missionName,
            photos: photoInfos,
            dateIdentifier: dateIdentifier
        )

        guard let defaults = UserDefaults(suiteName: Constants.appGroupID),
              let encoded = try? JSONEncoder().encode(dailyData) else { return }

        defaults.set(encoded, forKey: Constants.dailyDataKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private

    private func createAndSaveWidgetThumbnail(imagePath: String, fileName: String) {
        // 1. 원본 이미지 로딩 (FileManager에서 로드)
        guard let originalImage = ImageFileManager.shared.loadImage(fileName: imagePath) else { return }
        
        // 2. 1:1 중앙 크롭
        guard let squareImage = originalImage.cropToSquare() else { return }
        
        // 3. 위젯 최적화 크기로 리사이징 (예: 600x600 px)
        let targetSize = Constants.thumbnailSize // 이미 300x300으로 정의됨
        guard let resizedImage = squareImage.resized(to: targetSize) else { return }
        
        // 4. App Group 경로 확보
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupID
        ) else { return }

        let dirURL = containerURL.appendingPathComponent(Constants.imageDirName)
        try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

        // 5. JPEG 압축 및 저장
        let fileURL = dirURL.appendingPathComponent(fileName)
        guard let data = resizedImage.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: fileURL)
    }

    private func colorName(for hex: String) -> String {
        switch hex.lowercased() {
        case "#ffd700": return "노랑"
        case "#87ceeb": return "하늘"
        case "#ffa500": return "주황"
        case "#ff7eb3": return "핑크"
        case "#fde047": return "노랑"
        case "#708090": return "회색"
        case "#b0c4de": return "파랑"
        case "#94a3b8": return "회색"
        case "#64748b": return "슬레이트"
        case "#e2e8f0": return "연회색"
        case "#34d399": return "초록"
        case "#4682b4": return "파랑"
        case "#10b981": return "초록"
        case "#064e3b": return "진초록"
        case "#0f172a": return "남색"
        case "#483d8b": return "보라"
        case "#ff4500": return "오렌지"
        case "#4b0082": return "인디고"
        case "#dc2626": return "빨강"
        case "#1e293b": return "회청색"
        default: return hex.uppercased()
        }
    }
}
