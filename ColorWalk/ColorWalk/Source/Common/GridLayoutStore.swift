//
//  GridLayoutStore.swift
//  ColorWalk
//

import Foundation
import RxSwift
import RxCocoa

final class GridLayoutStore {
    static let shared = GridLayoutStore()
    
    let selectedLayout = BehaviorRelay<GridLayoutType>(value: .threeByThree)
    private let disposeBag = DisposeBag()
    
    private init() {
        loadFromUserDefaults()
    }
    
    func updateLayout(_ layout: GridLayoutType) {
        UserDefaults.standard.set(layout.rawValue, forKey: AppConstants.UserDefaultsKey.gridLayout)
        selectedLayout.accept(layout)
    }
    
    private func loadFromUserDefaults() {
        if let raw = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKey.gridLayout),
           let saved = GridLayoutType(rawValue: raw) {
            selectedLayout.accept(saved)
        }
    }
}
