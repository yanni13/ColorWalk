import Foundation
import RealmSwift

final class RealmManager {

    // MARK: - Properties

    static let shared = RealmManager()

    private enum Constants {
        static let schemaVersion: UInt64 = 2
    }

    private init() {
        let config = Realm.Configuration(
            schemaVersion: Constants.schemaVersion,
            migrationBlock: { _, _ in }
        )
        Realm.Configuration.defaultConfiguration = config
    }

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

        write { realm in
            realm.add(photo) // 사진 객체 먼저 추가
            let slot = mission.slots[index]
            slot.linkedPhoto = photo
            slot.isCaptured = true

            let allCaptured = mission.slots.allSatisfy { $0.isCaptured }
            mission.isPaletteCompleted = allCaptured
        }
    }

    func deletePhoto(_ photo: Photo) {
        let fileName = photo.imagePath
        write { realm in
            ImageFileManager.shared.deleteImage(fileName: fileName)
            realm.delete(photo)
        }
    }

    func deleteAllPhotos() {
        let photos = realm.objects(Photo.self)
        write { realm in
            photos.forEach { ImageFileManager.shared.deleteImage(fileName: $0.imagePath) }
            realm.delete(photos)
        }
    }

    // MARK: - All Photos

    func fetchAllPhotos() -> [Photo] {
        Array(realm.objects(Photo.self).sorted(byKeyPath: "createdAt", ascending: false))
    }
}
