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

    private init() {
        checkDailyReset()
        loadFromRealm()
    }

    func add(_ card: ColorCard) {
        checkDailyReset()
        
        // 오늘 미션이 없으면 생성 (RealmManager 활용)
        let today = currentDateString()
        _ = RealmManager.shared.fetchOrCreateTodayMission()
        
        // 이미지 저장 및 Realm 저장
        if let image = card.capturedImage {
            let fileName = "photo_\(UUID().uuidString).jpg"
            if ImageFileManager.shared.saveImage(image: image, fileName: fileName) != nil {
                let photo = Photo()
                photo.imagePath = fileName
                photo.capturedHex = card.hexColor
                photo.matchRate = Double(card.matchPercentage)
                photo.createdAt = Date()
                
                // 슬롯 인덱스 결정: 0이면 첫 번째 빈 슬롯 찾기 (최대 9개)
                let currentIndex = cards.value.count
                let slotIndex = (card.missionCurrent > 0) ? (card.missionCurrent - 1) : currentIndex
                
                if slotIndex < 9 {
                    repository.savePhoto(photo, toSlotIndex: slotIndex, missionId: today)
                }
            }
        }
        
        var current = cards.value
        current.insert(card, at: 0)
        cards.accept(current)
    }

    func checkDailyReset() {
        let today = currentDateString()
        let lastReset = userDefaults.string(forKey: lastResetKey)

        if lastReset != today {
            repository.deleteAllPhotos()
            cards.accept([])
            userDefaults.set(today, forKey: lastResetKey)
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
                colorName: "수집된 색상",
                hexColor: photo.capturedHex,
                dotColor: UIColor(hex: photo.capturedHex),
                locationName: "현재 위치",
                captureDate: formatter.string(from: photo.createdAt),
                matchPercentage: Int(photo.matchRate),
                missionCurrent: 0, // 표시용으로는 0이어도 무관하나 필요시 로직 추가
                missionTotal: 9
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
