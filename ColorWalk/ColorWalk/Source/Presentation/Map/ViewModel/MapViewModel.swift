import RxSwift
import RxCocoa

final class MapViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let clusterTapped: Observable<[Photo]>
    }

    struct Output {
        let annotations: Driver<[PhotoAnnotation]>
        let selectedPhotos: Driver<[Photo]>
        let nearbySubtitle: Driver<String>
    }

    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        let annotations = input.viewDidLoad
            .map { _ -> [PhotoAnnotation] in
                RealmManager.shared.fetchAllPhotos()
                    .filter { $0.latitude != 0 || $0.longitude != 0 }
                    .map { PhotoAnnotation(photo: $0) }
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
                // Simple color name: use hex if no name available
                return "\(first.capturedHex) 외 \(max(0, photos.count - 1))장"
            }

        return Output(
            annotations: annotations,
            selectedPhotos: selectedPhotos,
            nearbySubtitle: nearbySubtitle
        )
    }
}
