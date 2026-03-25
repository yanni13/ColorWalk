import Foundation
import RealmSwift

final class ColorSlot: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var index: Int = 0
    @Persisted var isCaptured: Bool = false
    @Persisted var linkedPhoto: Photo?

    @Persisted(originProperty: "slots") var parentMission: LinkingObjects<DailyMission>
}
