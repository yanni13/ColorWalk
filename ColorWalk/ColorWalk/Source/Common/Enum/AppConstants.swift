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
        static let widgetDisplayShort = "M/d"
    }

    enum Analytics {
        enum Event {
            static let photoCaptured = "photo_captured"
            static let galleryImageUsed = "gallery_image_used"
            static let missionShuffled = "mission_shuffled"
            static let missionColorChanged = "mission_color_changed"
            static let collectionShared = "collection_shared"
            static let onboardingCtaTapped = "onboarding_cta_tapped"
        }

        enum Param {
            static let matchPercent = "match_percent"
            static let filterUsed = "filter_used"
            static let isSuccess = "is_success"
            static let hexColor = "hex_color"
            static let colorName = "color_name"
        }
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
