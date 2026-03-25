import MapKit
import UIKit
import SnapKit

// MARK: - Individual Photo Pin (Single Marker)

final class PhotoAnnotationView: MKAnnotationView {
    static let reuseId = "PhotoAnnotationView"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor.App.bgSecondary
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        iv.layer.borderWidth = 2.5
        iv.layer.borderColor = UIColor.white.cgColor
        return iv
    } ()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "photo"
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        centerOffset = CGPoint(x: 0, y: -30)

        addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    override var annotation: MKAnnotation? {
        didSet { updateAppearance() }
    }

    private func updateAppearance() {
        guard let ann = annotation as? PhotoAnnotation else { return }
        let photo = ann.photo
        if !photo.imagePath.isEmpty, let image = UIImage(contentsOfFile: photo.imagePath) {
            imageView.image = image
            imageView.backgroundColor = nil
        } else {
            imageView.image = nil
            imageView.backgroundColor = UIColor(hex: photo.capturedHex)
        }
    }
}

// MARK: - Cluster Badge (Photo with Count Badge - MjQxm)

final class PhotoClusterAnnotationView: MKAnnotationView {
    static let reuseId = "PhotoClusterAnnotationView"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor.App.bgSecondary
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        iv.layer.borderWidth = 2.5
        iv.layer.borderColor = UIColor.white.cgColor
        return iv
    } ()

    private let badgeView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.App.accentBlue
        v.layer.cornerRadius = 11
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.18
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    private let badgeIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "camera.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = UIFont(name: "Inter-Bold", size: 11) ?? .boldSystemFont(ofSize: 11)
        l.textAlignment = .center
        return l
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        centerOffset = CGPoint(x: 0, y: -30)

        addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        addSubview(badgeView)
        badgeView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(-8)
            $0.centerX.equalTo(imageView.snp.trailing).offset(-10)
            $0.height.equalTo(22)
            $0.width.greaterThanOrEqualTo(38)
        }

        badgeView.addSubview(badgeIcon)
        badgeIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(12)
        }

        badgeView.addSubview(countLabel)
        countLabel.snp.makeConstraints {
            $0.leading.equalTo(badgeIcon.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().offset(-8)
            $0.centerY.equalToSuperview()
        }

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    override var annotation: MKAnnotation? {
        didSet { updateAppearance() }
    }

    private func updateAppearance() {
        guard let cluster = annotation as? MKClusterAnnotation else { return }
        let members = cluster.memberAnnotations.compactMap { $0 as? PhotoAnnotation }
        countLabel.text = "\(cluster.memberAnnotations.count)"

        if let first = members.first {
            let photo = first.photo
            if !photo.imagePath.isEmpty, let image = UIImage(contentsOfFile: photo.imagePath) {
                imageView.image = image
                imageView.backgroundColor = nil
            } else {
                imageView.image = nil
                imageView.backgroundColor = UIColor(hex: photo.capturedHex)
            }
        }
    }
}
