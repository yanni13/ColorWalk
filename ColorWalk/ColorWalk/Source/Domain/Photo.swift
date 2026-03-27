import Foundation
import RealmSwift

final class Photo: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var imagePath: String = "" // 파일명만 저장 (Relative Path)
    @Persisted var capturedHex: String = ""
    @Persisted var matchRate: Double = 0.0
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var locationName: String = "알 수 없는 위치"
    @Persisted var createdAt: Date = Date()
    @Persisted var isFromGallery: Bool = false

    var imageURL: URL {
        return ImageFileManager.shared.getImageUrl(fileName: imagePath)
    }
}
