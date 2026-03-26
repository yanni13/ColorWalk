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

    func start(missionName: String, missionHex: String, missionColor: UIColor, match: Int, incomplete: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attrs = ColorPickerAttributes(missionName: missionName, missionHex: missionHex)
        let state = ContentState(missionColor: missionColor, hex: missionHex, match: match, incomplete: incomplete)

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

    func update(missionColor: UIColor, hex: String, match: Int, incomplete: Int) {
        guard let activity = currentActivity else { return }
        let state = ContentState(missionColor: missionColor, hex: hex, match: match, incomplete: incomplete)
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    // MARK: - Stop

    func stop() {
        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    // MARK: - Helper

    private func ContentState(missionColor: UIColor, hex: String, match: Int, incomplete: Int) -> ColorPickerAttributes.ContentState {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        missionColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return ColorPickerAttributes.ContentState(
            missionHex: hex,
            matchPercent: match,
            incompleteCount: incomplete,
            red: Double(r), green: Double(g), blue: Double(b)
        )
    }
}
