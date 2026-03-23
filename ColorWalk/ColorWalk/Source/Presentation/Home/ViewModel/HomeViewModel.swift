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
    let colorName: String
    let hexColor: String
    let dotColor: UIColor
    let locationName: String
    let captureDate: String
    let matchPercentage: Int
    let missionCurrent: Int
    let missionTotal: Int
}

// MARK: - Mock Data
extension ColorCard {
    static let mockCards: [ColorCard] = [
        ColorCard(
            id: "1",
            imageURL: URL(string: "https://images.unsplash.com/photo-1683652584550-5fdbc14762bf?w=1080"),
            colorName: "Sunset Pink",
            hexColor: "#FF7EB3",
            dotColor: UIColor(hex: "#FF7EB3"),
            locationName: "여의도 한강공원",
            captureDate: "2026.03.20",
            matchPercentage: 98,
            missionCurrent: 5,
            missionTotal: 9
        ),
        ColorCard(
            id: "2",
            imageURL: URL(string: "https://images.unsplash.com/photo-1634596570024-00e86e21f876?w=1080"),
            colorName: "Ocean Blue",
            hexColor: "#3182F6",
            dotColor: UIColor(hex: "#3182F6"),
            locationName: "광안리 해수욕장",
            captureDate: "2026.03.18",
            matchPercentage: 85,
            missionCurrent: 3,
            missionTotal: 9
        ),
        ColorCard(
            id: "3",
            imageURL: URL(string: "https://images.unsplash.com/photo-1561495391-457141312761?w=1080"),
            colorName: "Forest Green",
            hexColor: "#34C759",
            dotColor: UIColor(hex: "#34C759"),
            locationName: "북한산 국립공원",
            captureDate: "2026.03.15",
            matchPercentage: 91,
            missionCurrent: 7,
            missionTotal: 9
        ),
        ColorCard(
            id: "4",
            imageURL: URL(string: "https://images.unsplash.com/photo-1561495391-457141312761?w=1080"),
            colorName: "Golden Hour",
            hexColor: "#FF9500",
            dotColor: UIColor(hex: "#FF9500"),
            locationName: "경복궁",
            captureDate: "2026.03.12",
            matchPercentage: 76,
            missionCurrent: 2,
            missionTotal: 9
        ),
        ColorCard(
            id: "5",
            imageURL: URL(string: "https://images.unsplash.com/photo-1634596570024-00e86e21f876?w=1080"),
            colorName: "Lavender Mist",
            hexColor: "#BF5AF2",
            dotColor: UIColor(hex: "#BF5AF2"),
            locationName: "남산타워",
            captureDate: "2026.03.10",
            matchPercentage: 88,
            missionCurrent: 6,
            missionTotal: 9
        )
    ]
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
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

    private let cards: [ColorCard] = ColorCard.mockCards
    private let currentIndexRelay = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()

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
