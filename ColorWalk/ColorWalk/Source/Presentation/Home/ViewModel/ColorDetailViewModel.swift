//
//  ColorDetailViewModel.swift
//  ColorWalk
//

import UIKit
import RxSwift
import RxCocoa

final class ColorDetailViewModel: ViewModelType {

    struct Input {
        let swipeLeft:  Observable<Void>
        let swipeRight: Observable<Void>
        let backTap:    Observable<Void>
        let shareTap:   Observable<Void>
    }

    struct ChevronState {
        let leftAlpha: CGFloat
        let rightAlpha: CGFloat
    }

    struct Output {
        let currentCard: Driver<ColorCard>
        let pageText: Driver<String>
        let shareCard: Driver<ColorCard>
        let chevronState: Driver<ChevronState>
    }

    var onBack: (() -> Void)?

    private let cards: [ColorCard]
    private let currentIndexRelay: BehaviorRelay<Int>
    private let disposeBag = DisposeBag()

    init(cards: [ColorCard], startIndex: Int) {
        self.cards = cards
        self.currentIndexRelay = BehaviorRelay(value: startIndex)
    }

    func transform(input: Input) -> Output {
        let count = cards.count

        input.swipeLeft
            .withLatestFrom(currentIndexRelay)
            .filter { $0 < count - 1 }
            .map { $0 + 1 }
            .bind(to: currentIndexRelay)
            .disposed(by: disposeBag)

        input.swipeRight
            .withLatestFrom(currentIndexRelay)
            .filter { $0 > 0 }
            .map { $0 - 1 }
            .bind(to: currentIndexRelay)
            .disposed(by: disposeBag)

        input.backTap
            .subscribe(onNext: { [weak self] in self?.onBack?() })
            .disposed(by: disposeBag)

        let shareCardRelay = PublishRelay<ColorCard>()

        input.shareTap
            .withLatestFrom(currentIndexRelay)
            .compactMap { [weak self] index in self?.cards[index] }
            .bind(to: shareCardRelay)
            .disposed(by: disposeBag)

        let currentCard = currentIndexRelay
            .map { [weak self] index -> ColorCard in
                self?.cards[index] ?? ColorCard.mockCards[0]
            }
            .asDriver(onErrorJustReturn: ColorCard.mockCards[0])

        let pageText = currentIndexRelay
            .map { [weak self] index -> String in
                guard let self else { return "" }
                return "\(index + 1) / \(self.cards.count)"
            }
            .asDriver(onErrorJustReturn: "")

        let shareCard = shareCardRelay.asDriver(onErrorDriveWith: .empty())

        let chevronState = currentIndexRelay
            .map { index -> ChevronState in
                guard count > 1 else { return ChevronState(leftAlpha: 0, rightAlpha: 0) }
                return ChevronState(
                    leftAlpha:  index > 0           ? 1.0 : 0.3,
                    rightAlpha: index < count - 1   ? 1.0 : 0.3
                )
            }
            .asDriver(onErrorJustReturn: ChevronState(leftAlpha: 0, rightAlpha: 0))

        return Output(currentCard: currentCard, pageText: pageText, shareCard: shareCard, chevronState: chevronState)
    }
}
