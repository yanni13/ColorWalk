import UIKit
import SnapKit

final class NearbyPhotoCell: UICollectionViewCell {
    static let reuseId = "NearbyPhotoCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with photo: Photo) {
        if !photo.imagePath.isEmpty, let image = UIImage(contentsOfFile: photo.imagePath) {
            imageView.image = image
            imageView.backgroundColor = nil
        } else {
            imageView.image = nil
            imageView.backgroundColor = UIColor(hex: photo.capturedHex)
        }
    }
}
