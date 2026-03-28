//
//  WeatherKitService.swift
//  ColorWalk
//

import Foundation
import WeatherKit
import CoreLocation
import RxSwift

// MARK: - Protocol

protocol WeatherServiceProtocol {
    func fetchWeatherInfo(for location: CLLocation) -> Single<String>
}

// MARK: - Implementation

final class WeatherKitService: WeatherServiceProtocol {

    func fetchWeatherInfo(for location: CLLocation) -> Single<String> {
        Single.create { single in
            let task = Task {
                do {
                    let weather = try await WeatherService.shared.weather(for: location)
                    let current = weather.currentWeather
                    let celsius = String(format: "%.0f°C", current.temperature.converted(to: .celsius).value)
                    let conditionText = current.condition.koreanDescription
                    single(.success("\(conditionText) · \(celsius)"))
                } catch {
                    single(.success("날씨 정보 없음"))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }
}

// MARK: - WeatherCondition Korean

private extension WeatherCondition {
    var koreanDescription: String {
        switch self {
        case .clear:                    return "맑음"
        case .mostlyClear:              return "대체로 맑음"
        case .partlyCloudy:             return "구름 조금"
        case .mostlyCloudy:             return "대체로 흐림"
        case .cloudy:                   return "흐림"
        case .foggy:                    return "안개"
        case .haze:                     return "연무"
        case .smoky:                    return "연기"
        case .breezy:                   return "산들바람"
        case .windy:                    return "강풍"
        case .blowingDust:              return "황사"
        case .drizzle:                  return "이슬비"
        case .rain:                     return "비"
        case .heavyRain:                return "폭우"
        case .sunShowers:               return "맑다가 소나기"
        case .isolatedThunderstorms:    return "드문 뇌우"
        case .scatteredThunderstorms:   return "돌발 뇌우"
        case .thunderstorms:            return "뇌우"
        case .strongStorms:             return "강한 뇌우"
        case .snow:                     return "눈"
        case .heavySnow:                return "폭설"
        case .flurries:                 return "가벼운 눈"
        case .sunFlurries:              return "맑다가 눈"
        case .blowingSnow:              return "날리는 눈"
        case .blizzard:                 return "눈폭풍"
        case .sleet:                    return "진눈깨비"
        case .hail:                     return "우박"
        case .freezingRain:             return "어는 비"
        case .freezingDrizzle:          return "어는 이슬비"
        case .wintryMix:                return "겨울 혼합"
        case .hot:                      return "매우 더움"
        case .frigid:                   return "매우 추움"
        case .hurricane:                return "허리케인"
        case .tropicalStorm:            return "열대 폭풍"
        default:                        return "날씨 정보"
        }
    }
}
