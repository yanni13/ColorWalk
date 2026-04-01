import Foundation
import RxSwift
import RxCocoa

final class CollectionEditViewModel: ViewModelType {
    
    struct Input {
        let saveTap: Observable<Void>
    }
    
    struct Output {
        let slots: Driver<[SlotDisplayInfo]>
        let saveCompleted: Driver<Void>
    }
    
    private let slotsRelay: BehaviorRelay<[SlotDisplayInfo]>
    private let disposeBag = DisposeBag()
    
    init(slots: [SlotDisplayInfo]) {
        self.slotsRelay = BehaviorRelay(value: slots)
    }
    
    func transform(input: Input) -> Output {
        let saveCompleted = input.saveTap
            .map { _ in () }
            .asDriver(onErrorJustReturn: ())
            
        return Output(
            slots: slotsRelay.asDriver(),
            saveCompleted: saveCompleted
        )
    }
}
