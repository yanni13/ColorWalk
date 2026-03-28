import Foundation

enum AppConstants {

    enum DateFormat {
        static let stored = "yyyy-MM-dd"
        static let displayShort = "M월 d일"
        static let displayFull = "M월 d일 EEEE"
        static let displayShare = "yyyy. MM. dd"
    }

    enum Text {
        static let missionComplete = "완성"
        static let missionIncomplete = "미완성"
        static let noMissionTitle = "텅~"
        static let noMissionSubtitle = "이 날은 산책을 하지 않았어요."
        static let inProgressMessage = "아쉬워요 😢  미션을 완성하지 못했어요."
        static let shareButtonTitle = "공유하기"
    }
}
