import Foundation
import RxSwift
import RxCocoa

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
        let missionColorHex: Driver<String>
        let missionMetaText: Driver<String>
        let missionState: Driver<MissionState>
        let canGoNext: Driver<Bool>
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
            missionColorHex: makeMissionColorHexDriver(missionData: missionData),
            missionMetaText: makeMissionMetaTextDriver(missionData: missionData),
            missionState: makeMissionStateDriver(missionData: missionData),
            canGoNext: makeCanGoNextDriver()
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
                return (date, mission)
            }
            .share(replay: 1)
    }

    private func makeDateTextDriver(missionData: Observable<(Date, DailyMission?)>) -> Driver<String> {
        missionData
            .map { (date, _) in DateManager.displayShortString(from: date) }
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
        missionData
            .map { (_, mission) -> String in
                guard let mission else { return "" }
                let captured = mission.slots.filter { $0.isCaptured }.count
                let total = mission.slots.count
                if mission.isPaletteCompleted {
                    return "\(AppConstants.Text.missionComplete) (\(total)/\(total))"
                }
                return "\(AppConstants.Text.missionIncomplete) (\(captured)/\(total))"
            }
            .asDriver(onErrorJustReturn: "")
    }

    private func makeMissionStateDriver(missionData: Observable<(Date, DailyMission?)>) -> Driver<MissionState> {
        missionData
            .map { (_, mission) -> MissionState in
                guard let mission else { return .noMission }
                let sortedSlots = Array(mission.slots)
                    .map { slot -> SlotDisplayInfo in
                        SlotDisplayInfo(
                            index: slot.index,
                            imagePath: slot.linkedPhoto?.imagePath,
                            capturedHex: slot.linkedPhoto?.capturedHex,
                            isCaptured: slot.isCaptured
                        )
                    }
                    .sorted { $0.index < $1.index }
                
                let capturedCount = sortedSlots.filter { $0.isCaptured }.count
                
                // 미션 객체만 있으면 진행 중(inProgress)으로 간주하여 그리드를 표시함
                return mission.isPaletteCompleted
                    ? .completed(slots: sortedSlots)
                    : .inProgress(capturedCount: capturedCount, slots: sortedSlots)
            }
            .asDriver(onErrorJustReturn: .noMission)
    }

    private func makeCanGoNextDriver() -> Driver<Bool> {
        dayOffsetRelay
            .map { $0 < 0 }
            .asDriver(onErrorJustReturn: false)
    }
}
