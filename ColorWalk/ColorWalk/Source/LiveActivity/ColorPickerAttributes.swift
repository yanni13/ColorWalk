//
//  ColorPickerAttributes.swift
//  ColorWalk
//


import ActivityKit
import Foundation

struct ColorPickerAttributes: ActivityAttributes {

    // 세션 동안 변하지 않는 정보 (미션 정보)
    var missionName: String
    var missionHex:  String
    var red:   Double
    var green: Double
    var blue:  Double

    // 매 프레임마다 업데이트되는 정보 (실시간 일치율)
    struct ContentState: Codable, Hashable {
        var matchPercent: Int
    }
}
