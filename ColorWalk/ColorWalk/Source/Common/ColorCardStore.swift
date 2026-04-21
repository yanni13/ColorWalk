//
//  ColorCardStore.swift
//  ColorWalk
//

import Foundation
import RxCocoa
import UIKit
import RxCocoa
import RealmSwift
internal import Realm

final class ColorCardStore {
    static let shared = ColorCardStore()
    private let userDefaults = UserDefaults.standard
    private let lastResetKey = "lastResetDate"
    private let repository: PhotoRepositoryProtocol = RealmPhotoRepository()

    let cards = BehaviorRelay<[ColorCard]>(value: [])
    var didResetToday: Bool = false

    private init() {
        checkDailyReset()
        loadFromRealm()
    }

    func add(_ card: ColorCard) {
        checkDailyReset()
        
        // 오늘 미션이 없으면 생성 및 초기값 설정
        let today = currentDateString()
        let mission = RealmManager.shared.fetchOrCreateTodayMission()
        
        // 미션 기본 정보가 비어있으면 현재 미션 정보로 업데이트
        if mission.recommendedHex.isEmpty {
            let currentMission = ColorMissionStore.shared.mission.value
            RealmManager.shared.write { realm in
                mission.recommendedHex = currentMission.hexColor
                mission.weatherStatus = currentMission.weatherInfo
            }
        }
        
        // 이미지 저장 및 Realm 저장
        if let image = card.capturedImage {
            let fileName = "photo_\(UUID().uuidString).jpg"
            if ImageFileManager.shared.saveImage(image: image, fileName: fileName) != nil {
                let photo = Photo()
                photo.imagePath = fileName
                photo.capturedHex = card.hexColor
                photo.matchRate = Double(card.matchPercentage)
                photo.latitude = card.latitude
                photo.longitude = card.longitude
                photo.locationName = card.locationName
                photo.createdAt = Date()

                // 슬롯 인덱스 결정: 0이면 첫 번째 빈 슬롯 찾기
                let slotIndex = (card.missionCurrent > 0) ? (card.missionCurrent - 1) : cards.value.count
                let maxSlotCount = GridLayoutStore.shared.selectedLayout.value.slotCount

                if slotIndex < maxSlotCount {
                    repository.savePhoto(photo, toSlotIndex: slotIndex, missionId: today)
                } else {
                    repository.savePhotoOnly(photo)
                }
            }
        }

        WidgetDataWriter.shared.updateWidgetData(with: ColorMissionStore.shared.mission.value)

        var current = cards.value
        current.insert(card, at: 0)
        cards.accept(current)
    }

    func remove(at index: Int) {
        let current = cards.value
        guard index < current.count else { return }

        let photos = repository.fetchAllPhotos()
        if index < photos.count {
            repository.deletePhoto(photos[index])
        }

        var updated = current
        updated.remove(at: index)
        cards.accept(updated)
    }

    func clearAll() {
        RealmManager.shared.deleteAllPhotosAndResetMission()
        cards.accept([])
    }

    func checkDailyReset() {
        let today = currentDateString()
        let lastReset = userDefaults.string(forKey: lastResetKey)

        if lastReset != today {
            repository.deleteAllPhotos()
            cards.accept([])
            userDefaults.set(today, forKey: lastResetKey)
            didResetToday = true
        }
    }

    private func loadFromRealm() {
        let photos = repository.fetchAllPhotos()
        let loadedCards = photos.map { photo -> ColorCard in
            let uiImage = ImageFileManager.shared.loadImage(fileName: photo.imagePath)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd"
            
            // 저장된 사진의 순서를 기반으로 missionCurrent 복구
            return ColorCard(
                id: photo.id.stringValue,
                imageURL: nil,
                capturedImage: uiImage,
                colorName: L10n.colorCardCollected,
                hexColor: photo.capturedHex,
                dotColor: UIColor(hex: photo.capturedHex),
                locationName: photo.locationName,
                captureDate: formatter.string(from: photo.createdAt),
                matchPercentage: Int(photo.matchRate),
                missionCurrent: 0, // 표시용으로는 0이어도 무관하나 필요시 로직 추가
                missionTotal: GridLayoutStore.shared.selectedLayout.value.slotCount,
                latitude: photo.latitude,
                longitude: photo.longitude
            )
        }
        cards.accept(loadedCards)
    }

    private func currentDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}
