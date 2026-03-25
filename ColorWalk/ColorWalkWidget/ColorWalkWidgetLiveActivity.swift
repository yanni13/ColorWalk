//
//  ColorWalkWidgetLiveActivity.swift
//  ColorWalkWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget

struct ColorWalkWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ColorPickerAttributes.self) { context in
            // 잠금화면 / 알림 배너
            LockScreenBannerView(state: context.state, attrs: context.attributes)
                .activityBackgroundTint(Color.black.opacity(0.85))

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded (꾹 눌렀을 때) 
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(stateColor(context.state))
                            .frame(width: 28, height: 28)
                            .shadow(color: stateColor(context.state).opacity(0.6), radius: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.detectedHex)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("\(context.state.matchPercent)% 일치")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("미션")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.45))
                        Text(context.attributes.missionName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    MatchProgressBar(
                        percent:    context.state.matchPercent,
                        barColor:   stateColor(context.state),
                        missionHex: context.attributes.missionHex
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }

            } compactLeading: {
                // Compact: 왼쪽 컬러 도트
                Circle()
                    .fill(stateColor(context.state))
                    .frame(width: 16, height: 16)
                    .padding(.leading, 4)

            } compactTrailing: {
                // Compact: 오른쪽 미션 hex 코드
                Text(context.attributes.missionHex)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.trailing, 4)

            } minimal: {
                // Minimal: 도트만 
                Circle()
                    .fill(stateColor(context.state))
            }
            .contentMargins(.all, 0, for: .minimal)
        }
    }

    private func stateColor(_ state: ColorPickerAttributes.ContentState) -> Color {
        Color(red: state.red, green: state.green, blue: state.blue)
    }
}

// MARK: - Lock Screen Banner

private struct LockScreenBannerView: View {
    let state: ColorPickerAttributes.ContentState
    let attrs: ColorPickerAttributes

    private var color: Color { Color(red: state.red, green: state.green, blue: state.blue) }

    var body: some View {
        HStack(spacing: 12) {
            // 컬러 미리보기
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .shadow(color: color.opacity(0.5), radius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(state.detectedHex)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                Text("미션: \(attrs.missionName)  ·  \(state.matchPercent)% 일치")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            // 진행률 링
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(1, CGFloat(state.matchPercent) / 100))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(state.matchPercent)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Match Progress Bar

private struct MatchProgressBar: View {
    let percent:    Int
    let barColor:   Color
    let missionHex: String

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("목표 \(missionHex)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
                Spacer()
                Text("\(percent)%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15))
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(percent) / 100)
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Preview

extension ColorPickerAttributes {
    fileprivate static let preview = ColorPickerAttributes(
        missionName: "Sky Blue",
        missionHex:  "#5B8DEF"
    )
}

extension ColorPickerAttributes.ContentState {
    fileprivate static let low = ColorPickerAttributes.ContentState(
        detectedHex: "#B0C4DE", matchPercent: 42,
        red: 0.69, green: 0.77, blue: 0.87
    )
    fileprivate static let high = ColorPickerAttributes.ContentState(
        detectedHex: "#5B8DEF", matchPercent: 96,
        red: 0.36, green: 0.55, blue: 0.94
    )
}

#Preview("Notification", as: .content, using: ColorPickerAttributes.preview) {
    ColorWalkWidgetLiveActivity()
} contentStates: {
    ColorPickerAttributes.ContentState.low
    ColorPickerAttributes.ContentState.high
}
