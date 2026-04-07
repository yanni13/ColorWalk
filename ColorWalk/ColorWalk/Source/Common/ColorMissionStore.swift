//
//  ColorMissionStore.swift
//  ColorWalk
//

import UIKit
import RxSwift
import RxCocoa

final class ColorMissionStore {
    static let shared = ColorMissionStore()
    private init() {}

    let mission = BehaviorRelay<ColorMission>(value: ColorMission.placeholder)

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
