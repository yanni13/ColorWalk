import MapKit
import UIKit
import SnapKit

// MARK: - Individual Photo Pin (Single Marker)

final class PhotoAnnotationView: MKAnnotationView {
    static let reuseId = "PhotoAnnotationView"

    private let containerView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.18
        v.layer.shadowRadius = 4
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 8
        iv.layer.masksToBounds = true
        return iv
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "photo"
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        centerOffset = CGPoint(x: 0, y: -22)
        backgroundColor = .clear

        addSubview(containerView)
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview().inset(2) }
    }

    override var annotation: MKAnnotation? {
        didSet { updateAppearance() }
    }

    private func updateAppearance() {
        guard let ann = annotation as? PhotoAnnotation else { return }
        let photo = ann.photo
        let accentColor = UIColor(hex: photo.capturedHex)
        containerView.backgroundColor = accentColor

        if !photo.imagePath.isEmpty, let image = UIImage(contentsOfFile: photo.imagePath) {
            imageView.image = image
            imageView.backgroundColor = nil
        } else {
            imageView.image = nil
            imageView.backgroundColor = accentColor.withAlphaComponent(0.25)
        }
    }
}

// MARK: - Cluster Marker (Photo with Count Badge)

final class PhotoClusterAnnotationView: MKAnnotationView {
    static let reuseId = "PhotoClusterAnnotationView"

    private let outerContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 23 
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.18
        v.layer.shadowRadius = 4
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor.App.bgSecondary
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        return iv
    }()

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
        frame = CGRect(x: 0, y: 0, width: 62, height: 62)
        centerOffset = CGPoint(x: 0, y: -31)
        backgroundColor = .clear

        addSubview(outerContainer)
        outerContainer.snp.makeConstraints { $0.edges.equalToSuperview() }

        outerContainer.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview().inset(3) }

        addSubview(badgeView)
        badgeView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(-8)
            $0.trailing.equalToSuperview().offset(8)
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
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
        }
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
