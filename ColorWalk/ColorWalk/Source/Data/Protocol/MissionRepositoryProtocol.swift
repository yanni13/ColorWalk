import Foundation

protocol MissionRepositoryProtocol {
    func fetchOrCreateTodayMission() -> DailyMission
    func fetchDailyMission(for dateIdentifier: String) -> DailyMission?
    func saveDailyMission(_ mission: DailyMission)
}
