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
                dateString: String(localized: "widget.date.today"),
                missionColorHex: "#5B8DEF",
                missionColorName: String(localized: "widget.today.color"),
                photos: [],
                dateIdentifier: nil
            )
        )
    }

    static func newDay(hex: String) -> ColorWalkEntry {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return ColorWalkEntry(
            date: .now,
            dailyData: WidgetDailyData(
                dateString: formatter.string(from: Date()),
                missionColorHex: hex,
                missionColorName: String(localized: "widget.today.color"),
                photos: [],
                dateIdentifier: nil
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
        guard let data = WidgetDataStore.shared.loadDailyData() else {
            return newDayEntry()
        }
        if let storedIdentifier = data.dateIdentifier {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayIdentifier = formatter.string(from: Date())
            if storedIdentifier != todayIdentifier {
                return newDayEntry()
            }
        }
        return ColorWalkEntry(date: .now, dailyData: data)
    }

    private func newDayEntry() -> ColorWalkEntry {
        let weatherSymbol = WidgetDataStore.shared.loadWeatherSymbol()
        let hex = WidgetColorGenerator.hex(for: Date(), weatherSymbol: weatherSymbol)
        return .newDay(hex: hex)
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
    let kind: String = WidgetConstants.Kind.main

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
        .configurationDisplayName("widget.displayName")
        .description("widget.description")
    }
}
