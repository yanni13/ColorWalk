import UIKit
import SnapKit
import Kingfisher

final class NearbyPhotoCell: UICollectionViewCell {
    static let reuseId = "NearbyPhotoCell"

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 23
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.12
        v.layer.shadowRadius = 12
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        return v
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(3) 
        }
    }

    func configure(with photo: Photo) {
        imageView.backgroundColor = UIColor(hex: photo.capturedHex)

        guard !photo.imagePath.isEmpty else { return }

        if photo.imagePath.hasPrefix("http"), let url = URL(string: photo.imagePath) {
            imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            imageView.image = ImageFileManager.shared.loadImage(fileName: photo.imagePath)
            imageView.backgroundColor = nil
        }
    }
}
