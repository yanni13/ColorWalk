import Foundation
import RealmSwift

final class MockMissionRepository: MissionRepositoryProtocol {

    // MARK: - Properties

    private lazy var todayMission: DailyMission = Self.makeMockMission()

    // MARK: - MissionRepositoryProtocol

    func fetchOrCreateTodayMission() -> DailyMission {
        todayMission
    }

    func fetchDailyMission(for dateIdentifier: String) -> DailyMission? {
        guard todayMission.dateIdentifier == dateIdentifier else { return nil }
        return todayMission
    }

    func saveDailyMission(_ mission: DailyMission) {}

    // MARK: - Mock Data

    private static func makeMockMission() -> DailyMission {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let mission = DailyMission()
        mission.dateIdentifier = formatter.string(from: Date())
        mission.weatherStatus = "맑음"
        mission.recommendedHex = "#34D399"

        let slotData: [(hex: String?, rate: Double)] = [
            ("#34D399", 0.91),
            ("#5B8DEF", 0.85),
            (nil, 0),
            ("#FF7EB3", 0.98),
            (nil, 0),
            (nil, 0),
            ("#FF9500", 0.76),
            (nil, 0),
            (nil, 0),
        ]

        let slots: [ColorSlot] = slotData.enumerated().map { index, data in
            let slot = ColorSlot()
            slot.index = index

            if let hex = data.hex {
                let photo = Photo()
                photo.capturedHex = hex
                photo.matchRate = data.rate
                photo.imagePath = ""
                photo.createdAt = Date()
                slot.linkedPhoto = photo
                slot.isCaptured = true
            }

            return slot
        }

        mission.slots.append(objectsIn: slots)
        return mission
    }
}
