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

    func start(missionName: String, missionHex: String, color: UIColor, hex: String, match: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attrs = ColorPickerAttributes(missionName: missionName, missionHex: missionHex)
        let state = ContentState(color: color, hex: hex, match: match)

        do {
            currentActivity = try Activity.request(
                attributes: attrs,
                contentState: state,
                pushType: nil
            )
        } catch {
            print("[Dynamic Island] 시작 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    func update(color: UIColor, hex: String, match: Int) {
        guard let activity = currentActivity else { return }
        let state = ContentState(color: color, hex: hex, match: match)
        Task { await activity.update(using: state) }
    }

    // MARK: - Stop

    func stop() {
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    // MARK: - Helper

    private func ContentState(color: UIColor, hex: String, match: Int) -> ColorPickerAttributes.ContentState {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return ColorPickerAttributes.ContentState(
            detectedHex: hex,
            matchPercent: match,
            red: Double(r), green: Double(g), blue: Double(b)
        )
    }
}
