//
//  CardGlassOverlayView.swift
//  ColorWalk
//

import UIKit
import SnapKit

final class CardGlassOverlayView: UIView {

    // MARK: - UI

    private let glassView = GlassView(dimStyle: .dark)

    private let colorDotView = ColorDotView(
        size: 14,
        borderColor: UIColor.white.withAlphaComponent(0.267),
        borderWidth: 1
    )

    private let colorNameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 22)
        l.textColor = UIColor(hex: "#F5F4F2")
        return l
    }()

    private lazy var colorRowStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [colorDotView, colorNameLabel])
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        return s
    }()

    // hexBadge: hex · date
    private let hexTextLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor.white.withAlphaComponent(0.6)
        return l
    }()

    private let dotSeparatorLabel: UILabel = {
        let l = UILabel()
        l.text = "·"
        l.font = UIFont(name: "Pretendard-Regular", size: 14)
        l.textColor = UIColor.white.withAlphaComponent(0.267)
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
        l.textColor = UIColor.white.withAlphaComponent(0.4)
        return l
    }()

    private lazy var hexBadgeStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [hexTextLabel, dotSeparatorLabel, dateLabel])
        s.axis = .horizontal
        s.spacing = 6
        s.alignment = .center
        return s
    }()

    // locationRow: icon + text
    private let locationIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "mappin")
        iv.tintColor = UIColor.white.withAlphaComponent(0.267)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 12)
        l.textColor = UIColor.white.withAlphaComponent(0.333)
        return l
    }()

    private lazy var locationRowStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [locationIconView, locationLabel])
        s.axis = .horizontal
        s.spacing = 6
        s.alignment = .center
        return s
    }()

    // main vertical stack
    private lazy var mainStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [colorRowStack, hexBadgeStack, locationRowStack])
        s.axis = .vertical
        s.spacing = 8
        return s
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(glassView)
        addSubview(mainStack)
    }

    private func setupConstraints() {
        glassView.snp.makeConstraints { $0.edges.equalToSuperview() }

        locationIconView.snp.makeConstraints {
            $0.width.height.equalTo(12)
        }

        // AFc3C padding: [20, 24, 24, 24]
        mainStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.bottom.equalToSuperview().inset(24)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().inset(24)
        }
    }

    // MARK: - Configure

    func configure(card: ColorCard) {
        colorDotView.setColor(card.dotColor)

        let nameAttr = NSMutableAttributedString(string: card.colorName)
        nameAttr.addAttribute(.kern, value: -0.3, range: NSRange(location: 0, length: card.colorName.count))
        colorNameLabel.attributedText = nameAttr

        hexTextLabel.text = card.hexColor
        dateLabel.text = card.captureDate
        locationLabel.text = card.locationName
    }

    func updateLocationVisibility(_ authorized: Bool) {
        locationRowStack.isHidden = !authorized
    }
}
