import Foundation
import RealmSwift

final class Sticker: Object {

    // MARK: - Properties

    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var imagePath: String = ""
    @Persisted var colorName: String = ""
    @Persisted var hexColor: String = ""
    @Persisted var createdAt: Date = Date()

    var imageURL: URL {
        StickerManager.shared.stickerURL(for: imagePath)
    }
}
