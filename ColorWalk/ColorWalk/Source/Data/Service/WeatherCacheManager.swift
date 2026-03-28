import Foundation
import WeatherKit
import CoreLocation

// MARK: - WeatherData

struct WeatherData {
    let displayText: String
    let symbolName: String
    let celsius: String
    let humidity: String
}

// MARK: - WeatherCacheManager

final class WeatherCacheManager: @unchecked Sendable {

    static let shared = WeatherCacheManager()

    private enum Constants {
        static let cacheTTLSeconds: TimeInterval = 10800  // 3시간
        static let coordinatePrecision: Double = 100      // 소수점 2자리 ≈ 1.1km
    }

    private struct CacheEntry {
        let data: WeatherData
        let timestamp: Date

        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < Constants.cacheTTLSeconds
        }
    }

    private var cache: [String: CacheEntry] = [:]
    private let queue = DispatchQueue(label: "com.colorwalk.weathercache")

    private init() {}

    func fetch(for location: CLLocation) async throws -> WeatherData {
        let key = cacheKey(for: location)

        if let entry = queue.sync(execute: { cache[key] }), entry.isValid {
            let age = Int(Date().timeIntervalSince(entry.timestamp) / 60)
            print("[WeatherCache] ✅ HIT  key=\(key)  age=\(age)분  \(entry.data.displayText)")
            return entry.data
        }

        print("[WeatherCache] 🌐 API CALL  key=\(key)")
        let weather = try await WeatherService.shared.weather(for: location)
        let current = weather.currentWeather
        let celsius = String(format: "%.0f°C", current.temperature.converted(to: .celsius).value)
        let data = WeatherData(
            displayText: "\(current.condition.koreanDescription) · \(celsius)",
            symbolName: current.symbolName,
            celsius: celsius,
            humidity: "\(Int(current.humidity * 100))%"
        )

        queue.async { [weak self] in
            guard let self else { return }
            cache[key] = CacheEntry(data: data, timestamp: Date())
            purgeExpiredEntries()
            print("[WeatherCache] 💾 STORED  key=\(key)  총 캐시 수=\(cache.count)")
        }

        return data
    }

    private func purgeExpiredEntries() {
        let before = cache.count
        cache = cache.filter { $0.value.isValid }
        let removed = before - cache.count
        if removed > 0 {
            print("[WeatherCache] 🗑️ PURGE  만료 제거=\(removed)  남은 캐시=\(cache.count)")
        }
    }

    private func cacheKey(for location: CLLocation) -> String {
        let lat = (location.coordinate.latitude * Constants.coordinatePrecision).rounded() / Constants.coordinatePrecision
        let lon = (location.coordinate.longitude * Constants.coordinatePrecision).rounded() / Constants.coordinatePrecision
        return "\(lat),\(lon)"
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
