//
//  ColorDetailViewModel.swift
//  ColorWalk
//

import RxSwift
import RxCocoa

final class ColorDetailViewModel: ViewModelType {

    struct Input {
        let swipeLeft:  Observable<Void>
        let swipeRight: Observable<Void>
        let backTap:    Observable<Void>
        let shareTap:   Observable<Void>
    }

    struct Output {
        let currentCard: Driver<ColorCard>
        let pageText: Driver<String>   // "1 / 9"
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
            .map { ($0 + 1) % count }
            .bind(to: currentIndexRelay)
            .disposed(by: disposeBag)

        input.swipeRight
            .withLatestFrom(currentIndexRelay)
            .map { ($0 - 1 + count) % count }
            .bind(to: currentIndexRelay)
            .disposed(by: disposeBag)

        input.backTap
            .subscribe(onNext: { [weak self] in self?.onBack?() })
            .disposed(by: disposeBag)

        input.shareTap
            .withLatestFrom(currentIndexRelay)
            .subscribe(onNext: { [weak self] index in
                guard let card = self?.cards[index] else { return }
                print("공유: \(card.colorName)")
            })
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

        return Output(currentCard: currentCard, pageText: pageText)
    }
}
