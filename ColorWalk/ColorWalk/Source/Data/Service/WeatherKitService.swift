import Foundation
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
                    let data = try await WeatherCacheManager.shared.fetch(for: location)
                    single(.success(data.displayText))
                } catch {
                    single(.success("날씨 정보 없음"))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }
}
