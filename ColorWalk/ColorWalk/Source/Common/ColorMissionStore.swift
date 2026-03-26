//
//  ColorMissionStore.swift
//  ColorWalk
//

import UIKit
import RxSwift
import RxCocoa

final class ColorMissionStore {
    static let shared = ColorMissionStore()
    private init() {
        // 초기값 설정
        mission.accept(ColorMission.mockMissions[0])
    }

    let mission = BehaviorRelay<ColorMission>(value: ColorMission.mockMissions[0])

    func setMission(_ newMission: ColorMission) {
        mission.accept(newMission)
    }

    func updateColor(_ color: UIColor, hex: String) {
        let current = mission.value
        let updated = ColorMission(
            name: current.name,
            hexColor: hex,
            color: color,
            weatherInfo: current.weatherInfo,
            progress: current.progress
        )
        mission.accept(updated)
    }
}
