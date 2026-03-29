import MapKit
import UIKit
import SnapKit
import Kingfisher

// MARK: - Individual Photo Pin (Single Marker)

final class PhotoAnnotationView: MKAnnotationView {
    static let reuseId = "PhotoAnnotationView"

    private let containerView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.18
        v.layer.shadowRadius = 4
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 12
        iv.layer.masksToBounds = true
        return iv
    }()

    private let badgeView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.12
        v.layer.shadowRadius = 4
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.isHidden = true

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.layer.cornerRadius = 10
        blur.clipsToBounds = true
        
        let whiteOverlay = UIView()
        whiteOverlay.backgroundColor = UIColor.white.withAlphaComponent(0.65)
        whiteOverlay.layer.cornerRadius = 10
        whiteOverlay.clipsToBounds = true

        v.addSubview(blur)
        v.addSubview(whiteOverlay)
        blur.snp.makeConstraints { $0.edges.equalToSuperview() }
        whiteOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        return v
    }()

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.App.accentBlue
        l.font = UIFont(name: "Inter-Bold", size: 10) ?? .boldSystemFont(ofSize: 10)
        l.textAlignment = .center
        return l
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "photo"
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        centerOffset = CGPoint(x: 0, y: -30)
        backgroundColor = .clear

        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(2)
        }

        addSubview(badgeView)
        badgeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-6)
            make.trailing.equalToSuperview().offset(6)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(20)
        }

        badgeView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5))
        }
    }

    override var annotation: MKAnnotation? {
        didSet { updateAppearance() }
    }

    private func updateAppearance() {
        guard let ann = annotation as? PhotoAnnotation else { return }
        let photo = ann.photo
        let targetColor = UIColor(hex: ann.targetHex ?? photo.capturedHex)
        let capturedColor = UIColor(hex: photo.capturedHex)

        containerView.backgroundColor = targetColor
        imageView.backgroundColor = capturedColor

        let count = ann.photos.count
        badgeView.isHidden = count <= 1
        badgeLabel.text = "\(count)"

        guard !photo.imagePath.isEmpty else { return }

        if photo.imagePath.hasPrefix("http"), let url = URL(string: photo.imagePath) {
            imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            imageView.image = ImageFileManager.shared.loadImage(fileName: photo.imagePath)
            imageView.backgroundColor = nil
        }
    }
}

// MARK: - Cluster Marker (Photo with Count Badge)

final class PhotoClusterAnnotationView: MKAnnotationView {
    static let reuseId = "PhotoClusterAnnotationView"

    private let outerContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 26
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
        iv.layer.cornerRadius = 23
        iv.layer.masksToBounds = true
        return iv
    }()

    private let badgeView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 11
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.12
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.layer.cornerRadius = 11
        blur.clipsToBounds = true
        
        let whiteOverlay = UIView()
        whiteOverlay.backgroundColor = UIColor.white.withAlphaComponent(0.65)
        whiteOverlay.layer.cornerRadius = 11
        whiteOverlay.clipsToBounds = true

        v.addSubview(blur)
        v.addSubview(whiteOverlay)
        blur.snp.makeConstraints { $0.edges.equalToSuperview() }
        whiteOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        return v
    }()

    private let badgeIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "camera.fill"))
        iv.tintColor = UIColor.App.accentBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.App.accentBlue
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
        frame = CGRect(x: 0, y: 0, width: 68, height: 68)
        centerOffset = CGPoint(x: 0, y: -34)
        backgroundColor = .clear

        addSubview(outerContainer)
        outerContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        outerContainer.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(3)
        }

        addSubview(badgeView)
        badgeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-8)
            make.trailing.equalToSuperview().offset(8)
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(38)
        }

        badgeView.addSubview(badgeIcon)
        badgeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }

        badgeView.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(badgeIcon.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
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
            let targetColor = UIColor(hex: first.targetHex ?? photo.capturedHex)
            let capturedColor = UIColor(hex: photo.capturedHex)

            outerContainer.backgroundColor = targetColor
            imageView.backgroundColor = capturedColor

            if !photo.imagePath.isEmpty {
                if photo.imagePath.hasPrefix("http"), let url = URL(string: photo.imagePath) {
                    imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
                } else {
                    imageView.image = ImageFileManager.shared.loadImage(fileName: photo.imagePath)
                    imageView.backgroundColor = nil
                }
            }
        }
    }
}
