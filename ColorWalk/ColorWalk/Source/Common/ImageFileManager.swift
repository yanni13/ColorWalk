import UIKit
import CoreLocation
import ImageIO

final class ImageFileManager {
    static let shared = ImageFileManager()
    private init() {}

    func jpegDataWithGPS(from image: UIImage, coordinate: CLLocationCoordinate2D) -> Data? {
        guard let cgImage = image.cgImage else { return image.jpegData(compressionQuality: 0.8) }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData, "public.jpeg" as CFString, 1, nil
        ) else { return image.jpegData(compressionQuality: 0.8) }

        let gpsProperties: [CFString: Any] = [
            kCGImagePropertyGPSLatitude:     abs(coordinate.latitude),
            kCGImagePropertyGPSLatitudeRef:  coordinate.latitude  >= 0 ? "N" : "S",
            kCGImagePropertyGPSLongitude:    abs(coordinate.longitude),
            kCGImagePropertyGPSLongitudeRef: coordinate.longitude >= 0 ? "E" : "W"
        ]

        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: gpsProperties,
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]

        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return image.jpegData(compressionQuality: 0.8)
        }
        return mutableData as Data
    }

    func saveImage(image: UIImage, fileName: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            // 원본은 앱 화면에서만 읽으므로(위젯은 App Group 썸네일 사용) 잠금 상태에서는 새로 열 수 없게 보호
            try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
            FileProtectionInspector.printReport()
#if DEBUG
print(
    "[FileProtection] \(url.lastPathComponent): " +
    FileProtectionInspector.protection(of: url)
)
#endif
            return fileName
        } catch {
            return nil
        }
    }

    func deleteImage(fileName: String) {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func getImageUrl(fileName: String) -> URL {
        return getDocumentsDirectory().appendingPathComponent(fileName)
    }
    
    func loadImage(fileName: String) -> UIImage? {
        let url = getImageUrl(fileName: fileName)
        return UIImage(contentsOfFile: url.path)
    }

    func loadThumbnail(fileName: String, size: CGSize) -> UIImage? {
        let url = getImageUrl(fileName: fileName) as CFURL
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height) * UIScreen.main.scale
        ]
        
        guard let source = CGImageSourceCreateWithURL(url, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: image)
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// 기존 Documents 사진 파일에 보호 속성을 적용하고 검증
    func migrateExistingImages() -> (total: Int, succeeded: Int, failed: [String]) {
        let fileManager = FileManager.default
        let directory = getDocumentsDirectory()

        let files: [URL]

        do {
            files = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey]
            ).filter { url in
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
                return values?.isRegularFile == true
                    && ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased())
            }
        } catch {
            print("[Migration] 디렉터리 조회 실패: \(error)")
            return (0, 0, ["디렉터리 조회 실패: \(error.localizedDescription)"])
        }

        var succeeded = 0
        var failed: [String] = []

        for url in files {
            do {
                // 기존 파일에 보호 속성 적용
                try fileManager.setAttributes(
                    [.protectionKey: FileProtectionType.completeUnlessOpen],
                    ofItemAtPath: url.path
                )

                // 실제 속성을 다시 조회해 검증
                let attributes = try fileManager.attributesOfItem(atPath: url.path)

                guard let protection = attributes[.protectionKey] as? FileProtectionType,
                      protection == .completeUnlessOpen else {
                    failed.append("\(url.lastPathComponent): 보호 속성 불일치")
                    continue
                }

                succeeded += 1
            } catch {
                failed.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        print("""
        [Migration] 기존 사진 보호 속성 점검
        전체: \(files.count)
        성공: \(succeeded)
        실패: \(failed.count)
        실패 목록: \(failed)
        """)

        return (files.count, succeeded, failed)
    }
}
