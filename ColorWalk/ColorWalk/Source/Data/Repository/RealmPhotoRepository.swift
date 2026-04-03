import Foundation

final class RealmPhotoRepository: PhotoRepositoryProtocol {

    // MARK: - PhotoRepositoryProtocol

    func fetchAllPhotos() -> [Photo] {
        RealmManager.shared.fetchAllPhotos()
    }

    func savePhoto(_ photo: Photo, toSlotIndex index: Int, missionId: String) {
        RealmManager.shared.savePhoto(photo, toSlotIndex: index, missionId: missionId)
    }

    func savePhotoOnly(_ photo: Photo) {
        RealmManager.shared.savePhotoOnly(photo)
    }

    func deletePhoto(_ photo: Photo) {
        RealmManager.shared.deletePhoto(photo)
    }

    func deleteAllPhotos() {
        RealmManager.shared.deleteAllPhotos()
    }
}
