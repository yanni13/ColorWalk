import RxSwift
import UIKit
import RxCocoa

final class MapViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let clusterTapped: Observable<[Photo]>
    }

    struct Output {
        let annotations: Driver<[PhotoAnnotation]>
        let selectedPhotos: Driver<[Photo]>
        let nearbySubtitle: Driver<String>
    }

    private let photoRepository: PhotoRepositoryProtocol
    private let disposeBag = DisposeBag()

    init(photoRepository: PhotoRepositoryProtocol = RealmPhotoRepository()) {
        self.photoRepository = photoRepository
    }

    func transform(input: Input) -> Output {
        // 모든 갱신 시점(로드, 화면진입, 데이터변경)을 하나로 통합
        let annotations = Observable.merge(
                input.viewDidLoad,
                input.viewWillAppear,
                ColorCardStore.shared.cards.map { _ in }.asObservable()
            )
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .map { [weak self] _ -> [PhotoAnnotation] in
                guard let self = self else { return [] }

                // Realm에서 실제 촬영한 사진 데이터만 가져오기 (최신순)
                let realmPhotos = self.photoRepository.fetchAllPhotos()
                    .sorted { $0.createdAt > $1.createdAt }
                    .filter { $0.latitude != 0 || $0.longitude != 0 }

                let groups = realmPhotos.reduce(into: [[Photo]]()) { groups, photo in
                    if let idx = groups.firstIndex(where: { group in
                        guard let first = group.first else { return false }
                        return abs(first.latitude - photo.latitude) < 0.00001 &&
                               abs(first.longitude - photo.longitude) < 0.00001
                    }) {
                        groups[idx].append(photo)
                    } else {
                        groups.append([photo])
                    }
                }
                return groups.compactMap { photos in
                    guard let first = photos.first else { return nil }
                    let targetHex = RealmManager.shared.findMissionColor(for: first)
                    return PhotoAnnotation(photos: photos, targetHex: targetHex)
                }
            }
            .asDriver(onErrorJustReturn: [])

        let selectedPhotos = input.clusterTapped
            .asDriver(onErrorJustReturn: [])

        let nearbySubtitle = selectedPhotos
            .map { photos -> String in
                guard let first = photos.first else { return "" }
                let color = UIColor(hex: first.capturedHex)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: nil)
                return "\(first.capturedHex) 외 \(max(0, photos.count - 1))장"
            }

        return Output(
            annotations: annotations,
            selectedPhotos: selectedPhotos,
            nearbySubtitle: nearbySubtitle
        )
    }
}
