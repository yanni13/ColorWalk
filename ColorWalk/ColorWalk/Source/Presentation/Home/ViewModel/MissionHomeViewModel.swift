//
//  MissionHomeViewModel.swift
//  ColorWalk
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - Model

struct ColorMission {
    let name: String
    let hexColor: String
    let color: UIColor
    let weatherInfo: String
    let progress: Float
}

extension ColorMission {
    static let mockMissions: [ColorMission] = [
        ColorMission(
            name: "비 온 뒤 초록",
            hexColor: "#34D399",
            color: UIColor(hex: "#34D399"),
            weatherInfo: "오늘의 날씨: 흐린 후 맑음",
            progress: 0.0
        ),
        ColorMission(
            name: "하늘빛 파랑",
            hexColor: "#5B8DEF",
            color: UIColor(hex: "#5B8DEF"),
            weatherInfo: "오늘의 날씨: 맑음",
            progress: 0.0
        ),
        ColorMission(
            name: "노을 주황",
            hexColor: "#FF9500",
            color: UIColor(hex: "#FF9500"),
            weatherInfo: "오늘의 날씨: 구름 조금",
            progress: 0.0
        ),
        ColorMission(
            name: "벚꽃 핑크",
            hexColor: "#FF7EB3",
            color: UIColor(hex: "#FF7EB3"),
            weatherInfo: "오늘의 날씨: 맑음",
            progress: 0.0
        ),
        ColorMission(
            name: "새벽 보라",
            hexColor: "#BF5AF2",
            color: UIColor(hex: "#BF5AF2"),
            weatherInfo: "오늘의 날씨: 흐림",
            progress: 0.0
        )
    ]
}

// MARK: - ViewModel

final class MissionHomeViewModel: ViewModelType {

    struct Input {
        let shuffleTap: Observable<Void>
        let changeMissionTap: Observable<Void>
    }

    struct Output {
        let mission: Driver<ColorMission>
    }

    private let missions = ColorMission.mockMissions
    private let indexRelay = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        let count = missions.count

        Observable.merge(input.shuffleTap, input.changeMissionTap)
            .withLatestFrom(indexRelay)
            .map { ($0 + 1) % count }
            .bind(to: indexRelay)
            .disposed(by: disposeBag)

        let mission = indexRelay
            .map { [weak self] idx -> ColorMission in
                self?.missions[idx] ?? ColorMission.mockMissions[0]
            }
            .asDriver(onErrorJustReturn: ColorMission.mockMissions[0])

        return Output(mission: mission)
    }
}
