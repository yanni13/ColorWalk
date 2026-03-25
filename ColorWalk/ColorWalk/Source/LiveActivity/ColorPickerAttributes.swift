//
//  ColorPickerAttributes.swift
//  ColorWalk
//
//  ⚠️ Xcode 설정 필요:
//  1. File > New > Target > Widget Extension 추가 (예: "ColorWalkWidget")
//  2. 이 파일을 두 타겟(ColorWalk + ColorWalkWidget)에 모두 포함
//  3. Info.plist에 NSSupportsLiveActivities = YES 추가
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
