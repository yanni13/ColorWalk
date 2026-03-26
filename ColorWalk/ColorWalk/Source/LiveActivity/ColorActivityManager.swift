//
//  ColorActivityManager.swift
//  ColorWalk
//

import ActivityKit
import UIKit

@available(iOS 16.1, *)
final class ColorActivityManager {

    static let shared = ColorActivityManager()
    private var currentActivity: Activity<ColorPickerAttributes>?
    private init() {}

    // MARK: - Start

    func start(missionName: String, missionHex: String, missionColor: UIColor, match: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        missionColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let attrs = ColorPickerAttributes(
            missionName: missionName,
            missionHex:  missionHex,
            red:         Double(r),
            green:       Double(g),
            blue:        Double(b)
        )
        let state = ColorPickerAttributes.ContentState(matchPercent: match)

        do {
            currentActivity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("[Dynamic Island] 시작 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    func update(match: Int) {
        guard let activity = currentActivity else { return }
        let state = ColorPickerAttributes.ContentState(matchPercent: match)
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    // MARK: - Stop

    func stop() {
        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
