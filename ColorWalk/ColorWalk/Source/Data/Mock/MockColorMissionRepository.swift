import Foundation

final class MockColorMissionRepository: ColorMissionRepositoryProtocol {

    // MARK: - ColorMissionRepositoryProtocol

    func fetchMissions() -> [ColorMission] {
        ColorMission.mockMissions
    }
}
