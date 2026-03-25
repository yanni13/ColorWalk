import Foundation
import RealmSwift

final class Photo: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var imagePath: String = ""
    @Persisted var capturedHex: String = ""
    @Persisted var matchRate: Double = 0.0
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var createdAt: Date = Date()
}
