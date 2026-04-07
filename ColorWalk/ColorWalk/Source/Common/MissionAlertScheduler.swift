import UserNotifications

final class MissionAlertScheduler {

    // MARK: - Properties

    static let shared = MissionAlertScheduler()

    private enum Constants {
        static let identifierPrefix  = "colorwalk.mission.alert"
        static let alertHourRange    = 9...11
        static let scheduleDaysAhead = 14
    }

    private init() {}

    // MARK: - Public

    func reschedule() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let pendingIds = Set(pending.map { $0.identifier })
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            for dayOffset in 0..<Constants.scheduleDaysAhead {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let dateStr = DateManager.storedString(from: date)
                let id = "\(Constants.identifierPrefix).\(dateStr)"
                if !pendingIds.contains(id) {
                    self.scheduleAlert(for: date, identifier: id)
                }
            }
        }
    }

    func scheduleImmediateTest(after delay: TimeInterval = 5) {
        let mission = RealmManager.shared.fetchOrCreateTodayMission()
        let missionHex = mission.recommendedHex.isEmpty ? "" : mission.recommendedHex

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
        UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
            let ids = pending
                .map { $0.identifier }
                .filter { $0.hasPrefix(Constants.identifierPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Private

    private func scheduleAlert(for date: Date, identifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let randomHour   = Int.random(in: Constants.alertHourRange)
            let randomMinute = Int.random(in: 0...59)

            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour   = randomHour
            components.minute = randomMinute

            guard let fireDate = calendar.date(from: components),
                  fireDate > Date() else { return }

            let mission    = RealmManager.shared.fetchOrCreateTodayMission()
            let missionHex = mission.recommendedHex.isEmpty ? "#5B8DEF" : mission.recommendedHex

            let content = self.makeContent(missionHex: missionHex)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("[MissionAlertScheduler] 등록 실패 (\(identifier)): \(error.localizedDescription)")
                }
            }
        }
    }

    private func makeContent(missionHex: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = L10n.notificationTitle
        content.body  = L10n.notificationBody
        content.sound = .default
        content.userInfo = [
            AppConstants.Notification.missionHexKey:  missionHex,
            AppConstants.Notification.missionNameKey: L10n.notificationMissionName
        ]
        return content
    }

}
