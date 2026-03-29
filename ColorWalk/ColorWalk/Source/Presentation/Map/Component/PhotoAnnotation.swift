import MapKit

final class PhotoAnnotation: NSObject, MKAnnotation {
    let photos: [Photo]
    let targetHex: String?

    var photo: Photo { photos[0] }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: photo.latitude, longitude: photo.longitude)
    }

    var title: String? { photo.capturedHex }

    init(photos: [Photo], targetHex: String? = nil) {
        self.photos = photos
        self.targetHex = targetHex
    }
}
