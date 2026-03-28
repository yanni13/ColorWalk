import UserNotifications

final class MissionAlertScheduler {

    // MARK: - Properties

    static let shared = MissionAlertScheduler()

    private enum Constants {
        static let identifierPrefix = "colorwalk.mission.alert"
        static let alertHours: [Int] = [9, 13, 19]
    }

    private init() {}

    // MARK: - Public

    func reschedule() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let pendingIds = Set(pending.map { $0.identifier })
            for hour in Constants.alertHours {
                let id = "\(Constants.identifierPrefix).\(hour)"
                guard !pendingIds.contains(id) else { continue }
                self.scheduleAlert(hour: hour, identifier: id)
            }
        }
    }

    func scheduleImmediateTest(after delay: TimeInterval = 5) {
        let mission = RealmManager.shared.fetchOrCreateTodayMission()
        let missionHex = mission.recommendedHex.isEmpty ? "#5B8DEF" : mission.recommendedHex

        let content = makeContent(missionHex: missionHex)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let id = "colorwalk.mission.test.\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[MissionAlertScheduler] 테스트 알림 등록 실패: \(error.localizedDescription)")
            }
        }
    }

    func cancelAll() {
        let ids = Constants.alertHours.map { "\(Constants.identifierPrefix).\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private

    private func scheduleAlert(hour: Int, identifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let mission = RealmManager.shared.fetchOrCreateTodayMission()
            let missionHex = mission.recommendedHex.isEmpty ? "#5B8DEF" : mission.recommendedHex

            let content = self.makeContent(missionHex: missionHex)
            var components = DateComponents()
            components.hour = hour
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("[MissionAlertScheduler] 등록 실패 (hour:\(hour)): \(error.localizedDescription)")
                }
            }
        }
    }

    private func makeContent(missionHex: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ 지금 색상을 찾아라! ⚠️"
        content.body = "목표 색상 \(missionHex) — 3분 안에 찾아봐요"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            AppConstants.Notification.missionHexKey: missionHex,
            AppConstants.Notification.missionNameKey: "오늘의 색상 미션"
        ]
        return content
    }
}
