import UIKit
import SnapKit
import Kingfisher

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
        imageView.backgroundColor = UIColor(hex: photo.capturedHex)

        guard !photo.imagePath.isEmpty else { return }

        if photo.imagePath.hasPrefix("http"), let url = URL(string: photo.imagePath) {
            imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else if let image = UIImage(contentsOfFile: photo.imagePath) {
            imageView.image = image
            imageView.backgroundColor = nil
        }
    }
}
