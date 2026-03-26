import Foundation

final class RealmMissionRepository: MissionRepositoryProtocol {

    // MARK: - MissionRepositoryProtocol

    func fetchOrCreateTodayMission() -> DailyMission {
        RealmManager.shared.fetchOrCreateTodayMission()
    }

    func fetchDailyMission(for dateIdentifier: String) -> DailyMission? {
        RealmManager.shared.fetchDailyMission(for: dateIdentifier)
    }

    func saveDailyMission(_ mission: DailyMission) {
        RealmManager.shared.saveDailyMission(mission)
    }
}
