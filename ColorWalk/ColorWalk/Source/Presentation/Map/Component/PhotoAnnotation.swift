import MapKit

final class PhotoAnnotation: NSObject, MKAnnotation {
    let photo: Photo
    let targetHex: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: photo.latitude, longitude: photo.longitude)
    }

    var title: String? { photo.capturedHex }

    init(photo: Photo, targetHex: String? = nil) {
        self.photo = photo
        self.targetHex = targetHex
    }
}
