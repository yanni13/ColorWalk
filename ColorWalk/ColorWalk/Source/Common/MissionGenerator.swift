//
//  MissionGenerator.swift
//  ColorWalk
//

import UIKit

enum WeatherTheme: CaseIterable {
    case clear, cloudy, rainy, extreme

    static func from(symbolName: String) -> WeatherTheme {
        switch symbolName {
        case let s where s.contains("sun") || s.contains("clear"): return .clear
        case let s where s.contains("cloud"): return .cloudy
        case let s where s.contains("rain") || s.contains("snow") || s.contains("drizzle"): return .rainy
        default: return .extreme
        }
    }
}

final class MissionGenerator {
    
    struct ColorCandidate {
        let hex: String
        let nameTemplates: [String]
    }

    private static var themes: [WeatherTheme: [ColorCandidate]] {
        [
            .clear: [
                ColorCandidate(hex: "#FFD700", nameTemplates: [L10n.missionThemeSunFull, L10n.missionThemeGolden, L10n.missionThemeClearOf]),
                ColorCandidate(hex: "#87CEEB", nameTemplates: [L10n.missionThemeBlueSky, L10n.missionThemeClearLake, L10n.missionThemeCool]),
                ColorCandidate(hex: "#FFA500", nameTemplates: [L10n.missionThemeRefreshing, L10n.missionThemeAfternoon, L10n.missionThemeShining]),
                ColorCandidate(hex: "#FF7EB3", nameTemplates: [L10n.missionThemeCherryBlossom, L10n.missionThemeShy, L10n.missionThemeVivid]),
                ColorCandidate(hex: "#FDE047", nameTemplates: [L10n.missionThemeCanola, L10n.missionThemeBright, L10n.missionThemeYellow])
            ],
            .cloudy: [
                ColorCandidate(hex: "#708090", nameTemplates: [L10n.missionThemeFoggy, L10n.missionThemeCalm, L10n.missionThemeSlate]),
                ColorCandidate(hex: "#B0C4DE", nameTemplates: [L10n.missionThemeThroughClouds, L10n.missionThemeLight, L10n.missionThemeFaint]),
                ColorCandidate(hex: "#94A3B8", nameTemplates: [L10n.missionThemeCityForest, L10n.missionThemeMonochrome, L10n.missionThemeStatic]),
                ColorCandidate(hex: "#64748B", nameTemplates: [L10n.missionThemeDeepNight, L10n.missionThemeHeavy, L10n.missionThemeCalm]),
                ColorCandidate(hex: "#E2E8F0", nameTemplates: [L10n.missionThemeCloudySky, L10n.missionThemeClean, L10n.missionThemeSoft])
            ],
            .rainy: [
                ColorCandidate(hex: "#34D399", nameTemplates: [L10n.missionThemeAfterRain, L10n.missionThemeLively, L10n.missionThemeForest]),
                ColorCandidate(hex: "#4682B4", nameTemplates: [L10n.missionThemeRainSoaked, L10n.missionThemeSteel, L10n.missionThemeMoist]),
                ColorCandidate(hex: "#10B981", nameTemplates: [L10n.missionThemeGrassScent, L10n.missionThemeGreenTone, L10n.missionThemeFresh]),
                ColorCandidate(hex: "#064E3B", nameTemplates: [L10n.missionThemeDeepMountain, L10n.missionThemeDeep, L10n.missionThemeForestOf]),
                ColorCandidate(hex: "#0F172A", nameTemplates: [L10n.missionThemeMidnight, L10n.missionThemeAbyss, L10n.missionThemeDark])
            ],
            .extreme: [
                ColorCandidate(hex: "#483D8B", nameTemplates: [L10n.missionThemeBeforeStorm, L10n.missionThemeIntense, L10n.missionThemeMysterious]),
                ColorCandidate(hex: "#FF4500", nameTemplates: [L10n.missionThemeHeat, L10n.missionThemeBlazing, L10n.missionThemeIntense]),
                ColorCandidate(hex: "#4B0082", nameTemplates: [L10n.missionThemeLightningFlash, L10n.missionThemeIndigo, L10n.missionThemeHeavyFeel]),
                ColorCandidate(hex: "#DC2626", nameTemplates: [L10n.missionThemeWarning, L10n.missionThemeIntense, L10n.missionThemePassion]),
                ColorCandidate(hex: "#1E293B", nameTemplates: [L10n.missionThemeGaleWind, L10n.missionThemeCold, L10n.missionThemeDark])
            ]
        ]
    }

    static func generate(weatherSymbol: String, weatherText: String, shuffled: Bool = false) -> ColorMission {
        let theme = WeatherTheme.from(symbolName: weatherSymbol)
        let hour = Calendar.current.component(.hour, from: Date())

        guard let candidates = themes[theme] else {
            return ColorMission.placeholder
        }

        let candidate: ColorCandidate
        let themePrefix: String

        if shuffled {
            guard let random = candidates.randomElement() else { return ColorMission.placeholder }
            candidate = random
            themePrefix = candidate.nameTemplates.randomElement() ?? ""
        } else {
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            candidate = candidates[(dayOfYear - 1) % candidates.count]
            themePrefix = candidate.nameTemplates[(dayOfYear - 1) % candidate.nameTemplates.count]
        }

        let colorName = getColorName(for: candidate.hex)
        
        var timePrefix = ""
        if (17...20).contains(hour) { timePrefix = L10n.missionThemeSunset }
        else if (5...8).contains(hour) { timePrefix = L10n.missionThemeDawn }
        else if (21...23).contains(hour) || (0...4).contains(hour) { timePrefix = L10n.missionThemeNight }

        // 단계별 이름 조합 (10자 이내 최적화)
        var finalName = ""
        
        // 1순위: [시간] [테마] [색상] (예: "노을 햇살 가득 노랑")
        let fullOption = "\(timePrefix) \(themePrefix) \(colorName)".replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
        
        // 2순위: [테마] [색상] (예: "햇살 가득 노랑")
        let themeOption = "\(themePrefix) \(colorName)".trimmingCharacters(in: .whitespaces)
        
        // 3순위: [시간] [색상] (예: "노을 노랑")
        let timeOption = "\(timePrefix) \(colorName)".trimmingCharacters(in: .whitespaces)
        
        if fullOption.count <= 10 {
            finalName = fullOption
        } else if themeOption.count <= 10 {
            finalName = themeOption
        } else if timeOption.count <= 10 {
            finalName = timeOption
        } else {
            finalName = colorName // 최악의 경우 색상 이름만이라도 표시
        }

        return ColorMission(
            name: finalName,
            hexColor: candidate.hex,
            color: UIColor(hex: candidate.hex),
            weatherInfo: weatherText,
            progress: 0.0
        )
    }

    private static func getColorName(for hex: String) -> String {
        switch hex.lowercased() {
        case "#ffd700": return L10n.missionColorYellow
        case "#87ceeb": return L10n.missionColorSky
        case "#ffa500": return L10n.missionColorOrange
        case "#ff7eb3": return L10n.missionColorPink
        case "#fde047": return L10n.missionColorYellow
        case "#708090": return L10n.missionColorGray
        case "#b0c4de": return L10n.missionColorBlue
        case "#94a3b8": return L10n.missionColorGray
        case "#64748b": return L10n.missionColorSlate
        case "#e2e8f0": return L10n.missionColorLightGray
        case "#34d399": return L10n.missionColorGreen
        case "#4682b4": return L10n.missionColorBlue
        case "#10b981": return L10n.missionColorGreen
        case "#064e3b": return L10n.missionColorDarkGreen
        case "#0f172a": return L10n.missionColorNavy
        case "#483d8b": return L10n.missionColorPurple
        case "#ff4500": return L10n.missionColorOrange
        case "#4b0082": return L10n.missionColorIndigo
        case "#dc2626": return L10n.missionColorRed
        case "#1e293b": return L10n.missionColorBlueGray
        default: return L10n.missionColorDefault
        }
    }
}
