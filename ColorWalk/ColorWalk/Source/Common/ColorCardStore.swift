//
//  ColorCardStore.swift
//  ColorWalk
//

import RxCocoa

final class ColorCardStore {
    static let shared = ColorCardStore()
    private init() {}

    let cards = BehaviorRelay<[ColorCard]>(value: [])

    func add(_ card: ColorCard) {
        var current = cards.value
        current.insert(card, at: 0)
        cards.accept(current)
    }
}
