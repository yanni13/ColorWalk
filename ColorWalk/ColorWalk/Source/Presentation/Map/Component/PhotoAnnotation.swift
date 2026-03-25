import MapKit

final class PhotoAnnotation: NSObject, MKAnnotation {
    let photo: Photo

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: photo.latitude, longitude: photo.longitude)
    }

    var title: String? { photo.capturedHex }

    init(photo: Photo) {
        self.photo = photo
    }
}
