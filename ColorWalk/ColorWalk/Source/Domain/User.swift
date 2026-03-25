import Foundation
import RealmSwift

final class User: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var jobType: String = ""
    @Persisted var pushMorningTime: Date?
    @Persisted var pushEveningTime: Date?
    @Persisted var isNotificationOn: Bool = false
}
