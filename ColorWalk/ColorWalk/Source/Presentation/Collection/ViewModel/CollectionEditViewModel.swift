import Foundation
import RxSwift
import RxCocoa
import RealmSwift

struct PhotoPickerItem {
    let photoId: String
    let imagePath: String
    let capturedHex: String
    var isSelected: Bool
    var selectionOrder: Int?
}

final class CollectionEditViewModel: ViewModelType {

    // MARK: - Constants

    private enum Constants {
        static let maxSelection: Int = 9
    }

    // MARK: - Input / Output

    struct Input {
        let photoTap: Observable<Int>
        let doneTap: Observable<Void>
    }

    struct Output {
        let photoItems: Driver<[PhotoPickerItem]>
        let selectedCount: Driver<Int>
        let saveCompleted: Driver<Void>
    }

    // MARK: - Properties

    private let missionDateIdentifier: String
    private let photoItemsRelay: BehaviorRelay<[PhotoPickerItem]>
    private let disposeBag = DisposeBag()

    // MARK: - Init

    init(missionDateIdentifier: String) {
        self.missionDateIdentifier = missionDateIdentifier

        let allPhotos = RealmManager.shared.fetchAllPhotos()
        let mission = RealmManager.shared.fetchDailyMission(for: missionDateIdentifier)
        let preSelectedPaths: [String] = (mission.map { Array($0.slots) } ?? [])
            .sorted { $0.index < $1.index }
            .compactMap { $0.linkedPhoto?.imagePath }

        let items = allPhotos.map { photo -> PhotoPickerItem in
            if let orderIndex = preSelectedPaths.firstIndex(of: photo.imagePath) {
                return PhotoPickerItem(
                    photoId: photo.imagePath,
                    imagePath: photo.imagePath,
                    capturedHex: photo.capturedHex,
                    isSelected: true,
                    selectionOrder: orderIndex + 1
                )
            }
            return PhotoPickerItem(
                photoId: photo.imagePath,
                imagePath: photo.imagePath,
                capturedHex: photo.capturedHex,
                isSelected: false,
                selectionOrder: nil
            )
        }
        self.photoItemsRelay = BehaviorRelay(value: items)
    }

    // MARK: - Transform

    func transform(input: Input) -> Output {
        bindPhotoTap(input.photoTap)

        let selectedCount = photoItemsRelay
            .map { $0.filter { $0.isSelected }.count }
            .asDriver(onErrorJustReturn: 0)

        let saveCompleted = input.doneTap
            .do(onNext: { [weak self] in self?.saveSelectedPhotos() })
            .map { () }
            .asDriver(onErrorJustReturn: ())

        return Output(
            photoItems: photoItemsRelay.asDriver(),
            selectedCount: selectedCount,
            saveCompleted: saveCompleted
        )
    }

    // MARK: - Private

    private func bindPhotoTap(_ tap: Observable<Int>) {
        tap
            .subscribe(onNext: { [weak self] index in
                guard let self else { return }
                var items = photoItemsRelay.value
                guard index < items.count else { return }

                if items[index].isSelected {
                    let removedOrder = items[index].selectionOrder
                    items[index].isSelected = false
                    items[index].selectionOrder = nil
                    if let removedOrder {
                        for i in items.indices {
                            if let order = items[i].selectionOrder, order > removedOrder {
                                items[i].selectionOrder = order - 1
                            }
                        }
                    }
                } else {
                    let currentCount = items.filter { $0.isSelected }.count
                    guard currentCount < Constants.maxSelection else { return }
                    items[index].isSelected = true
                    items[index].selectionOrder = currentCount + 1
                }
                photoItemsRelay.accept(items)
            })
            .disposed(by: disposeBag)
    }

    private func saveSelectedPhotos() {
        let allPhotos = RealmManager.shared.fetchAllPhotos()
        let selectedItems = photoItemsRelay.value
            .filter { $0.isSelected }
            .sorted { ($0.selectionOrder ?? 0) < ($1.selectionOrder ?? 0) }

        let selectedPhotos = selectedItems.compactMap { item in
            allPhotos.first { $0.imagePath == item.imagePath }
        }
        RealmManager.shared.reassignMissionSlots(
            missionId: missionDateIdentifier,
            photos: selectedPhotos
        )
    }
}
