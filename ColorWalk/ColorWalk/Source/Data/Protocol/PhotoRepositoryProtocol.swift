import Foundation

protocol PhotoRepositoryProtocol {
    func fetchAllPhotos() -> [Photo]
    func savePhoto(_ photo: Photo, toSlotIndex index: Int, missionId: String)
}
