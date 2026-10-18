#if DEBUG
import Foundation

/// 저장된 사진·스티커·위젯 썸네일의 Data Protection 클래스를 콘솔에 출력하는 디버그 전용 점검 도구
enum FileProtectionInspector {

    private enum Constants {
        static let appGroupID = "group.com.yanni13.ColorWalk"
        static let widgetImageDirName = "WidgetImages"
        static let stickerDirName = "stickers"
        static let imageExtensions: Set<String> = ["jpg", "jpeg", "png"]
        static let maxFilesPerGroup = 8
    }

    static func printReport() {
        let fm = FileManager.default
        let documents = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let widgetDir = fm.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID)?
            .appendingPathComponent(Constants.widgetImageDirName)

        print("===== [FileProtection] 파일 보호 클래스 점검 =====")
        printGroup(title: "원본 사진 (Documents)", directory: documents)
        printGroup(title: "스티커 (Documents/stickers)", directory: documents.appendingPathComponent(Constants.stickerDirName))
        if let widgetDir {
            printGroup(title: "위젯 썸네일 (App Group/WidgetImages)", directory: widgetDir)
            let excluded = (try? widgetDir.resourceValues(forKeys: [.isExcludedFromBackupKey]))?.isExcludedFromBackup
            print("  └ 폴더 iCloud 백업 제외: \(excluded.map { $0 ? "YES" : "NO" } ?? "확인 불가")")
        }
        print("  Realm DB: \(protection(of: documents.appendingPathComponent("default.realm")))")
        print("=================================================")
    }

    private static func printGroup(title: String, directory: URL) {
        let fm = FileManager.default
        let files = ((try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])) ?? [])
            .filter { Constants.imageExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { creationDate($0) > creationDate($1) }

        print("▸ \(title): \(files.count)개")
        for file in files.prefix(Constants.maxFilesPerGroup) {
            print("  \(file.lastPathComponent.prefix(18))…  \(protection(of: file))")
        }
        if files.count > Constants.maxFilesPerGroup {
            print("  … 외 \(files.count - Constants.maxFilesPerGroup)개")
        }
    }

    internal static func protection(of url: URL) -> String {
        do {
            let attrs = try FileManager.default.attributesOfItem(
                atPath: url.path
            )

            guard let value = attrs[.protectionKey] else {
                return "보호 속성값 없음 (기본 정책 확인 필요)"
            }

            guard let type = value as? FileProtectionType else {
                return "보호 속성 타입 확인 불가: \(value)"
            }

            return type.rawValue
        } catch {
            return "속성 조회 실패: \(error.localizedDescription)"
        }
    }

    private static func creationDate(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
    }
}
#endif
