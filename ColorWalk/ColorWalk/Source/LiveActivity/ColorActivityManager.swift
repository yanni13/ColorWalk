//
//  ColorActivityManager.swift
//  ColorWalk

import ActivityKit
import UIKit

@available(iOS 16.1, *)
final class ColorActivityManager {

    // MARK: - Properties

    static let shared = ColorActivityManager()
    private var currentActivity: Activity<ColorPickerAttributes>?
    private var sessionTimerEnd: Date?
    private(set) var isTimedSessionActive: Bool = false

    private init() {}

    // MARK: - Start (카메라 수동 사용 - 타이머 없음)

    func start(missionName: String, missionHex: String, missionColor: UIColor, match: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard !isTimedSessionActive else { return }

        sessionTimerEnd = nil
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        missionColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let attrs = ColorPickerAttributes(
            missionName: missionName,
            missionHex:  missionHex,
            red:         Double(r),
            green:       Double(g),
            blue:        Double(b)
        )
        let state = ColorPickerAttributes.ContentState(matchPercent: match, timerEnd: nil, isExpired: false)

        do {
            currentActivity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("[Dynamic Island] 활성화 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Start Timed (알림 트리거 - 3분 카운트다운)

    func startTimedSession(missionName: String, missionHex: String, missionColor: UIColor, duration: TimeInterval = 180) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        stop()

        let timerEnd = Date().addingTimeInterval(duration)
        sessionTimerEnd = timerEnd
        isTimedSessionActive = true

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        missionColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let attrs = ColorPickerAttributes(
            missionName: missionName,
            missionHex:  missionHex,
            red:         Double(r),
            green:       Double(g),
            blue:        Double(b)
        )
        let state = ColorPickerAttributes.ContentState(matchPercent: 0, timerEnd: timerEnd, isExpired: false)

        do {
            currentActivity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: timerEnd),
                pushType: nil
            )
        } catch {
            print("[Dynamic Island] 시간 제한 미션 시작 실패: \(error.localizedDescription)")
            return
        }

        scheduleExpiry(after: duration)
    }

    // MARK: - Update

    func update(match: Int) {
        guard let activity = currentActivity else { return }
        
        let isExpired = sessionTimerEnd != nil && Date() >= sessionTimerEnd!
        let state = ColorPickerAttributes.ContentState(matchPercent: match, timerEnd: sessionTimerEnd, isExpired: isExpired)
        
        Task { await activity.update(.init(state: state, staleDate: sessionTimerEnd)) }
    }

    // MARK: - Stop

    func stop() {
        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            sessionTimerEnd = nil
            isTimedSessionActive = false
        }
    }

    // MARK: - Private

    private func scheduleExpiry(after duration: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self else { return }
            self.stop()
        }
    }
}
