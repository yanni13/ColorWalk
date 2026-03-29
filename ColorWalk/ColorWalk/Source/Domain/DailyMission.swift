
import Foundation
import RealmSwift

final class DailyMission: Object {
    @Persisted(primaryKey: true) var dateIdentifier: String = ""
    @Persisted var weatherStatus: String = ""
    @Persisted var recommendedHex: String = ""
    @Persisted var recommendedMissionName: String = ""
    @Persisted var slots: List<ColorSlot>
    @Persisted var isPaletteCompleted: Bool = false
    @Persisted var completedAt: Date? = nil
}
