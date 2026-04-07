import Foundation

enum AppConstants {

    enum Notification {
        static let missionHexKey = "missionHex"
        static let missionNameKey = "missionName"
    }


    enum DateFormat {
        static let stored = "yyyy-MM-dd"
        static let displayShort = "M월 d일"
        static let displayFull = "M월 d일 EEEE"
        static let displayShare = "yyyy. MM. dd"
    }

    enum Text {
        static var missionComplete: String { L10n.missionStatusComplete }
        static var missionIncomplete: String { L10n.missionStatusIncomplete }
        static var noMissionTitle: String { L10n.emptyTitle }
        static var noMissionSubtitle: String { L10n.emptySubtitle }
        static var inProgressMessage: String { L10n.missionStatusInProgress }
        static var shareButtonTitle: String { L10n.buttonShare }
    }
}
