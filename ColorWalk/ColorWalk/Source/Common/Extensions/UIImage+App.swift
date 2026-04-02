import UIKit

extension UIImage {
    /// 이미지를 중앙 기준으로 1:1 비율로 크롭합니다.
    func cropToSquare() -> UIImage? {
        let originalWidth  = size.width
        let originalHeight = size.height
        let edge = min(originalWidth, originalHeight)
        
        let x = (originalWidth - edge) / 2.0
        let y = (originalHeight - edge) / 2.0
        
        let cropRect = CGRect(x: x, y: y, width: edge, height: edge)
        
        guard let imageRef = cgImage?.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
    }
    
    /// 지정된 크기로 이미지 해상도를 조절합니다.
    func resized(to targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // 해상도 고정 (위젯 최적화)
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
