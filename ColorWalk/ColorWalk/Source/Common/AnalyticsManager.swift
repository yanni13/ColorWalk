//
//  AnalyticsManager.swift
//  ColorWalk

import Foundation
import FirebaseAnalytics

final class AnalyticsManager {

    static let shared = AnalyticsManager()
    private init() {}

    // MARK: - Photo

    func logPhotoCaptured(matchPercent: Int, filter: String, isSuccess: Bool) {
        Analytics.logEvent(AppConstants.Analytics.Event.photoCaptured, parameters: [
            AppConstants.Analytics.Param.matchPercent: matchPercent,
            AppConstants.Analytics.Param.filterUsed: filter,
            AppConstants.Analytics.Param.isSuccess: isSuccess
        ])
    }

    func logGalleryImageUsed() {
        Analytics.logEvent(AppConstants.Analytics.Event.galleryImageUsed, parameters: nil)
    }

    // MARK: - Mission

    func logMissionShuffled() {
        Analytics.logEvent(AppConstants.Analytics.Event.missionShuffled, parameters: nil)
    }

    func logMissionColorChanged(hexColor: String, colorName: String) {
        Analytics.logEvent(AppConstants.Analytics.Event.missionColorChanged, parameters: [
            AppConstants.Analytics.Param.hexColor: hexColor,
            AppConstants.Analytics.Param.colorName: colorName
        ])
    }

    // MARK: - Collection

    func logCollectionShared() {
        Analytics.logEvent(AppConstants.Analytics.Event.collectionShared, parameters: nil)
    }

    // MARK: - Onboarding

    func logOnboardingCtaTapped() {
        Analytics.logEvent(AppConstants.Analytics.Event.onboardingCtaTapped, parameters: nil)
    }
}
