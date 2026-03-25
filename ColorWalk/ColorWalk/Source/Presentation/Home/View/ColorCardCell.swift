//
//  ColorCardCell.swift
//  ColorWalk
//

import UIKit
import SnapKit
import Kingfisher

final class ColorCardCell: UICollectionViewCell {

    static let reuseID = "ColorCardCell"

    // MARK: - UI

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#E5E8EB")
        return iv
    }()

    // Glass overlay — blur + dark tint
    private let blurView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        return v
    }()

    private let overlayTint: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.05, alpha: 0.33)
        return v
    }()

    // Color row: dot + name
    private let colorDot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 5
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.27).cgColor
        return v
    }()

    private let colorNameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 16) ?? .boldSystemFont(ofSize: 16)
        l.textColor = UIColor(hex: "#F5F4F2")
        return l
    }()

    private lazy var colorRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [colorDot, colorNameLabel])
        s.axis = .horizontal
        s.spacing = 6
        s.alignment = .center
        return s
    }()

    // Hex badge row: hex · date
    private let hexLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        l.textColor = UIColor.white.withAlphaComponent(0.6)
        return l
    }()

    private let separatorDot: UILabel = {
        let l = UILabel()
        l.text = "·"
        l.font = UIFont(name: "Pretendard-Regular", size: 11) ?? .systemFont(ofSize: 11)
        l.textColor = UIColor.white.withAlphaComponent(0.27)
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 11) ?? .systemFont(ofSize: 11)
        l.textColor = UIColor.white.withAlphaComponent(0.4)
        return l
    }()

    private lazy var hexBadgeRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [hexLabel, separatorDot, dateLabel])
        s.axis = .horizontal
        s.spacing = 4
        s.alignment = .center
        return s
    }()

    // Location row: pin icon + location
    private let locationIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "mappin")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 10, weight: .regular))
        iv.tintColor = UIColor.white.withAlphaComponent(0.34)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 10) ?? .systemFont(ofSize: 10)
        l.textColor = UIColor.white.withAlphaComponent(0.33)
        return l
    }()

    private lazy var locationRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [locationIcon, locationLabel])
        s.axis = .horizontal
        s.spacing = 4
        s.alignment = .center
        return s
    }()

    // Content stack inside glass overlay
    private lazy var contentStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [colorRow, hexBadgeRow, locationRow])
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .leading
        return s
    }()

    private let glassContainer = UIView()

    // Match badge (top-right)
    private let matchBadge: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 12) ?? .boldSystemFont(ofSize: 12)
        l.textColor = .white
        l.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        l.layer.cornerRadius = 10
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 32
        layer.shadowOpacity = 0.38

        contentView.addSubview(imageView)
        contentView.addSubview(glassContainer)
        glassContainer.addSubview(blurView)
        glassContainer.addSubview(overlayTint)
        glassContainer.addSubview(contentStack)
        contentView.addSubview(matchBadge)

        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        glassContainer.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        overlayTint.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(18)
            $0.trailing.equalToSuperview().inset(18)
            $0.bottom.equalToSuperview().inset(14)
        }

        colorDot.snp.makeConstraints { $0.width.height.equalTo(10) }
        locationIcon.snp.makeConstraints { $0.width.height.equalTo(10) }

        matchBadge.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.trailing.equalToSuperview().inset(14)
            $0.height.equalTo(20)
        }
    }

    // MARK: - Configure

    func configure(with card: ColorCard) {
        if let capturedImage = card.capturedImage {
            imageView.image = capturedImage
        } else if let url = card.imageURL {
            imageView.kf.setImage(with: url)
        }

        colorDot.backgroundColor = card.dotColor
        colorNameLabel.text = card.colorName
        hexLabel.text = card.hexColor
        dateLabel.text = card.captureDate
        locationLabel.text = card.locationName

        matchBadge.text = "  \(card.matchPercentage)%  "
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.kf.cancelDownloadTask()
    }
}
