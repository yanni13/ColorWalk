import Foundation
import CoreLocation
import RxSwift

// MARK: - Protocol

protocol WeatherServiceProtocol {
    func fetchWeatherInfo(for location: CLLocation) -> Single<WeatherData>
}

// MARK: - Implementation

final class WeatherKitService: WeatherServiceProtocol {

    func fetchWeatherInfo(for location: CLLocation) -> Single<WeatherData> {
        Single.create { single in
            let task = Task {
                do {
                    let data = try await WeatherCacheManager.shared.fetch(for: location)
                    single(.success(data))
                } catch {
                    // 기본 에러 데이터
                    single(.success(WeatherData(displayText: "날씨 정보 없음", symbolName: "sun.max", celsius: "0°C", humidity: "0%")))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }
}
