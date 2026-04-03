import Foundation
import RealmSwift

final class MockPhotoRepository: PhotoRepositoryProtocol {
    func deletePhoto(_ photo: Photo) {
        
    }
    
    func deleteAllPhotos() {
        
    }
    

    // MARK: - Properties

    private lazy var photos: [Photo] = Self.makeMockPhotos()

    // MARK: - PhotoRepositoryProtocol

    func fetchAllPhotos() -> [Photo] {
        photos
    }

    func savePhoto(_ photo: Photo, toSlotIndex index: Int, missionId: String) {}

    func savePhotoOnly(_ photo: Photo) {}

    // MARK: - Mock Data

    private static func makeMockPhotos() -> [Photo] {
        let mockData: [(hex: String, lat: Double, lng: Double, rate: Double, daysAgo: Double, imageURL: String)] = [
            ("#FF7EB3", 37.5236, 126.9338, 0.98, 6,  "https://picsum.photos/seed/cherry/200/200"),
            ("#3182F6", 35.1532, 129.1183, 0.85, 8,  "https://picsum.photos/seed/ocean/200/200"),
            ("#34C759", 37.6606, 126.9997, 0.91, 11, "https://picsum.photos/seed/forest/200/200"),
            ("#FF9500", 37.5796, 126.9770, 0.76, 14, "https://picsum.photos/seed/sunset/200/200"),
            ("#BF5AF2", 37.5512, 126.9882, 0.88, 16, "https://picsum.photos/seed/lavender/200/200"),
            ("#34D399", 37.5045, 127.0050, 0.72, 20, "https://picsum.photos/seed/mint/200/200"),
            ("#5B8DEF", 37.5133, 127.1028, 0.94, 22, "https://picsum.photos/seed/sky/200/200"),
            ("#FFB347", 37.5171, 127.0473, 0.81, 25, "https://picsum.photos/seed/golden/200/200"),
            ("#FF6B6B", 37.5665, 126.9780, 0.67, 30, "https://picsum.photos/seed/brick/200/200"),
        ]

        return mockData.map { item in
            let photo = Photo()
            photo.capturedHex = item.hex
            photo.latitude = item.lat
            photo.longitude = item.lng
            photo.matchRate = item.rate
            photo.imagePath = item.imageURL
            photo.createdAt = Date().addingTimeInterval(-86400 * item.daysAgo)
            photo.isFromGallery = false
            return photo
        }
    }
}
