//
//  ColorCardStore.swift
//  ColorWalk
//

import Foundation
import RxCocoa

final class ColorCardStore {
    static let shared = ColorCardStore()
    private let userDefaults = UserDefaults.standard
    private let lastResetKey = "lastResetDate"

    let cards = BehaviorRelay<[ColorCard]>(value: [])

    private init() {
        checkDailyReset()
    }

    func add(_ card: ColorCard) {
        checkDailyReset()
        var current = cards.value
        current.insert(card, at: 0)
        cards.accept(current)
    }

    func checkDailyReset() {
        let today = currentDateString()
        let lastReset = userDefaults.string(forKey: lastResetKey)

        if lastReset != today {
            cards.accept([])
            userDefaults.set(today, forKey: lastResetKey)
        }
    }

    private func currentDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}
