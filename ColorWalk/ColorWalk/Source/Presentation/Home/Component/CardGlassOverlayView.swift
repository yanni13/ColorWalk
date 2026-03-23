//
//  CardGlassOverlayView.swift
//  ColorWalk
//

import UIKit
import SnapKit

final class CardGlassOverlayView: UIView {

    // MARK: - UI

    private let blurView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        return v
    }()

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.051, green: 0.051, blue: 0.051, alpha: 0.533) // #0D0D0D 88%
        return v
    }()

    // colorRow: dot + name
    private let colorDotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 7   // 14x14 → r=7
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.267).cgColor
        return v
    }()

    private let colorNameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 22)
        l.textColor = UIColor(hex: "#F5F4F2")
        return l
    }()

    private lazy var colorRowStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [colorDotView, colorNameLabel])
        s.axis = .horizontal
        s.spacing = 10   // AFc3C: gap 10
        s.alignment = .center
        return s
    }()

    // hexBadge: hex · date
    private let hexTextLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor.white.withAlphaComponent(0.6)  // #FFFFFF99
        return l
    }()

    private let dotSeparatorLabel: UILabel = {
        let l = UILabel()
        l.text = "·"
        l.font = UIFont(name: "Pretendard-Regular", size: 14)
        l.textColor = UIColor.white.withAlphaComponent(0.267)  // #FFFFFF44
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
        l.textColor = UIColor.white.withAlphaComponent(0.4)   // #FFFFFF66
        return l
    }()

    private lazy var hexBadgeStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [hexTextLabel, dotSeparatorLabel, dateLabel])
        s.axis = .horizontal
        s.spacing = 6   // AFc3C: gap 6
        s.alignment = .center
        return s
    }()

    // locationRow: icon + text
    private let locationIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "mappin")
        iv.tintColor = UIColor.white.withAlphaComponent(0.267)  // #FFFFFF44
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 12)
        l.textColor = UIColor.white.withAlphaComponent(0.333)  // #FFFFFF55
        return l
    }()

    private lazy var locationRowStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [locationIconView, locationLabel])
        s.axis = .horizontal
        s.spacing = 6   // AFc3C: gap 6
        s.alignment = .center
        return s
    }()

    // main vertical stack
    private lazy var mainStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [colorRowStack, hexBadgeStack, locationRowStack])
        s.axis = .vertical
        s.spacing = 8   // AFc3C: gap 8
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
        addSubview(blurView)
        addSubview(dimView)
        addSubview(mainStack)
    }

    private func setupConstraints() {
        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        colorDotView.snp.makeConstraints {
            $0.width.height.equalTo(14)   // AFc3C: 14x14
        }

        locationIconView.snp.makeConstraints {
            $0.width.height.equalTo(12)   // AFc3C: 12x12
        }

        // AFc3C padding: [20, 24, 24, 24] → top 20, right 24, bottom 24, left 24
        mainStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.bottom.equalToSuperview().inset(24)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().inset(24)
        }
    }

    // MARK: - Configure

    func configure(card: ColorCard) {
        colorDotView.backgroundColor = card.dotColor

        let nameAttr = NSMutableAttributedString(string: card.colorName)
        nameAttr.addAttribute(.kern, value: -0.3, range: NSRange(location: 0, length: card.colorName.count))
        colorNameLabel.attributedText = nameAttr

        hexTextLabel.text = card.hexColor
        dateLabel.text = card.captureDate
        locationLabel.text = card.locationName
    }
}
