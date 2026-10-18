import Foundation
import RealmSwift

final class RealmManager {

    // MARK: - Properties

    static let shared = RealmManager()

    private enum Constants {
        static let schemaVersion: UInt64 = 6
        static let objectIdKeyedClasses = [
            "Photo", "Sticker", "ColorSlot", "User"
        ]
    }

    private init() {
        let config = Realm.Configuration(
            schemaVersion: Constants.schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion == 5 {
                    Self.dedupePrimaryKeys(migration)
                }
            }
        )

        // 기존 Realm 파일이 있다면 열기 전에 보호 속성 적용
        Self.applyFileProtection(to: config.fileURL)

        Realm.Configuration.defaultConfiguration = config

        print("[Realm] DB 경로: \(config.fileURL?.path ?? "경로 없음")")
    }

    // MARK: - File Protection

    /// 기존 Realm DB 파일에 완전한 파일 보호 적용
    private static func applyFileProtection(to realmURL: URL?) {
        guard let realmURL else {
            print("[Realm Protection] DB 경로를 찾을 수 없음")
            return
        }

        let fileManager = FileManager.default

        // 파일이 아직 생성되지 않았다면 적용할 수 없음
        guard fileManager.fileExists(atPath: realmURL.path) else {
            print("[Realm Protection] DB 파일이 아직 존재하지 않음")
            return
        }

        do {
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: realmURL.path
            )

            // 실제 적용 결과 확인
            let attributes = try fileManager.attributesOfItem(
                atPath: realmURL.path
            )

            let protection = attributes[.protectionKey]
                as? FileProtectionType

            if protection == .complete {
                print(
                    "[Realm Protection] 적용 및 검증 성공: " +
                    "\(realmURL.lastPathComponent) - \(protection!)"
                )
            } else {
                print(
                    "[Realm Protection] 보호 속성 불일치: " +
                    "\(String(describing: protection))"
                )
            }
        } catch {
            print(
                "[Realm Protection] 적용 실패: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Migration

    /// v5의 중복 키를 정리
    private static func dedupePrimaryKeys(_ migration: Migration) {
        var seenDates = Set<String>()

        migration.enumerateObjects(ofType: "DailyMission") { old, new in
            guard
                let new,
                let date = old?["dateIdentifier"] as? String
            else {
                return
            }

            if !seenDates.insert(date).inserted {
                migration.delete(new)
            }
        }

        for className in Constants.objectIdKeyedClasses {
            var seenIds = Set<ObjectId>()

            migration.enumerateObjects(ofType: className) { old, new in
                guard let new else { return }

                let id = old?["id"] as? ObjectId

                if id == nil || !seenIds.insert(id!).inserted {
                    let newId = ObjectId.generate()
                    seenIds.insert(newId)
                    new["id"] = newId
                }
            }
        }
    }

    // MARK: - Realm Access

    private var _mainRealm: Realm?

    private var mainRealm: Realm? {
        if Thread.isMainThread {
            if let realm = _mainRealm {
                return realm
            }

            do {
                let realm = try Realm()
                _mainRealm = realm
                return realm
            } catch {
                print("Main Realm initialization failed: \(error)")
                return nil
            }
        }

        return nil
    }

    private var realm: Realm {
        if Thread.isMainThread, let realm = mainRealm {
            return realm
        }

        do {
            return try Realm()
        } catch {
            fatalError("Realm 초기화 실패: \(error)")
        }
    }

    // MARK: - Write

    func write(_ block: (Realm) -> Void) {
        let realm = realm

        if realm.isInWriteTransaction {
            block(realm)
        } else {
            do {
                try realm.write {
                    block(realm)
                }
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
        realm.object(
            ofType: DailyMission.self,
            forPrimaryKey: dateIdentifier
        )
    }

    func fetchOrCreateTodayMission(
        in specificRealm: Realm? = nil
    ) -> DailyMission {
        let realm = specificRealm ?? self.realm
        let today = DateManager.storedString(from: Date())

        if let existing = realm.object(
            ofType: DailyMission.self,
            forPrimaryKey: today
        ) {
            return existing
        }

        let mission = DailyMission()
        mission.dateIdentifier = today

        let slots = (0..<9).map { index -> ColorSlot in
            let slot = ColorSlot()
            slot.index = index
            return slot
        }

        if realm.isInWriteTransaction {
            realm.add(mission)
            mission.slots.append(objectsIn: slots)
        } else {
            try? realm.write {
                realm.add(mission)
                mission.slots.append(objectsIn: slots)
            }
        }

        return mission
    }

    // MARK: - Photo

    func savePhoto(
        _ photo: Photo,
        toSlotIndex index: Int,
        missionId: String
    ) {
        write { realm in
            let mission = fetchOrCreateTodayMission(in: realm)

            guard index < mission.slots.count else { return }

            realm.add(photo)

            let slot = mission.slots[index]
            slot.linkedPhoto = photo
            slot.isCaptured = true

            mission.isPaletteCompleted =
                mission.slots.allSatisfy { $0.isCaptured }
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

            photos.forEach {
                ImageFileManager.shared.deleteImage(fileName: $0.imagePath)
            }

            realm.delete(photos)
        }
    }

    func deleteAllPhotosAndResetMission() {
        write { realm in
            let photos = realm.objects(Photo.self)

            photos.forEach {
                ImageFileManager.shared.deleteImage(fileName: $0.imagePath)
            }

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

    func updateTodayMission(
        hex: String,
        name: String,
        weather: String
    ) {
        write { realm in
            let mission = fetchOrCreateTodayMission(in: realm)
            mission.recommendedHex = hex
            mission.recommendedMissionName = name
            mission.weatherStatus = weather
        }
    }

    func reassignMissionSlots(
        missionId: String,
        photos: [Photo]
    ) {
        write { realm in
            guard let mission = realm.object(
                ofType: DailyMission.self,
                forPrimaryKey: missionId
            ) else {
                return
            }

            let sortedSlots = Array(mission.slots).sorted {
                $0.index < $1.index
            }

            sortedSlots.forEach { slot in
                slot.linkedPhoto = nil
                slot.isCaptured = false
            }

            for (index, photo) in photos.enumerated()
            where index < sortedSlots.count {
                guard let livePhoto = realm.object(
                    ofType: Photo.self,
                    forPrimaryKey: photo.id
                ) else {
                    continue
                }

                sortedSlots[index].linkedPhoto = livePhoto
                sortedSlots[index].isCaptured = true
            }

            mission.isPaletteCompleted =
                mission.slots.allSatisfy { $0.isCaptured }
        }
    }

    func savePhotoOnly(_ photo: Photo) {
        write { realm in
            realm.add(photo)
        }
    }

    // MARK: - All Photos

    func fetchAllPhotos() -> [Photo] {
        Array(
            realm.objects(Photo.self)
                .sorted(byKeyPath: "createdAt", ascending: false)
        )
    }

    // MARK: - Photo Helper

    func findMissionColor(for photo: Photo) -> String? {
        let slots = realm.objects(ColorSlot.self)
            .filter("linkedPhoto == %@", photo)

        guard
            let slot = slots.first,
            let mission = slot.parentMission.first
        else {
            return nil
        }

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
            guard
                !sticker.isInvalidated,
                realm.object(
                    ofType: Sticker.self,
                    forPrimaryKey: sticker.id
                ) != nil
            else {
                return
            }

            realm.delete(sticker)
        }
    }

    func fetchAllStickers() -> [Sticker] {
        Array(
            realm.objects(Sticker.self)
                .sorted(byKeyPath: "createdAt", ascending: false)
        )
    }

    func updateStickerName(_ sticker: Sticker, name: String) {
        write { realm in
            guard
                !sticker.isInvalidated,
                let live = realm.object(
                    ofType: Sticker.self,
                    forPrimaryKey: sticker.id
                )
            else {
                return
            }

            live.colorName = name
        }
    }
}
