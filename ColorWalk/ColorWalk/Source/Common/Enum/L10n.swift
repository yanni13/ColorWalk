import Foundation

enum L10n {

    // MARK: - Tab Bar

    static var tabHome: String { String(localized: "tab.home") }
    static var tabCamera: String { String(localized: "tab.camera") }
    static var tabCollection: String { String(localized: "tab.collection") }
    static var tabMap: String { String(localized: "tab.map") }

    // MARK: - Common Buttons

    static var buttonCancel: String { String(localized: "button.cancel") }
    static var buttonConfirm: String { String(localized: "button.confirm") }
    static var buttonDelete: String { String(localized: "button.delete") }
    static var buttonDeleteAction: String { String(localized: "button.deleteAction") }
    static var buttonSave: String { String(localized: "button.save") }
    static var buttonChange: String { String(localized: "button.change") }
    static var buttonShare: String { String(localized: "button.share") }
    static var buttonClose: String { String(localized: "button.close") }
    static var buttonOpenSettings: String { String(localized: "button.openSettings") }
    static var buttonDone: String { String(localized: "button.done") }
    static var buttonDeselectAll: String { String(localized: "button.deselectAll") }
    static var buttonApply: String { String(localized: "button.apply") }
    static var buttonRandomColor: String { String(localized: "button.randomColor") }
    static var buttonCustomInput: String { String(localized: "button.customInput") }

    // MARK: - Mission Status

    static var missionStatusComplete: String { String(localized: "mission.status.complete") }
    static var missionStatusIncomplete: String { String(localized: "mission.status.incomplete") }
    static var missionStatusInProgress: String { String(localized: "mission.status.inProgress") }

    static func missionCompleteStatus(total: Int) -> String {
        String(format: String(localized: "collection.mission.complete"), total, total)
    }
    static func missionIncompleteStatus(captured: Int, total: Int) -> String {
        String(format: String(localized: "collection.mission.incomplete"), captured, total)
    }

    // MARK: - Empty State

    static var emptyTitle: String { String(localized: "empty.title") }
    static var emptySubtitle: String { String(localized: "empty.subtitle") }

    // MARK: - Home

    static var homeTitle: String { String(localized: "home.title") }
    static var homeMidnightBanner: String { String(localized: "home.midnight.banner") }
    static var homeMissionSection: String { String(localized: "home.mission.section") }
    static var homeProgressSection: String { String(localized: "home.progress.section") }
    static var homeChangeMissionButton: String { String(localized: "home.changeMission.button") }
    static var homePlaceholder: String { String(localized: "home.placeholder") }
    static var homePhotosSection: String { String(localized: "home.photos.section") }

    static func homeProgressCount(captured: Int, total: Int) -> String {
        String(format: String(localized: "home.progress.count"), captured, total)
    }
    static func homePhotosCount(captured: Int, total: Int) -> String {
        String(format: String(localized: "home.photos.count"), captured, total)
    }

    // MARK: - Alerts

    static var alertSaveSuccessTitle: String { String(localized: "alert.save.success.title") }
    static var alertSaveSuccessMessage: String { String(localized: "alert.save.success.message") }
    static var alertSaveFailureTitle: String { String(localized: "alert.save.failure.title") }
    static var alertSaveFailureMessage: String { String(localized: "alert.save.failure.message") }
    static var alertSavePermissionTitle: String { String(localized: "alert.save.permission.title") }
    static var alertSavePermissionMessage: String { String(localized: "alert.save.permission.message") }
    static var alertMissionChangeTitle: String { String(localized: "alert.mission.change.title") }
    static var alertMissionChangeMessage: String { String(localized: "alert.mission.change.message") }
    static var alertPhotoDeleteTitle: String { String(localized: "alert.photo.delete.title") }
    static var alertPhotoDeleteMessage: String { String(localized: "alert.photo.delete.message") }
    static var alertEditNameTitle: String { String(localized: "alert.editName.title") }
    static var alertEditNameMessage: String { String(localized: "alert.editName.message") }
    static var textFieldMissionNamePlaceholder: String { String(localized: "textField.missionName.placeholder") }

    // MARK: - Collection

    static func collectionShareHint(count: Int) -> String {
        String(format: String(localized: "collection.share.hint"), count)
    }
    static var collectionMissionColor: String { String(localized: "collection.mission.color") }
    static var collectionShareTitle: String { String(localized: "collection.share.title") }
    static var collectionShareToast: String { String(localized: "collection.share.toast") }

    // MARK: - CollectionEdit

    static var collectionEditTitle: String { String(localized: "collectionEdit.title") }
    static var collectionEditInstruction: String { String(localized: "collectionEdit.instruction") }
    static var collectionEditSelectedPhotos: String { String(localized: "collectionEdit.selectedPhotos") }

    // MARK: - Camera

    static var cameraTitle: String { String(localized: "camera.title") }
    static var locationCurrent: String { String(localized: "location.current") }

    static func cameraMissionLabel(_ name: String) -> String {
        String(format: String(localized: "camera.mission.label"), name)
    }

    // MARK: - Camera Filters

    static var cameraFilterNormal: String { String(localized: "camera.filter.normal") }
    static var cameraFilterWarm: String { String(localized: "camera.filter.warm") }
    static var cameraFilterCool: String { String(localized: "camera.filter.cool") }
    static var cameraFilterVivid: String { String(localized: "camera.filter.vivid") }
    static var cameraFilterSoft: String { String(localized: "camera.filter.soft") }
    static var cameraFilterMono: String { String(localized: "camera.filter.mono") }

    // MARK: - Gallery

    static var galleryTitle: String { String(localized: "gallery.title") }
    static var galleryInstruction: String { String(localized: "gallery.instruction") }

    // MARK: - ColorPicker Sheet

    static var colorPickerTitle: String { String(localized: "colorPicker.title") }
    static var colorPickerCurrentColorLabel: String { String(localized: "colorPicker.currentColorLabel") }
    static var colorPickerPresetLabel: String { String(localized: "colorPicker.presetLabel") }
    static var colorPickerCustomInputLabel: String { String(localized: "colorPicker.customInputLabel") }
    static var colorPickerCustomColorName: String { String(localized: "colorPicker.customColorName") }

    // MARK: - Color Card

    static var colorCardCollected: String { String(localized: "colorCard.collected") }

    // MARK: - Preset Color Names

    static var colorPresetSky: String { String(localized: "color.preset.sky") }
    static var colorPresetCherryBlossom: String { String(localized: "color.preset.cherryBlossom") }
    static var colorPresetLavender: String { String(localized: "color.preset.lavender") }
    static var colorPresetSunset: String { String(localized: "color.preset.sunset") }
    static var colorPresetMint: String { String(localized: "color.preset.mint") }
    static var colorPresetCoral: String { String(localized: "color.preset.coral") }
    static var colorPresetOcean: String { String(localized: "color.preset.ocean") }
    static var colorPresetGrape: String { String(localized: "color.preset.grape") }

    // MARK: - ColorConfirm Sheet

    static var colorConfirmTitle: String { String(localized: "colorConfirm.title") }
    static var colorConfirmOldColorLabel: String { String(localized: "colorConfirm.oldColorLabel") }
    static var colorConfirmNewColorLabel: String { String(localized: "colorConfirm.newColorLabel") }
    static var colorConfirmDescription: String { String(localized: "colorConfirm.description") }

    // MARK: - Mission Weather

    static var missionWeatherNoInfo: String { String(localized: "mission.weather.noInfo") }
    static var missionWeatherLoading: String { String(localized: "mission.weather.loading") }
    static func missionWeatherInfoFormat(_ condition: String) -> String {
        String(format: String(localized: "mission.weather.infoFormat"), condition)
    }

    // MARK: - MissionDetail Sheet

    static var missionDetailWeatherTitle: String { String(localized: "missionDetail.weatherTitle") }

    static func missionDetailWeatherDetail(celsius: String, humidity: String) -> String {
        String(format: String(localized: "missionDetail.weatherDetail"), celsius, humidity)
    }

    // MARK: - Onboarding

    static var onboardingSubtitle: String { String(localized: "onboarding.subtitle") }
    static var onboardingEmptyTitle: String { String(localized: "onboarding.empty.title") }
    static var onboardingEmptyDesc: String { String(localized: "onboarding.empty.desc") }
    static var onboardingCTAButton: String { String(localized: "onboarding.cta.button") }

    // MARK: - Nearby Photos

    static var nearbyPhotosTitle: String { String(localized: "nearbyPhotos.title") }
    static var nearbyPhotosColorInfo: String { String(localized: "nearbyPhotos.colorInfo") }
    static var nearbyPhotosWeather: String { String(localized: "nearbyPhotos.weather") }
    static var nearbyPhotosNoAddress: String { String(localized: "nearbyPhotos.noAddress") }
    static var nearbyPhotosWeatherNow: String { String(localized: "nearbyPhotos.weatherNow") }
    static var nearbyPhotosTimeJustNow: String { String(localized: "nearbyPhotos.time.justNow") }

    static func nearbyPhotosSubtitle(_ count: Int) -> String {
        String(format: String(localized: "nearbyPhotos.subtitle"), count)
    }
    static func nearbyPhotosTimeMinutesAgo(_ minutes: Int) -> String {
        String(format: String(localized: "nearbyPhotos.time.minutesAgo"), minutes)
    }
    static func nearbyPhotosTimeHoursAgo(_ hours: Int) -> String {
        String(format: String(localized: "nearbyPhotos.time.hoursAgo"), hours)
    }
    static func nearbyPhotosTimeDaysAgo(_ days: Int) -> String {
        String(format: String(localized: "nearbyPhotos.time.daysAgo"), days)
    }
    static func nearbyPhotosMatchRate(_ rate: Int) -> String {
        String(format: String(localized: "nearbyPhotos.matchRate"), rate)
    }

    // MARK: - ColorDetail

    static var colorDetailShareText: String { String(localized: "colorDetail.shareText") }

    // MARK: - Accessibility

    static var accessibilityEditName: String { String(localized: "accessibility.editName") }
    static var accessibilityShuffleMission: String { String(localized: "accessibility.shuffleMission") }
    static var accessibilityMyLocation: String { String(localized: "accessibility.myLocation") }
    static var accessibilityClose: String { String(localized: "accessibility.close") }
    static var accessibilityPhoto: String { String(localized: "accessibility.photo") }
    static var accessibilityChangeLayout: String { String(localized: "accessibility.changeLayout") }

    // MARK: - Details Section

    static var detailsColorAccuracy: String { String(localized: "details.colorAccuracy") }
    static var detailsMissionProgress: String { String(localized: "details.missionProgress") }

    // MARK: - Notifications

    static var notificationTitle: String { String(localized: "notification.title") }
    static var notificationBody: String { String(localized: "notification.body") }
    static var notificationMissionName: String { String(localized: "notification.missionName") }

    // MARK: - Camera Match

    static func cameraMatch(_ match: Int) -> String {
        String(format: String(localized: "camera.match"), match)
    }
    static func cameraToastCollectSuccess(_ match: Int) -> String {
        String(format: String(localized: "camera.toast.collectSuccess"), match)
    }
    static func cameraToastCollectFail(_ match: Int) -> String {
        String(format: String(localized: "camera.toast.collectFail"), match)
    }

    // MARK: - ColorPalette Sheet

    static var colorPaletteTitle: String { String(localized: "colorPalette.title") }
    static var colorPaletteSelectedColor: String { String(localized: "colorPalette.selectedColor") }

    // MARK: - Gallery Popup

    static var galleryPopupMatchPerfect: String { String(localized: "gallery.popup.match.perfect") }
    static var galleryPopupMatchSimilar: String { String(localized: "gallery.popup.match.similar") }
    static var galleryPopupMatchDifferent: String { String(localized: "gallery.popup.match.different") }
    static var galleryPopupMatchVeryDifferent: String { String(localized: "gallery.popup.match.veryDifferent") }
    static var galleryPopupRetry: String { String(localized: "gallery.popup.retry") }
    static var galleryPopupCollect: String { String(localized: "gallery.popup.collect") }

    static func galleryPopupDescCanCollect(hex: String, match: Int) -> String {
        String(format: String(localized: "gallery.popup.desc.canCollect"), hex, match)
    }
    static func galleryPopupDescCannotCollect(hex: String, match: Int) -> String {
        String(format: String(localized: "gallery.popup.desc.cannotCollect"), hex, match)
    }

    // MARK: - Weather Conditions

    static var weatherClear: String { String(localized: "weather.clear") }
    static var weatherMostlyClear: String { String(localized: "weather.mostlyClear") }
    static var weatherPartlyCloudy: String { String(localized: "weather.partlyCloudy") }
    static var weatherMostlyCloudy: String { String(localized: "weather.mostlyCloudy") }
    static var weatherCloudy: String { String(localized: "weather.cloudy") }
    static var weatherFoggy: String { String(localized: "weather.foggy") }
    static var weatherHaze: String { String(localized: "weather.haze") }
    static var weatherSmoky: String { String(localized: "weather.smoky") }
    static var weatherBreezy: String { String(localized: "weather.breezy") }
    static var weatherWindy: String { String(localized: "weather.windy") }
    static var weatherBlowingDust: String { String(localized: "weather.blowingDust") }
    static var weatherDrizzle: String { String(localized: "weather.drizzle") }
    static var weatherRain: String { String(localized: "weather.rain") }
    static var weatherHeavyRain: String { String(localized: "weather.heavyRain") }
    static var weatherSunShowers: String { String(localized: "weather.sunShowers") }
    static var weatherIsolatedThunderstorms: String { String(localized: "weather.isolatedThunderstorms") }
    static var weatherScatteredThunderstorms: String { String(localized: "weather.scatteredThunderstorms") }
    static var weatherThunderstorms: String { String(localized: "weather.thunderstorms") }
    static var weatherStrongStorms: String { String(localized: "weather.strongStorms") }
    static var weatherSnow: String { String(localized: "weather.snow") }
    static var weatherHeavySnow: String { String(localized: "weather.heavySnow") }
    static var weatherFlurries: String { String(localized: "weather.flurries") }
    static var weatherSunFlurries: String { String(localized: "weather.sunFlurries") }
    static var weatherBlowingSnow: String { String(localized: "weather.blowingSnow") }
    static var weatherBlizzard: String { String(localized: "weather.blizzard") }
    static var weatherSleet: String { String(localized: "weather.sleet") }
    static var weatherHail: String { String(localized: "weather.hail") }
    static var weatherFreezingRain: String { String(localized: "weather.freezingRain") }
    static var weatherFreezingDrizzle: String { String(localized: "weather.freezingDrizzle") }
    static var weatherWintryMix: String { String(localized: "weather.wintryMix") }
    static var weatherHot: String { String(localized: "weather.hot") }
    static var weatherFrigid: String { String(localized: "weather.frigid") }
    static var weatherHurricane: String { String(localized: "weather.hurricane") }
    static var weatherTropicalStorm: String { String(localized: "weather.tropicalStorm") }
    static var weatherDefault: String { String(localized: "weather.default") }

    // MARK: - Mission Color Names

    static var missionColorYellow: String { String(localized: "mission.color.yellow") }
    static var missionColorSky: String { String(localized: "mission.color.sky") }
    static var missionColorOrange: String { String(localized: "mission.color.orange") }
    static var missionColorPink: String { String(localized: "mission.color.pink") }
    static var missionColorGray: String { String(localized: "mission.color.gray") }
    static var missionColorBlue: String { String(localized: "mission.color.blue") }
    static var missionColorSlate: String { String(localized: "mission.color.slate") }
    static var missionColorLightGray: String { String(localized: "mission.color.lightGray") }
    static var missionColorGreen: String { String(localized: "mission.color.green") }
    static var missionColorDarkGreen: String { String(localized: "mission.color.darkGreen") }
    static var missionColorNavy: String { String(localized: "mission.color.navy") }
    static var missionColorPurple: String { String(localized: "mission.color.purple") }
    static var missionColorRed: String { String(localized: "mission.color.red") }
    static var missionColorIndigo: String { String(localized: "mission.color.indigo") }
    static var missionColorBlueGray: String { String(localized: "mission.color.blueGray") }
    static var missionColorDefault: String { String(localized: "mission.color.default") }

    // MARK: - Mission Theme Prefixes

    static var missionThemeSunFull: String { String(localized: "mission.theme.sunFull") }
    static var missionThemeGolden: String { String(localized: "mission.theme.golden") }
    static var missionThemeClearOf: String { String(localized: "mission.theme.clearOf") }
    static var missionThemeBlueSky: String { String(localized: "mission.theme.blueSky") }
    static var missionThemeClearLake: String { String(localized: "mission.theme.clearLake") }
    static var missionThemeCool: String { String(localized: "mission.theme.cool") }
    static var missionThemeRefreshing: String { String(localized: "mission.theme.refreshing") }
    static var missionThemeAfternoon: String { String(localized: "mission.theme.afternoon") }
    static var missionThemeShining: String { String(localized: "mission.theme.shining") }
    static var missionThemeCherryBlossom: String { String(localized: "mission.theme.cherryBlossom") }
    static var missionThemeShy: String { String(localized: "mission.theme.shy") }
    static var missionThemeVivid: String { String(localized: "mission.theme.vivid") }
    static var missionThemeCanola: String { String(localized: "mission.theme.canola") }
    static var missionThemeBright: String { String(localized: "mission.theme.bright") }
    static var missionThemeYellow: String { String(localized: "mission.theme.yellow") }
    static var missionThemeFoggy: String { String(localized: "mission.theme.foggy") }
    static var missionThemeCalm: String { String(localized: "mission.theme.calm") }
    static var missionThemeSlate: String { String(localized: "mission.theme.slate") }
    static var missionThemeThroughClouds: String { String(localized: "mission.theme.throughClouds") }
    static var missionThemeLight: String { String(localized: "mission.theme.light") }
    static var missionThemeFaint: String { String(localized: "mission.theme.faint") }
    static var missionThemeCityForest: String { String(localized: "mission.theme.cityForest") }
    static var missionThemeMonochrome: String { String(localized: "mission.theme.monochrome") }
    static var missionThemeStatic: String { String(localized: "mission.theme.static") }
    static var missionThemeDeep: String { String(localized: "mission.theme.deep") }
    static var missionThemeHeavy: String { String(localized: "mission.theme.heavy") }
    static var missionThemeCloudySky: String { String(localized: "mission.theme.cloudy") }
    static var missionThemeClean: String { String(localized: "mission.theme.clean") }
    static var missionThemeSoft: String { String(localized: "mission.theme.soft") }
    static var missionThemeAfterRain: String { String(localized: "mission.theme.afterRain") }
    static var missionThemeLively: String { String(localized: "mission.theme.lively") }
    static var missionThemeForest: String { String(localized: "mission.theme.forest") }
    static var missionThemeRainSoaked: String { String(localized: "mission.theme.rainSoaked") }
    static var missionThemeSteel: String { String(localized: "mission.theme.steel") }
    static var missionThemeMoist: String { String(localized: "mission.theme.moist") }
    static var missionThemeGrassScent: String { String(localized: "mission.theme.grassScent") }
    static var missionThemeGreenTone: String { String(localized: "mission.theme.greenTone") }
    static var missionThemeFresh: String { String(localized: "mission.theme.fresh") }
    static var missionThemeDeepMountain: String { String(localized: "mission.theme.deepMountain") }
    static var missionThemeForestOf: String { String(localized: "mission.theme.forestOf") }
    static var missionThemeDark: String { String(localized: "mission.theme.dark") }
    static var missionThemeMidnight: String { String(localized: "mission.theme.midnight") }
    static var missionThemeAbyss: String { String(localized: "mission.theme.abyss") }
    static var missionThemeDeepNight: String { String(localized: "mission.theme.deepNight") }
    static var missionThemeBeforeStorm: String { String(localized: "mission.theme.beforeStorm") }
    static var missionThemeIntense: String { String(localized: "mission.theme.intense") }
    static var missionThemeMysterious: String { String(localized: "mission.theme.mysterious") }
    static var missionThemeHeat: String { String(localized: "mission.theme.heat") }
    static var missionThemeBlazing: String { String(localized: "mission.theme.blazing") }
    static var missionThemeHeavyFeel: String { String(localized: "mission.theme.heavyFeel") }
    static var missionThemeLightningFlash: String { String(localized: "mission.theme.lightningFlash") }
    static var missionThemeIndigo: String { String(localized: "mission.theme.indigo") }
    static var missionThemePassion: String { String(localized: "mission.theme.passion") }
    static var missionThemeWarning: String { String(localized: "mission.theme.warning") }
    static var missionThemeGaleWind: String { String(localized: "mission.theme.galeWind") }
    static var missionThemeCold: String { String(localized: "mission.theme.cold") }
    static var missionThemeDawn: String { String(localized: "mission.theme.dawn") }
    static var missionThemeNight: String { String(localized: "mission.theme.night") }
    static var missionThemeSunset: String { String(localized: "mission.theme.sunset") }
}
