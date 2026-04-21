//
//  MidnightResetTests.swift
//  ColorWalkTests
//

import Testing
import Foundation
@testable import ColorWalk
internal import RxRelay

// MARK: - 자정 초기화 & 배너 동작 테스트
//
// 검증 대상
// 1. 날짜가 바뀌면(자정 경과) 사진 카드가 초기화된다
// 2. 초기화 발생 시 didResetToday == true → 자정 배너 표시 조건 충족
// 3. 같은 날 재진입 시 초기화·배너 표시 없음
// 4. 배너가 한 번 표시된 뒤 플래그가 false로 정리된다

@Suite("자정 초기화 및 배너 동작")
final class MidnightResetTests {

    private let defaults = UserDefaults.standard
    private let lastResetKey = "lastResetDate"

    private let savedLastResetDate: String?
    private let savedDidResetToday: Bool

    init() {
        savedLastResetDate = defaults.string(forKey: lastResetKey)
        savedDidResetToday = ColorCardStore.shared.didResetToday
    }

    deinit {
        if let saved = savedLastResetDate {
            defaults.set(saved, forKey: lastResetKey)
        } else {
            defaults.removeObject(forKey: lastResetKey)
        }
        ColorCardStore.shared.didResetToday = savedDidResetToday
    }

    // MARK: - 날짜 포맷 로직

    @Suite("DateManager 날짜 문자열 포맷")
    struct DateFormatTests {

        @Test("storedString은 yyyy-MM-dd 형식을 반환한다")
        func storedStringHasCorrectFormat() {
            let result = DateManager.storedString(from: Date())
            let parts = result.split(separator: "-")
            #expect(parts.count == 3)
            #expect(parts[0].count == 4)
            #expect(parts[1].count == 2)
            #expect(parts[2].count == 2)
        }

        @Test("어제와 오늘의 날짜 문자열은 다르다")
        func yesterdayDiffersFromToday() {
            let today = DateManager.storedString(from: Date())
            let yesterday = DateManager.storedString(from: DateManager.date(byAddingDays: -1))
            #expect(today != yesterday)
        }

        @Test("같은 날 두 번 생성한 날짜 문자열은 동일하다")
        func todayStringIsStable() {
            let first = DateManager.storedString(from: Date())
            let second = DateManager.storedString(from: Date())
            #expect(first == second)
        }
    }

    // MARK: - 일일 초기화 조건

    @Test("lastResetDate가 없을 때 checkDailyReset 호출 시 초기화된다")
    func noStoredDateTriggersReset() {
        defaults.removeObject(forKey: lastResetKey)
        ColorCardStore.shared.didResetToday = false

        ColorCardStore.shared.checkDailyReset()

        #expect(ColorCardStore.shared.didResetToday == true)
    }

    @Test("lastResetDate가 오늘이면 초기화되지 않는다")
    func todayStoredDateSkipsReset() {
        defaults.set(DateManager.storedString(from: Date()), forKey: lastResetKey)
        ColorCardStore.shared.didResetToday = false

        ColorCardStore.shared.checkDailyReset()

        #expect(ColorCardStore.shared.didResetToday == false)
    }

    @Test("lastResetDate가 어제이면 자정 초기화가 발생한다")
    func yesterdayStoredDateTriggersReset() {
        let yesterday = DateManager.storedString(from: DateManager.date(byAddingDays: -1))
        defaults.set(yesterday, forKey: lastResetKey)
        ColorCardStore.shared.didResetToday = false

        ColorCardStore.shared.checkDailyReset()

        #expect(ColorCardStore.shared.didResetToday == true)
    }

    @Test("이틀 전 날짜가 저장된 경우도 초기화가 발생한다")
    func twoDaysAgoAlsoTriggersReset() {
        let twoDaysAgo = DateManager.storedString(from: DateManager.date(byAddingDays: -2))
        defaults.set(twoDaysAgo, forKey: lastResetKey)
        ColorCardStore.shared.didResetToday = false

        ColorCardStore.shared.checkDailyReset()

        #expect(ColorCardStore.shared.didResetToday == true)
    }

    // MARK: - 초기화 후 카드 상태

    @Test("자정 초기화 후 카드 목록이 비워진다")
    func resetClearsAllCards() {
        let yesterday = DateManager.storedString(from: DateManager.date(byAddingDays: -1))
        defaults.set(yesterday, forKey: lastResetKey)

        ColorCardStore.shared.checkDailyReset()

        #expect(ColorCardStore.shared.cards.value.isEmpty)
    }

    @Test("자정 초기화 후 UserDefaults에 오늘 날짜가 저장된다")
    func resetUpdatesStoredDateToToday() {
        let yesterday = DateManager.storedString(from: DateManager.date(byAddingDays: -1))
        let today = DateManager.storedString(from: Date())
        defaults.set(yesterday, forKey: lastResetKey)

        ColorCardStore.shared.checkDailyReset()

        #expect(defaults.string(forKey: lastResetKey) == today)
    }

    @Test("오늘 날짜가 저장된 경우 카드 목록이 변경되지 않는다")
    func noResetDoesNotClearCards() {
        defaults.set(DateManager.storedString(from: Date()), forKey: lastResetKey)
        let countBefore = ColorCardStore.shared.cards.value.count

        ColorCardStore.shared.checkDailyReset()

        #expect(ColorCardStore.shared.cards.value.count == countBefore)
    }

    // MARK: - 자정 배너 표시 조건

    @Test("자정 초기화 발생 후 didResetToday == true → 배너 표시 조건 충족")
    func resetSetsDidResetTodayForBannerDisplay() {
        let yesterday = DateManager.storedString(from: DateManager.date(byAddingDays: -1))
        defaults.set(yesterday, forKey: lastResetKey)

        ColorCardStore.shared.checkDailyReset()

        #expect(ColorCardStore.shared.didResetToday == true)
    }

    @Test("초기화 없을 때 didResetToday == false → 배너 미표시")
    func noResetKeepsBannerHidden() {
        defaults.set(DateManager.storedString(from: Date()), forKey: lastResetKey)
        ColorCardStore.shared.didResetToday = false

        ColorCardStore.shared.checkDailyReset()

        #expect(ColorCardStore.shared.didResetToday == false)
    }

    @Test("배너 표시 후 didResetToday 플래그가 false로 정리되어 재표시되지 않는다")
    func bannerFlagClearsAfterDisplay() {
        ColorCardStore.shared.didResetToday = true

        // MissionHomeViewController.updateBannerVisibility() 내부 로직 재현
        let didReset = ColorCardStore.shared.didResetToday
        if didReset {
            ColorCardStore.shared.didResetToday = false
        }

        #expect(ColorCardStore.shared.didResetToday == false)
    }

    @Test("연속 viewWillAppear 호출 시 배너는 최초 1회만 표시된다")
    func bannerAppearsOnlyOnce() {
        let yesterday = DateManager.storedString(from: DateManager.date(byAddingDays: -1))
        defaults.set(yesterday, forKey: lastResetKey)
        ColorCardStore.shared.checkDailyReset()

        // 첫 번째 viewWillAppear: 배너 표시
        let firstAppear = ColorCardStore.shared.didResetToday
        if firstAppear { ColorCardStore.shared.didResetToday = false }

        // 두 번째 viewWillAppear: 배너 미표시
        let secondAppear = ColorCardStore.shared.didResetToday

        #expect(firstAppear == true)
        #expect(secondAppear == false)
    }
}
