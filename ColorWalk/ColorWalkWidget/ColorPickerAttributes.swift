//
//  ColorPickerAttributes.swift
//  ColorWalkWidget
//
//  Widget Extension 타겟 전용 정의.
//  주 앱의 Source/LiveActivity/ColorPickerAttributes.swift 와 동일한 구조여야
//  ActivityKit 이 Codable 직렬화로 두 타겟을 연결할 수 있습니다.
//

import ActivityKit
import Foundation

struct ColorPickerAttributes: ActivityAttributes {

    // 세션 동안 고정되는 값
    var missionName: String
    var missionHex:  String

    // 매 프레임마다 업데이트
    struct ContentState: Codable, Hashable {
        var detectedHex:  String
        var matchPercent: Int
        var red:   Double
        var green: Double
        var blue:  Double
    }
}
