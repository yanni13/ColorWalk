import Foundation
import RealmSwift

final class RealmManager {

    static let shared = RealmManager()
    private init() {}

    private var realm: Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Realm 초기화 실패: \(error)")
        }
    }

    // MARK: - Write

    func write(_ block: (Realm) -> Void) {
        do {
            try realm.write { block(realm) }
        } catch {
            print("[Realm] 쓰기 실패: \(error)")
        }
    }

    // MARK: - DailyMission

    func saveDailyMission(_ mission: DailyMission) {
        write { realm in
            realm.add(mission, update: .modified)
        }
    }

    func fetchDailyMission(for dateIdentifier: String) -> DailyMission? {
        realm.object(ofType: DailyMission.self, forPrimaryKey: dateIdentifier)
    }

    func fetchOrCreateTodayMission() -> DailyMission {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        if let existing = fetchDailyMission(for: today) {
            return existing
        }

        let mission = DailyMission()
        mission.dateIdentifier = today

        let slots = (0..<9).map { i -> ColorSlot in
            let slot = ColorSlot()
            slot.index = i
            return slot
        }
        write { realm in
            realm.add(mission)
            mission.slots.append(objectsIn: slots)
        }
        return mission
    }

    // MARK: - Photo

    func savePhoto(_ photo: Photo, toSlotIndex index: Int, missionId: String) {
        guard let mission = fetchDailyMission(for: missionId),
              index < mission.slots.count else { return }

        write { _ in
            let slot = mission.slots[index]
            slot.linkedPhoto = photo
            slot.isCaptured = true

            let allCaptured = mission.slots.allSatisfy { $0.isCaptured }
            mission.isPaletteCompleted = allCaptured
        }
    }

    // MARK: - All Photos

    func fetchAllPhotos() -> [Photo] {
        Array(realm.objects(Photo.self).sorted(byKeyPath: "createdAt", ascending: false))
    }
}
