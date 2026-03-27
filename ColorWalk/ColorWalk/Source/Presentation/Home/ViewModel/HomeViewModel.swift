//
//  HomeViewModel.swift
//  ColorWalk
//

import UIKit
import RxSwift
import RxCocoa

struct ColorCard {
    let id: String
    let imageURL: URL?
    let capturedImage: UIImage?
    let colorName: String
    let hexColor: String
    let dotColor: UIColor
    let locationName: String
    let captureDate: String
    let matchPercentage: Int
    let missionCurrent: Int
    let missionTotal: Int
    let latitude: Double
    let longitude: Double
}

// MARK: - Mock Data
extension ColorCard {
    static let mockCards: [ColorCard] = [
        ColorCard(
            id: "1",
            imageURL: URL(string: "https://images.unsplash.com/photo-1683652584550-5fdbc14762bf?w=1080"),
            capturedImage: nil,
            colorName: "Sunset Pink",
            hexColor: "#FF7EB3",
            dotColor: UIColor(hex: "#FF7EB3"),
            locationName: "여의도 한강공원",
            captureDate: "2026.03.20",
            matchPercentage: 98,
            missionCurrent: 5,
            missionTotal: 9,
            latitude: 37.5284,
            longitude: 126.9331
        ),
        ColorCard(
            id: "2",
            imageURL: URL(string: "https://images.unsplash.com/photo-1634596570024-00e86e21f876?w=1080"),
            capturedImage: nil,
            colorName: "Ocean Blue",
            hexColor: "#3182F6",
            dotColor: UIColor(hex: "#3182F6"),
            locationName: "광안리 해수욕장",
            captureDate: "2026.03.18",
            matchPercentage: 85,
            missionCurrent: 3,
            missionTotal: 9,
            latitude: 35.1531,
            longitude: 129.1189
        ),
        ColorCard(
            id: "3",
            imageURL: URL(string: "https://images.unsplash.com/photo-1561495391-457141312761?w=1080"),
            capturedImage: nil,
            colorName: "Forest Green",
            hexColor: "#34C759",
            dotColor: UIColor(hex: "#34C759"),
            locationName: "북한산 국립공원",
            captureDate: "2026.03.15",
            matchPercentage: 91,
            missionCurrent: 7,
            missionTotal: 9,
            latitude: 37.6611,
            longitude: 126.9936
        ),
        ColorCard(
            id: "4",
            imageURL: URL(string: "https://images.unsplash.com/photo-1561495391-457141312761?w=1080"),
            capturedImage: nil,
            colorName: "Golden Hour",
            hexColor: "#FF9500",
            dotColor: UIColor(hex: "#FF9500"),
            locationName: "경복궁",
            captureDate: "2026.03.12",
            matchPercentage: 76,
            missionCurrent: 2,
            missionTotal: 9,
            latitude: 37.5796,
            longitude: 126.9770
        ),
        ColorCard(
            id: "5",
            imageURL: URL(string: "https://images.unsplash.com/photo-1634596570024-00e86e21f876?w=1080"),
            capturedImage: nil,
            colorName: "Lavender Mist",
            hexColor: "#BF5AF2",
            dotColor: UIColor(hex: "#BF5AF2"),
            locationName: "남산타워",
            captureDate: "2026.03.10",
            matchPercentage: 88,
            missionCurrent: 6,
            missionTotal: 9,
            latitude: 37.5512,
            longitude: 126.9882
        ),
        ColorCard(
            id: "6",
            imageURL: URL(string: "https://picsum.photos/seed/mint/400/600"),
            capturedImage: nil,
            colorName: "민트 그린",
            hexColor: "#34D399",
            dotColor: UIColor(hex: "#34D399"),
            locationName: "강남역",
            captureDate: "2026.03.06",
            matchPercentage: 72,
            missionCurrent: 7,
            missionTotal: 9,
            latitude: 37.4979,
            longitude: 127.0276
        ),
        ColorCard(
            id: "7",
            imageURL: URL(string: "https://picsum.photos/seed/sky/400/600"),
            capturedImage: nil,
            colorName: "하늘빛 파랑",
            hexColor: "#5B8DEF",
            dotColor: UIColor(hex: "#5B8DEF"),
            locationName: "잠실 석촌호수",
            captureDate: "2026.03.04",
            matchPercentage: 94,
            missionCurrent: 8,
            missionTotal: 9,
            latitude: 37.5115,
            longitude: 127.1032
        ),
        ColorCard(
            id: "8",
            imageURL: URL(string: "https://picsum.photos/seed/golden/400/600"),
            capturedImage: nil,
            colorName: "황금빛 주황",
            hexColor: "#FFB347",
            dotColor: UIColor(hex: "#FFB347"),
            locationName: "성수동",
            captureDate: "2026.03.01",
            matchPercentage: 81,
            missionCurrent: 9,
            missionTotal: 9,
            latitude: 37.5445,
            longitude: 127.0560
        ),
        ColorCard(
            id: "9",
            imageURL: URL(string: "https://picsum.photos/seed/brick/400/600"),
            capturedImage: nil,
            colorName: "벽돌 레드",
            hexColor: "#FF6B6B",
            dotColor: UIColor(hex: "#FF6B6B"),
            locationName: "광화문",
            captureDate: "2026.02.24",
            matchPercentage: 67,
            missionCurrent: 9,
            missionTotal: 9,
            latitude: 37.5759,
            longitude: 126.9768
        )
    ]
}

// MARK: - HomeViewModel
final class HomeViewModel: ViewModelType {

    struct Input {
        let swipeLeft: Observable<Void>
        let swipeRight: Observable<Void>
        let shareTap: Observable<Void>
        let saveTap: Observable<Void>
    }

    struct Output {
        let currentCard: Driver<ColorCard>
        let currentIndex: Driver<Int>
        let totalCards: Driver<Int>
        let progressRatio: Driver<Float>
        let missionText: Driver<String>
    }

    private let repository: ColorCardRepositoryProtocol
    private let cards: [ColorCard]
    private let currentIndexRelay = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()

    init(repository: ColorCardRepositoryProtocol = MockColorCardRepository()) {
        self.repository = repository
        self.cards = repository.fetchColorCards()
    }

    func transform(input: Input) -> Output {
        let count = cards.count

        input.swipeLeft
            .withLatestFrom(currentIndexRelay)
            .map { ($0 + 1) % count }
            .bind(to: currentIndexRelay)
            .disposed(by: disposeBag)

        input.swipeRight
            .withLatestFrom(currentIndexRelay)
            .map { ($0 - 1 + count) % count }
            .bind(to: currentIndexRelay)
            .disposed(by: disposeBag)

        input.shareTap
            .subscribe(onNext: { [weak self] in
                guard let self,
                      let card = self.currentCard else { return }
                print("공유: \(card.colorName)")
            })
            .disposed(by: disposeBag)

        input.saveTap
            .subscribe(onNext: { [weak self] in
                guard let self,
                      let card = self.currentCard else { return }
                print("저장: \(card.colorName)")
            })
            .disposed(by: disposeBag)

        let currentCard = currentIndexRelay
            .map { [weak self] index -> ColorCard in
                self?.cards[index] ?? ColorCard.mockCards[0]
            }
            .asDriver(onErrorJustReturn: ColorCard.mockCards[0])

        let progressRatio = currentIndexRelay
            .map { [weak self] index -> Float in
                guard let self else { return 0 }
                return Float(self.cards[index].matchPercentage) / 100.0
            }
            .asDriver(onErrorJustReturn: 0)

        let missionText = currentIndexRelay
            .map { [weak self] index -> String in
                guard let self else { return "" }
                let card = self.cards[index]
                return "\(card.missionCurrent) / \(card.missionTotal)"
            }
            .asDriver(onErrorJustReturn: "")

        return Output(
            currentCard: currentCard,
            currentIndex: currentIndexRelay.asDriver(),
            totalCards: .just(cards.count),
            progressRatio: progressRatio,
            missionText: missionText
        )
    }

    private var currentCard: ColorCard? {
        let index = currentIndexRelay.value
        guard index < cards.count else { return nil }
        return cards[index]
    }
}
