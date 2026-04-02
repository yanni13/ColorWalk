import WidgetKit
import SwiftUI

// MARK: - Entry

struct ColorWalkEntry: TimelineEntry {
    let date: Date
    let dailyData: WidgetDailyData

    static var placeholder: ColorWalkEntry {
        ColorWalkEntry(
            date: .now,
            dailyData: WidgetDailyData(
                dateString: "오늘",
                missionColorHex: "#5B8DEF",
                missionColorName: "오늘의 색상",
                photos: []
            )
        )
    }
}

// MARK: - Provider

struct ColorWalkProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> ColorWalkEntry {
        .placeholder
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> ColorWalkEntry {
        loadEntry()
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<ColorWalkEntry> {
        let entry = loadEntry()
        let nextMidnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }

    private func loadEntry() -> ColorWalkEntry {
        guard let data = WidgetDataStore.shared.loadDailyData() else { return .placeholder }
        return ColorWalkEntry(date: .now, dailyData: data)
    }
}

// MARK: - Entry View

struct ColorWalkWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ColorWalkEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

struct ColorWalkWidget: Widget {
    let kind: String = "ColorWalkWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: ColorWalkProvider()
        ) { entry in
            ColorWalkWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .configurationDisplayName("오늘의 컬러워크")
        .description("오늘 수집한 색상을 확인하세요.")
    }
}
