import UserNotifications

final class MissionAlertScheduler {

    // MARK: - Properties

    static let shared = MissionAlertScheduler()

    private enum Constants {
        static let identifierPrefix = "colorwalk.mission.alert"
        static let morningHourRange = 8...10
        static let eveningHourRange = 18...20
        static let scheduleDaysAhead = 14
    }

    private enum Session: String {
        case morning, evening
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

                let morningId = "\(Constants.identifierPrefix).\(Session.morning.rawValue).\(dateStr)"
                if !pendingIds.contains(morningId) {
                    self.scheduleRandomAlert(for: date, hourRange: Constants.morningHourRange, identifier: morningId)
                }

                let eveningId = "\(Constants.identifierPrefix).\(Session.evening.rawValue).\(dateStr)"
                if !pendingIds.contains(eveningId) {
                    self.scheduleRandomAlert(for: date, hourRange: Constants.eveningHourRange, identifier: eveningId)
                }
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
        UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
            let ids = pending
                .map { $0.identifier }
                .filter { $0.hasPrefix(Constants.identifierPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Private

    private func scheduleRandomAlert(for date: Date, hourRange: ClosedRange<Int>, identifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let randomHour = Int.random(in: hourRange)
            let randomMinute = Int.random(in: 0...59)

            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = randomHour
            components.minute = randomMinute

            guard let fireDate = calendar.date(from: components),
                  fireDate > Date() else { return }

            let mission = RealmManager.shared.fetchOrCreateTodayMission()
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
