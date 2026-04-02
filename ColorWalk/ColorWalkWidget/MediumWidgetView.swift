import SwiftUI
import WidgetKit

// MARK: - Medium Widget (systemMedium)
// 디자인: 좌측 사진 + 우측 미션 색상 정보 (이름, hex, 위치)

struct MediumWidgetView: View {

    let entry: ColorWalkEntry

    private var photo: WidgetPhotoInfo? { entry.dailyData.photos.first }
    private var missionHex: String { entry.dailyData.missionColorHex }
    private var missionName: String { entry.dailyData.missionColorName }

    var body: some View {
        HStack(spacing: 0) {
            photoSection
            infoSection
        }
    }

    // MARK: - Photo

    private var photoSection: some View {
        Group {
            if let photoInfo = photo,
               let image = WidgetDataStore.shared.loadImage(fileName: photoInfo.imageFileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: .infinity)
                    .clipped()
            } else {
                Color(hex: missionHex)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.35))
                    )
            }
        }
        .frame(width: 170)
    }

    // MARK: - Info Panel

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleRow
                .padding(.bottom, 16)
            colorRow
                .padding(.bottom, 8)
            Spacer()
            locationRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }

    private var titleRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("오늘의 색상")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.label))
            Text(entry.dailyData.dateString)
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private var colorRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: missionHex))
                .frame(width: 36, height: 36)
                .shadow(color: Color(hex: missionHex).opacity(0.4), radius: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(missionName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                Text(missionHex.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }

    private var locationRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabel))
            Text(photo?.locationName ?? "산책을 시작해보세요")
                .font(.system(size: 11))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(1)
        }
    }
}
