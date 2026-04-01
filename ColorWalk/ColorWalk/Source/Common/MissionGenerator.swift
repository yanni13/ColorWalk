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

    private static let themes: [WeatherTheme: [ColorCandidate]] = [
        .clear: [
            ColorCandidate(hex: "#FFD700", nameTemplates: ["햇살 가득", "금빛", "맑은"]),
            ColorCandidate(hex: "#87CEEB", nameTemplates: ["파란 하늘", "맑은 호수", "시원한"]),
            ColorCandidate(hex: "#FFA500", nameTemplates: ["상큼한", "오후의", "빛나는"]),
            ColorCandidate(hex: "#FF7EB3", nameTemplates: ["벚꽃", "수줍은", "화사한"]),
            ColorCandidate(hex: "#FDE047", nameTemplates: ["유채꽃", "밝은", "노란"])
        ],
        .cloudy: [
            ColorCandidate(hex: "#708090", nameTemplates: ["안개 낀", "차분한", "슬레이트"]),
            ColorCandidate(hex: "#B0C4DE", nameTemplates: ["구름 사이", "연한", "아련한"]),
            ColorCandidate(hex: "#94A3B8", nameTemplates: ["빌딩 숲", "무채색", "정적인"]),
            ColorCandidate(hex: "#64748B", nameTemplates: ["깊은 밤", "중후한", "차분한"]),
            ColorCandidate(hex: "#E2E8F0", nameTemplates: ["구름 하늘", "깨끗한", "소프트"])
        ],
        .rainy: [
            ColorCandidate(hex: "#34D399", nameTemplates: ["비 온 뒤", "생기 가득", "숲속"]),
            ColorCandidate(hex: "#4682B4", nameTemplates: ["비 머금은", "스틸", "촉촉한"]),
            ColorCandidate(hex: "#10B981", nameTemplates: ["풀내음", "초록빛", "싱그러운"]),
            ColorCandidate(hex: "#064E3B", nameTemplates: ["깊은 산", "진한", "숲의"]),
            ColorCandidate(hex: "#0F172A", nameTemplates: ["자정의", "심연의", "어두운"])
        ],
        .extreme: [
            ColorCandidate(hex: "#483D8B", nameTemplates: ["폭풍 전야", "강렬한", "신비로운"]),
            ColorCandidate(hex: "#FF4500", nameTemplates: ["열기 가득", "타오르는", "강렬한"]),
            ColorCandidate(hex: "#4B0082", nameTemplates: ["번개 빛", "인디고", "무거운"]),
            ColorCandidate(hex: "#DC2626", nameTemplates: ["경고등", "강렬한", "정열의"]),
            ColorCandidate(hex: "#1E293B", nameTemplates: ["거센 바람", "차가운", "어두운"])
        ]
    ]

    static func generate(weatherSymbol: String, weatherText: String) -> ColorMission {
        let theme = WeatherTheme.from(symbolName: weatherSymbol)
        let hour = Calendar.current.component(.hour, from: Date())
        
        guard let candidates = themes[theme], let candidate = candidates.randomElement() else {
            return ColorMission.mockMissions[0]
        }
        
        let themePrefix = candidate.nameTemplates.randomElement() ?? ""
        let colorName = getColorName(for: candidate.hex)
        
        // 시간 수식어 결정
        var timePrefix = ""
        if (17...20).contains(hour) { timePrefix = "노을" }
        else if (5...8).contains(hour) { timePrefix = "새벽" }
        else if (21...23).contains(hour) || (0...4).contains(hour) { timePrefix = "밤" }

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
        case "#ffd700": return "노랑"
        case "#87ceeb": return "하늘"
        case "#ffa500": return "주황"
        case "#ff7eb3": return "핑크"
        case "#fde047": return "노랑"
        case "#708090": return "회색"
        case "#b0c4de": return "파랑"
        case "#94a3b8": return "회색"
        case "#64748b": return "슬레이트"
        case "#e2e8f0": return "연회색"
        case "#34d399": return "초록"
        case "#4682b4": return "파랑"
        case "#10b981": return "초록"
        case "#064e3b": return "진초록"
        case "#0f172a": return "남색"
        case "#483d8b": return "보라"
        case "#ff4500": return "오렌지"
        case "#4b0082": return "인디고"
        case "#dc2626": return "빨강"
        case "#1e293b": return "회청색"
        default: return "색상"
        }
    }
}
