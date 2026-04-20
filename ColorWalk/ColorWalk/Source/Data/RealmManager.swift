import Foundation
import RealmSwift

final class RealmManager {

    // MARK: - Properties

    static let shared = RealmManager()

    private enum Constants {
        static let schemaVersion: UInt64 = 4
    }

    private init() {
        let config = Realm.Configuration(
            schemaVersion: Constants.schemaVersion,
            migrationBlock: { _, _ in }
        )
        Realm.Configuration.defaultConfiguration = config
    }

    private var mainRealm: Realm? {
        if Thread.isMainThread {
            if let r = _mainRealm { return r }
            do {
                let r = try Realm()
                _mainRealm = r
                return r
            } catch {
                print("Main Realm initialization failed: \(error)")
                return nil
            }
        }
        return nil
    }
    private var _mainRealm: Realm?

    private var realm: Realm {
        if Thread.isMainThread, let r = mainRealm {
            return r
        }
        do {
            return try Realm()
        } catch {
            fatalError("Realm 초기화 실패: \(error)")
        }
    }

    // MARK: - Write

    func write(_ block: (Realm) -> Void) {
        let r = realm
        if r.isInWriteTransaction {
            block(r)
        } else {
            do {
                try r.write { block(r) }
            } catch {
                print("[Realm] 쓰기 실패: \(error)")
            }
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

    func fetchOrCreateTodayMission(in specificRealm: Realm? = nil) -> DailyMission {
        let r = specificRealm ?? realm
        let today = DateManager.storedString(from: Date())

        if let existing = r.object(ofType: DailyMission.self, forPrimaryKey: today) {
            return existing
        }

        let mission = DailyMission()
        mission.dateIdentifier = today

        let slots = (0..<9).map { i -> ColorSlot in
            let slot = ColorSlot()
            slot.index = i
            return slot
        }
        
        if r.isInWriteTransaction {
            r.add(mission)
            mission.slots.append(objectsIn: slots)
        } else {
            try? r.write {
                r.add(mission)
                mission.slots.append(objectsIn: slots)
            }
        }
        return mission
    }

    // MARK: - Photo

    func savePhoto(_ photo: Photo, toSlotIndex index: Int, missionId: String) {
        write { realm in
            let today = DateManager.storedString(from: Date())
            let mission = fetchOrCreateTodayMission(in: realm)
            
            guard index < mission.slots.count else { return }

            realm.add(photo) 
            let slot = mission.slots[index]
            slot.linkedPhoto = photo
            slot.isCaptured = true

            let allCaptured = mission.slots.allSatisfy { $0.isCaptured }
            mission.isPaletteCompleted = allCaptured
        }
    }

    func deletePhoto(_ photo: Photo) {
        write { realm in
            guard !photo.isInvalidated else { return }
            let fileName = photo.imagePath
            ImageFileManager.shared.deleteImage(fileName: fileName)
            realm.delete(photo)
        }
    }

    func deleteAllPhotos() {
        write { realm in
            let photos = realm.objects(Photo.self)
            photos.forEach { ImageFileManager.shared.deleteImage(fileName: $0.imagePath) }
            realm.delete(photos)
        }
    }

    func deleteAllPhotosAndResetMission() {
        write { realm in
            let photos = realm.objects(Photo.self)
            photos.forEach { ImageFileManager.shared.deleteImage(fileName: $0.imagePath) }
            realm.delete(photos)

            let mission = fetchOrCreateTodayMission(in: realm)
            mission.isPaletteCompleted = false
            mission.recommendedHex = ""
            mission.slots.forEach { slot in
                slot.isCaptured = false
                slot.linkedPhoto = nil
            }
        }
    }

    func resetTodayMissionState() {
        write { realm in
            let mission = fetchOrCreateTodayMission(in: realm)
            mission.isPaletteCompleted = false
            mission.recommendedHex = ""
            mission.slots.forEach { slot in
                slot.isCaptured = false
                slot.linkedPhoto = nil
            }
        }
    }

    func updateTodayMissionHex(_ hex: String) {
        write { realm in
            let mission = fetchOrCreateTodayMission(in: realm)
            mission.recommendedHex = hex
        }
    }

    func updateTodayMission(hex: String, name: String, weather: String) {
        write { realm in
            let mission = fetchOrCreateTodayMission(in: realm)
            mission.recommendedHex = hex
            mission.recommendedMissionName = name
            mission.weatherStatus = weather
        }
    }

    func reassignMissionSlots(missionId: String, photos: [Photo]) {
        write { realm in
            guard let mission = realm.object(ofType: DailyMission.self, forPrimaryKey: missionId) else { return }
            let sortedSlots = Array(mission.slots).sorted { $0.index < $1.index }
            sortedSlots.forEach { slot in
                slot.linkedPhoto = nil
                slot.isCaptured = false
            }
            for (i, photo) in photos.enumerated() where i < sortedSlots.count {
                guard let livePhoto = realm.object(ofType: Photo.self, forPrimaryKey: photo.id) else { continue }
                sortedSlots[i].linkedPhoto = livePhoto
                sortedSlots[i].isCaptured = true
            }
            mission.isPaletteCompleted = mission.slots.allSatisfy { $0.isCaptured }
        }
    }

    func savePhotoOnly(_ photo: Photo) {
        write { realm in
            realm.add(photo)
        }
    }

    // MARK: - All Photos

    func fetchAllPhotos() -> [Photo] {
        Array(realm.objects(Photo.self).sorted(byKeyPath: "createdAt", ascending: false))
    }

    // MARK: - Photo Helper

    func findMissionColor(for photo: Photo) -> String? {
        let slots = realm.objects(ColorSlot.self).filter("linkedPhoto == %@", photo)
        guard let slot = slots.first,
              let mission = slot.parentMission.first else { return nil }
        return mission.recommendedHex
    }

    // MARK: - Sticker

    func saveSticker(_ sticker: Sticker) {
        write { realm in
            realm.add(sticker)
        }
    }

    func deleteSticker(_ sticker: Sticker) {
        write { realm in
            guard !sticker.isInvalidated else { return }
            realm.delete(sticker)
        }
    }

    func fetchAllStickers() -> [Sticker] {
        Array(realm.objects(Sticker.self).sorted(byKeyPath: "createdAt", ascending: false))
    }
}
