import Foundation
import RxSwift
import RxCocoa

final class StickerVaultViewModel: ViewModelType {

    // MARK: - Input / Output

    struct Input {
        let viewWillAppear: Observable<Void>
        let deleteSticker: Observable<Sticker>
    }

    struct Output {
        let stickers: Driver<[Sticker]>
        let isEmpty: Driver<Bool>
    }

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {
        let stickersRelay = BehaviorRelay<[Sticker]>(value: [])

        input.viewWillAppear
            .map { StickerManager.shared.fetchAll() }
            .bind(to: stickersRelay)
            .disposed(by: disposeBag)

        input.deleteSticker
            .subscribe(onNext: { [weak stickersRelay] sticker in
                StickerManager.shared.delete(sticker)
                let updated = StickerManager.shared.fetchAll()
                stickersRelay?.accept(updated)
            })
            .disposed(by: disposeBag)

        let stickers = stickersRelay.asDriver()
        let isEmpty = stickers.map { $0.isEmpty }

        return Output(stickers: stickers, isEmpty: isEmpty)
    }
}
