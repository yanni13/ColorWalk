import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "담아 위젯" }
    static var description: IntentDescription { "오늘 걷다 마주친 색을 홈 화면에 담아두세요." }
}
