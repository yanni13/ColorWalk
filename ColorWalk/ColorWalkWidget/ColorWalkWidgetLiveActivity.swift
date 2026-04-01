//
//  ColorWalkWidgetLiveActivity.swift
//  ColorWalkWidget

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget

struct ColorWalkWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ColorPickerAttributes.self) { context in
            LockScreenBannerView(state: context.state, attrs: context.attributes)
                .activityBackgroundTint(Color.black.opacity(0.9))

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded: 꾹 눌렀을 때
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(missionColor(context.attributes))
                            .frame(width: 32, height: 32)
                            .shadow(color: missionColor(context.attributes).opacity(0.6), radius: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(context.attributes.missionHex) 포착 중")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("\(context.state.matchPercent)% 일치")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let timerEnd = context.state.timerEnd {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("남은 시간")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.45))
                            Text(timerInterval: Date()...timerEnd, countsDown: true, showsHours: false)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(.trailing, 6)
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("미션")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.45))
                            Text(": \(context.attributes.missionName)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.trailing, 6)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    MatchProgressBar(
                        percent: context.state.matchPercent,
                        barColor: missionColor(context.attributes),
                        missionHex: context.attributes.missionHex
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }

            } compactLeading: {
                // 컬러칩 (Compact Leading)
                RoundedRectangle(cornerRadius: 6)
                    .fill(missionColor(context.attributes))
                    .frame(width: 14, height: 14)
                    .padding(.leading, 8)

            } compactTrailing: {
                // 일치율 % (Compact Trailing)
                Text("\(context.state.matchPercent)%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(missionColor(context.attributes))
                    .padding(.trailing, 8)

            } minimal: {
                // 최소화 모드 (작은 원형 컬러칩)
                Circle()
                    .fill(missionColor(context.attributes))
                    .frame(width: 12, height: 12)
            }
            .contentMargins(.all, 0, for: .minimal)
        }
    }

    private func missionColor(_ attrs: ColorPickerAttributes) -> Color {
        Color(red: attrs.red, green: attrs.green, blue: attrs.blue)
    }
}

// MARK: - Lock Screen Banner

private struct LockScreenBannerView: View {
    let state: ColorPickerAttributes.ContentState
    let attrs: ColorPickerAttributes

    private var color: Color { Color(red: attrs.red, green: attrs.green, blue: attrs.blue) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                // 타이머 종료 여부에 따른 타이틀 변경
                Text(state.isExpired ? "당신의 색상을 담아보세요." : "지금 주변의 색을 찾아보세요! 🔍")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                // 3분 전이고 타이머가 있을 때만 카운트다운 표시
                if let timerEnd = state.timerEnd, !state.isExpired {
                    HStack(spacing: 6) {
                        Text("목표 색상 \(attrs.missionHex)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(color)
                        Text("·")
                            .foregroundColor(.white.opacity(0.35))
                        Text(timerInterval: Date()...timerEnd, countsDown: true, showsHours: false)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .monospacedDigit()
                        Text("남음")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.55))
                    }
                } else {
                    // 타이머가 종료되었거나 없는 경우 목표 색상 및 일치율 정보 노출
                    HStack(spacing: 6) {
                        Text("목표 \(attrs.missionHex)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(color)
                        Text("·")
                            .foregroundColor(.white.opacity(0.35))
                        Text("\(state.matchPercent)% 일치 중")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
            }

            Spacer()

            // 컬러 칩 (BeReal의 카메라 아이콘 역할)
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                .frame(width: 56, height: 56)
                .overlay(
                    Text(attrs.missionHex.replacingOccurrences(of: "#", with: ""))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                )
                .shadow(color: color.opacity(0.5), radius: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Match Progress Bar

private struct MatchProgressBar: View {
    let percent: Int
    let barColor: Color
    let missionHex: String

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("목표 색상 \(missionHex)까지")
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
        missionHex: "#5B8DEF",
        red: 0.36, green: 0.55, blue: 0.94
    )
}

extension ColorPickerAttributes.ContentState {
    fileprivate static let timed = ColorPickerAttributes.ContentState(matchPercent: 42, timerEnd: Date().addingTimeInterval(120), isExpired: false)
    fileprivate static let notimed = ColorPickerAttributes.ContentState(matchPercent: 96, timerEnd: nil, isExpired: false)
}

#Preview("Notification", as: .content, using: ColorPickerAttributes.preview) {
    ColorWalkWidgetLiveActivity()
} contentStates: {
    ColorPickerAttributes.ContentState.timed
    ColorPickerAttributes.ContentState.notimed
}
