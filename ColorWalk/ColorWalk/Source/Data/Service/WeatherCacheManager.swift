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
            displayText: "\(current.condition.localizedDescription) · \(celsius)",
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

// MARK: - WeatherCondition Localized

private extension WeatherCondition {
    var localizedDescription: String {
        switch self {
        case .clear:                    return L10n.weatherClear
        case .mostlyClear:              return L10n.weatherMostlyClear
        case .partlyCloudy:             return L10n.weatherPartlyCloudy
        case .mostlyCloudy:             return L10n.weatherMostlyCloudy
        case .cloudy:                   return L10n.weatherCloudy
        case .foggy:                    return L10n.weatherFoggy
        case .haze:                     return L10n.weatherHaze
        case .smoky:                    return L10n.weatherSmoky
        case .breezy:                   return L10n.weatherBreezy
        case .windy:                    return L10n.weatherWindy
        case .blowingDust:              return L10n.weatherBlowingDust
        case .drizzle:                  return L10n.weatherDrizzle
        case .rain:                     return L10n.weatherRain
        case .heavyRain:                return L10n.weatherHeavyRain
        case .sunShowers:               return L10n.weatherSunShowers
        case .isolatedThunderstorms:    return L10n.weatherIsolatedThunderstorms
        case .scatteredThunderstorms:   return L10n.weatherScatteredThunderstorms
        case .thunderstorms:            return L10n.weatherThunderstorms
        case .strongStorms:             return L10n.weatherStrongStorms
        case .snow:                     return L10n.weatherSnow
        case .heavySnow:                return L10n.weatherHeavySnow
        case .flurries:                 return L10n.weatherFlurries
        case .sunFlurries:              return L10n.weatherSunFlurries
        case .blowingSnow:              return L10n.weatherBlowingSnow
        case .blizzard:                 return L10n.weatherBlizzard
        case .sleet:                    return L10n.weatherSleet
        case .hail:                     return L10n.weatherHail
        case .freezingRain:             return L10n.weatherFreezingRain
        case .freezingDrizzle:          return L10n.weatherFreezingDrizzle
        case .wintryMix:                return L10n.weatherWintryMix
        case .hot:                      return L10n.weatherHot
        case .frigid:                   return L10n.weatherFrigid
        case .hurricane:                return L10n.weatherHurricane
        case .tropicalStorm:            return L10n.weatherTropicalStorm
        default:                        return L10n.weatherDefault
        }
    }
}
