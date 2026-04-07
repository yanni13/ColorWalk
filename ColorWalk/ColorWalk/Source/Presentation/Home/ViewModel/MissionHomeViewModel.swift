//
//  MissionHomeViewModel.swift
//  ColorWalk
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation
import Photos

// MARK: - Model

struct ColorMission {
    let name: String
    let hexColor: String
    let color: UIColor
    let weatherInfo: String
    let progress: Float
}

extension ColorMission {
    static var placeholder: ColorMission {
        ColorMission(
            name: L10n.homeMissionSection,
            hexColor: "#B0B8C1",
            color: UIColor(hex: "#B0B8C1"),
            weatherInfo: L10n.missionWeatherNoInfo,
            progress: 0.0
        )
    }

    static let mockMissions: [ColorMission] = [
        ColorMission(
            name: "\(L10n.missionThemeAfterRain) \(L10n.missionColorGreen)",
            hexColor: "#34D399",
            color: UIColor(hex: "#34D399"),
            weatherInfo: L10n.missionWeatherNoInfo,
            progress: 0.0
        ),
        ColorMission(
            name: "\(L10n.missionThemeClearOf) \(L10n.missionColorBlue)",
            hexColor: "#5B8DEF",
            color: UIColor(hex: "#5B8DEF"),
            weatherInfo: L10n.missionWeatherNoInfo,
            progress: 0.0
        ),
        ColorMission(
            name: "\(L10n.missionThemeSunset) \(L10n.missionColorOrange)",
            hexColor: "#FF9500",
            color: UIColor(hex: "#FF9500"),
            weatherInfo: L10n.missionWeatherNoInfo,
            progress: 0.0
        ),
        ColorMission(
            name: "\(L10n.missionThemeCherryBlossom) \(L10n.missionColorPink)",
            hexColor: "#FF7EB3",
            color: UIColor(hex: "#FF7EB3"),
            weatherInfo: L10n.missionWeatherNoInfo,
            progress: 0.0
        ),
        ColorMission(
            name: "\(L10n.missionThemeDawn) \(L10n.missionColorPurple)",
            hexColor: "#BF5AF2",
            color: UIColor(hex: "#BF5AF2"),
            weatherInfo: L10n.missionWeatherNoInfo,
            progress: 0.0
        )
    ]
}

// MARK: - GallerySaveResult

enum GallerySaveResult {
    case success
    case failure
    case permissionDenied
}

// MARK: - ViewModel

final class MissionHomeViewModel: ViewModelType {

    struct Input {
        let shuffleTap: Observable<Void>
        let changeMissionTap: Observable<Void>
        let location: Observable<CLLocation>
        let saveTap: Observable<UIImage?>
    }

    struct Output {
        let mission: Driver<ColorMission>
        let saveResult: Driver<GallerySaveResult>
        let weatherData: Driver<WeatherData>
    }

    private let repository: MissionRepositoryProtocol
    private let weatherService: WeatherServiceProtocol
    private let missions: [ColorMission] = [] // Unused in this context
    private let weatherDataRelay = BehaviorRelay<WeatherData>(value: WeatherData(displayText: L10n.missionWeatherNoInfo, symbolName: "sun.max", celsius: "0°C", humidity: "0%"))
    private let disposeBag = DisposeBag()

    init(
        repository: MissionRepositoryProtocol = RealmMissionRepository(),
        weatherService: WeatherServiceProtocol = WeatherKitService()
    ) {
        self.repository = repository
        self.weatherService = weatherService
    }

    func transform(input: Input) -> Output {
        input.location
            .distinctUntilChanged { $0.distance(from: $1) < 1000 }
            .flatMapLatest { [weak self] location -> Observable<WeatherData> in
                guard let self else { return .empty() }
                return self.weatherService.fetchWeatherInfo(for: location)
                    .asObservable()
            }
            .bind(to: weatherDataRelay)
            .disposed(by: disposeBag)

        // 초기 미션 상태 결정
        let initialMission: ColorMission
        let today = DateManager.storedString(from: Date())
        
        if let existing = repository.fetchDailyMission(for: today), !existing.recommendedHex.isEmpty {
            initialMission = ColorMission(
                name: existing.recommendedMissionName,
                hexColor: existing.recommendedHex,
                color: UIColor(hex: existing.recommendedHex),
                weatherInfo: existing.weatherStatus,
                progress: 0.0
            )
        } else {
            initialMission = ColorMission.placeholder
        }

        let missionSubject = BehaviorSubject<ColorMission>(value: initialMission)

        // 셔플이나 날씨 변경 시 새 미션 생성 (단, 이미 오늘 미션이 Realm에 고정되어 있다면 날씨 변경으로 인한 자동 갱신은 방지)
        let shuffleOrChange = Observable.merge(
            input.shuffleTap,
            input.changeMissionTap
        )

        // 날씨가 처음으로 로드되었을 때, Realm에 미션이 없다면 생성
        let firstWeatherLoad = weatherDataRelay.skip(1).take(1)
            .filter { _ in
                let today = DateManager.storedString(from: Date())
                if let existing = self.repository.fetchDailyMission(for: today) {
                    return existing.recommendedHex.isEmpty
                }
                return true
            }
            .map { _ in () }

        Observable.merge(shuffleOrChange, firstWeatherLoad)
            .withLatestFrom(weatherDataRelay)
            .map { weatherData in
                MissionGenerator.generate(weatherSymbol: weatherData.symbolName, weatherText: L10n.missionWeatherInfoFormat(weatherData.displayText))
            }
            .bind(to: missionSubject)
            .disposed(by: disposeBag)

        let missionObservable = missionSubject.asObservable().share(replay: 1)

        missionObservable
            .bind(onNext: { ColorMissionStore.shared.setMission($0) })
            .disposed(by: disposeBag)

        let mission = missionObservable
            .asDriver(onErrorJustReturn: ColorMission.placeholder)

        let saveResult = input.saveTap
            .compactMap { $0 }
            .flatMapFirst { [weak self] image -> Observable<GallerySaveResult> in
                guard let self else { return .empty() }
                return self.requestPhotoLibraryAuthorization()
                    .flatMap { status -> Observable<GallerySaveResult> in
                        switch status {
                        case .authorized, .limited:
                            return self.saveImageToGallery(image)
                        default:
                            return .just(.permissionDenied)
                        }
                    }
            }
            .asDriver(onErrorJustReturn: .failure)

        return Output(
            mission: mission,
            saveResult: saveResult,
            weatherData: weatherDataRelay.asDriver()
        )
    }

    // MARK: - Private

    private func requestPhotoLibraryAuthorization() -> Observable<PHAuthorizationStatus> {
        return Observable.create { observer in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                observer.onNext(status)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    private func saveImageToGallery(_ image: UIImage) -> Observable<GallerySaveResult> {
        return Observable.create { observer in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                observer.onNext(success ? .success : .failure)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
