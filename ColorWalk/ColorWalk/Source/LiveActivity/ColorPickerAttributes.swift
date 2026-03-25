//
//  ColorPickerAttributes.swift
//  ColorWalk
//


import ActivityKit
import Foundation

struct ColorPickerAttributes: ActivityAttributes {

    // 세션 동안 변하지 않는 정보
    var missionName: String
    var missionHex:  String

    // 매 프레임마다 업데이트되는 정보
    struct ContentState: Codable, Hashable {
        var detectedHex:  String
        var matchPercent: Int
        var red:   Double
        var green: Double
        var blue:  Double
    }
}
