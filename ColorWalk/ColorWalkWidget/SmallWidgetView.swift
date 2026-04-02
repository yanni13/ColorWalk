import SwiftUI
import WidgetKit

// MARK: - Small Widget (systemSmall)
// 디자인: 전체 사진 배경 + 우상단 날짜 뱃지 + 하단 색상 dot + hex 코드

struct SmallWidgetView: View {

    let entry: ColorWalkEntry

    private var photo: WidgetPhotoInfo? { entry.dailyData.photos.first }
    private var hex: String { photo?.capturedHex ?? entry.dailyData.missionColorHex }

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
            dateBadge
            bottomOverlay
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if let photoInfo = photo,
           let image = WidgetDataStore.shared.loadImage(fileName: photoInfo.imageFileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Color(hex: entry.dailyData.missionColorHex)
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.3))
                )
        }
    }

    // MARK: - Date Badge

    private var dateBadge: some View {
        Text(entry.dailyData.dateString)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(10)
    }

    // MARK: - Bottom Overlay

    private var bottomOverlay: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
            Text(hex.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .black.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }
}
