import SwiftUI
import WidgetKit

// MARK: - Large Widget (systemLarge)
// 디자인: 전체 사진 배경 + 좌상단 날짜 뱃지 + 하단 색상 팔레트 (최대 3개)

struct LargeWidgetView: View {

    let entry: ColorWalkEntry

    private var photos: [WidgetPhotoInfo] { Array(entry.dailyData.photos.prefix(3)) }
    private var mainPhoto: WidgetPhotoInfo? { photos.first }

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
            dateBadge
            if !photos.isEmpty {
                paletteBar
            } else {
                emptyState
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if let photoInfo = mainPhoto,
           let image = WidgetDataStore.shared.loadImage(fileName: photoInfo.imageFileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            LinearGradient(
                colors: [
                    Color(hex: entry.dailyData.missionColorHex),
                    Color(hex: entry.dailyData.missionColorHex).opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Date Badge

    private var dateBadge: some View {
        Text(entry.dailyData.dateString)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
    }

    // MARK: - Palette Bar

    private var paletteBar: some View {
        HStack(spacing: 0) {
            ForEach(photos, id: \.imageFileName) { photoInfo in
                ColorPaletteItem(photoInfo: photoInfo)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "camera.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))
            Text("색상을 촬영해보세요")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Palette Item

private struct ColorPaletteItem: View {

    let photoInfo: WidgetPhotoInfo

    var body: some View {
        VStack(spacing: 5) {
            Circle()
                .fill(Color(hex: photoInfo.capturedHex))
                .frame(width: 20, height: 20)
                .shadow(color: Color(hex: photoInfo.capturedHex).opacity(0.5), radius: 4)
                .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 1))
            Text(photoInfo.colorName)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}
