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
            try data.write(to: url)
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
}
