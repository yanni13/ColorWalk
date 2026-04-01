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
    static let mockMissions: [ColorMission] = [
        ColorMission(
            name: "비 온 뒤 초록",
            hexColor: "#34D399",
            color: UIColor(hex: "#34D399"),
            weatherInfo: "오늘의 날씨: 흐린 후 맑음",
            progress: 0.0
        ),
        ColorMission(
            name: "하늘빛 파랑",
            hexColor: "#5B8DEF",
            color: UIColor(hex: "#5B8DEF"),
            weatherInfo: "오늘의 날씨: 맑음",
            progress: 0.0
        ),
        ColorMission(
            name: "노을 주황",
            hexColor: "#FF9500",
            color: UIColor(hex: "#FF9500"),
            weatherInfo: "오늘의 날씨: 구름 조금",
            progress: 0.0
        ),
        ColorMission(
            name: "벚꽃 핑크",
            hexColor: "#FF7EB3",
            color: UIColor(hex: "#FF7EB3"),
            weatherInfo: "오늘의 날씨: 맑음",
            progress: 0.0
        ),
        ColorMission(
            name: "새벽 보라",
            hexColor: "#BF5AF2",
            color: UIColor(hex: "#BF5AF2"),
            weatherInfo: "오늘의 날씨: 흐림",
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

    private let repository: ColorMissionRepositoryProtocol
    private let weatherService: WeatherServiceProtocol
    private let missions: [ColorMission]
    private let indexRelay: BehaviorRelay<Int>
    private let weatherDataRelay = BehaviorRelay<WeatherData>(value: WeatherData(displayText: "날씨 정보 없음", symbolName: "sun.max", celsius: "0°C", humidity: "0%"))
    private let disposeBag = DisposeBag()

    init(
        repository: ColorMissionRepositoryProtocol = MockColorMissionRepository(),
        weatherService: WeatherServiceProtocol = WeatherKitService()
    ) {
        self.repository = repository
        self.weatherService = weatherService
        self.missions = repository.fetchMissions()
        self.indexRelay = BehaviorRelay<Int>(value: 0)
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

        // 미션 생성 및 셔플 로직
        let missionSubject = BehaviorSubject<ColorMission>(value: ColorMission.mockMissions[0])

        // 셔플이나 날씨 변경 시 새 미션 생성
        Observable.merge(
            input.shuffleTap,
            input.changeMissionTap,
            weatherDataRelay.skip(1).map { _ in () }
        )
        .withLatestFrom(weatherDataRelay)
        .map { weatherData in
            MissionGenerator.generate(weatherSymbol: weatherData.symbolName, weatherText: "오늘의 날씨는 \(weatherData.displayText)이에요")
        }
        .bind(to: missionSubject)
        .disposed(by: disposeBag)

        let missionObservable = missionSubject.asObservable().share(replay: 1)

        missionObservable
            .bind(onNext: { ColorMissionStore.shared.setMission($0) })
            .disposed(by: disposeBag)

        let mission = missionObservable
            .asDriver(onErrorJustReturn: ColorMission.mockMissions[0])

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
