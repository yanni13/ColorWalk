import Foundation
import RxSwift
import RxCocoa
import RealmSwift

enum MissionState {
    case noMission
    case inProgress(capturedCount: Int, slots: [SlotDisplayInfo])
    case completed(slots: [SlotDisplayInfo])
}

struct SlotDisplayInfo {
    let index: Int
    let imagePath: String?
    let capturedHex: String?
    let isCaptured: Bool
}

final class CollectionViewModel: ViewModelType {

    // MARK: - Input / Output

    struct Input {
        let viewWillAppear: Observable<Void>
        let prevDayTap: Observable<Void>
        let nextDayTap: Observable<Void>
    }

    struct Output {
        let dateText: Driver<String>
        let shareDateText: Driver<String>
        let missionColorHex: Driver<String>
        let missionMetaText: Driver<String>
        let missionState: Driver<MissionState>
        let canGoNext: Driver<Bool>
        let missionDateIdentifier: Driver<String>
    }

    // MARK: - Properties

    private let dayOffsetRelay = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: Input) -> Output {
        bindDayNavigation(input: input)
        let missionData = makeMissionDataObservable(input: input)
        return Output(
            dateText: makeDateTextDriver(missionData: missionData),
            shareDateText: makeShareDateTextDriver(missionData: missionData),
            missionColorHex: makeMissionColorHexDriver(missionData: missionData),
            missionMetaText: makeMissionMetaTextDriver(missionData: missionData),
            missionState: makeMissionStateDriver(missionData: missionData),
            canGoNext: makeCanGoNextDriver(),
            missionDateIdentifier: makeMissionDateIdentifierDriver(missionData: missionData)
        )
    }

    // MARK: - Private

    private func bindDayNavigation(input: Input) {
        input.prevDayTap
            .withLatestFrom(dayOffsetRelay)
            .map { $0 - 1 }
            .bind(to: dayOffsetRelay)
            .disposed(by: disposeBag)

        input.nextDayTap
            .withLatestFrom(dayOffsetRelay)
            .filter { $0 < 0 }
            .map { $0 + 1 }
            .bind(to: dayOffsetRelay)
            .disposed(by: disposeBag)
    }

    private func makeMissionDataObservable(input: Input) -> Observable<(Date, DailyMission?)> {
        let fetchTrigger = Observable.merge(
            dayOffsetRelay.map { _ in () },
            input.viewWillAppear
        )
        return fetchTrigger
            .map { [weak self] _ -> (Date, DailyMission?) in
                guard let self else { return (Date(), nil) }
                let date = DateManager.date(byAddingDays: self.dayOffsetRelay.value)
                let mission = RealmManager.shared.fetchDailyMission(
                    for: DateManager.storedString(from: date)
                )
                return (date, mission?.freeze())
            }
            .share(replay: 1)
    }

    private func makeDateTextDriver(missionData: Observable<(Date, DailyMission?)>) -> Driver<String> {
        missionData
            .map { (date, _) in DateManager.displayShortString(from: date) }
            .asDriver(onErrorJustReturn: "")
    }

    private func makeShareDateTextDriver(missionData: Observable<(Date, DailyMission?)>) -> Driver<String> {
        missionData
            .map { (date, _) -> String in
                let formatter = DateFormatter()
                formatter.dateFormat = AppConstants.DateFormat.displayShare
                return formatter.string(from: date)
            }
            .asDriver(onErrorJustReturn: "")
    }

    private func makeMissionColorHexDriver(missionData: Observable<(Date, DailyMission?)>) -> Driver<String> {
        missionData
            .map { (_, mission) -> String in
                guard let hex = mission?.recommendedHex, !hex.isEmpty else { return "#E5E8EB" }
                return hex
            }
            .asDriver(onErrorJustReturn: "#E5E8EB")
    }

    private func makeMissionMetaTextDriver(missionData: Observable<(Date, DailyMission?)>) -> Driver<String> {
        Observable.combineLatest(missionData, GridLayoutStore.shared.selectedLayout.asObservable())
            .map { (missionData, layout) -> String in
                let (_, mission) = missionData
                guard let mission else { return "" }
                let total = layout.slotCount
                let captured = min(mission.slots.filter { $0.linkedPhoto != nil }.count, total)
                
                if captured == total && total > 0 {
                    return L10n.missionCompleteStatus(total: total)
                }
                return L10n.missionIncompleteStatus(captured: captured, total: total)
            }
            .asDriver(onErrorJustReturn: "")
    }

    private func makeMissionStateDriver(missionData: Observable<(Date, DailyMission?)>) -> Driver<MissionState> {
        Observable.combineLatest(missionData, GridLayoutStore.shared.selectedLayout.asObservable())
            .map { (missionData, layout) -> MissionState in
                let (_, mission) = missionData
                guard let mission else { return .noMission }

                let maxSlotCount = layout.slotCount

                let capturedSlots = Array(mission.slots)
                    .sorted { $0.index < $1.index }
                    .filter { $0.linkedPhoto != nil }
                    .prefix(maxSlotCount) // 레이아웃 슬롯 수만큼 제한
                    .enumerated()
                    .map { index, slot -> SlotDisplayInfo in
                        SlotDisplayInfo(
                            index: index,
                            imagePath: slot.linkedPhoto?.imagePath,
                            capturedHex: slot.linkedPhoto?.capturedHex,
                            isCaptured: true
                        )
                    }

                let emptySlots = (capturedSlots.count..<maxSlotCount).map { index -> SlotDisplayInfo in
                    SlotDisplayInfo(index: index, imagePath: nil, capturedHex: nil, isCaptured: false)
                }

                let displaySlots = capturedSlots + emptySlots
                let capturedCount = capturedSlots.count

                return capturedCount == maxSlotCount
                    ? .completed(slots: displaySlots)
                    : .inProgress(capturedCount: capturedCount, slots: displaySlots)
            }
            .asDriver(onErrorJustReturn: .noMission)
    }

    private func makeCanGoNextDriver() -> Driver<Bool> {
        dayOffsetRelay
            .map { $0 < 0 }
            .asDriver(onErrorJustReturn: false)
    }

    private func makeMissionDateIdentifierDriver(missionData: Observable<(Date, DailyMission?)>) -> Driver<String> {
        missionData
            .map { (date, _) in DateManager.storedString(from: date) }
            .asDriver(onErrorJustReturn: "")
    }
}
