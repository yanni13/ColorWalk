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
    }

    private let repository: ColorMissionRepositoryProtocol
    private let weatherService: WeatherServiceProtocol
    private let missions: [ColorMission]
    private let indexRelay = BehaviorRelay<Int>(value: 0)
    private let weatherInfoRelay = BehaviorRelay<String>(value: "날씨 정보 없음")
    private let disposeBag = DisposeBag()

    init(
        repository: ColorMissionRepositoryProtocol = MockColorMissionRepository(),
        weatherService: WeatherServiceProtocol = WeatherKitService()
    ) {
        self.repository = repository
        self.weatherService = weatherService
        self.missions = repository.fetchMissions()
    }

    func transform(input: Input) -> Output {
        let count = missions.count

        Observable.merge(input.shuffleTap, input.changeMissionTap)
            .withLatestFrom(indexRelay)
            .map { ($0 + 1) % count }
            .bind(to: indexRelay)
            .disposed(by: disposeBag)

        input.location
            .distinctUntilChanged { $0.distance(from: $1) < 1000 }
            .flatMapLatest { [weak self] location -> Observable<String> in
                guard let self else { return .just("날씨 정보 없음") }
                return self.weatherService.fetchWeatherInfo(for: location)
                    .asObservable()
                    .catchAndReturn("날씨 정보 없음")
            }
            .bind(to: weatherInfoRelay)
            .disposed(by: disposeBag)

        let missionObservable = Observable.combineLatest(indexRelay, weatherInfoRelay)
            .map { [weak self] idx, weatherInfo -> ColorMission in
                guard let self else { return ColorMission.mockMissions[0] }
                let base = self.missions[idx]
                return ColorMission(
                    name: base.name,
                    hexColor: base.hexColor,
                    color: base.color,
                    weatherInfo: "오늘의 날씨: \(weatherInfo)",
                    progress: base.progress
                )
            }
            .share(replay: 1)

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

        return Output(mission: mission, saveResult: saveResult)
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
