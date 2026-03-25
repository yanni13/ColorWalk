//
//  ColorDetectPillView.swift
//  ColorWalk
//

import UIKit
import SnapKit

final class ColorDetectPillView: UIView {

    // MARK: - Subviews

    private let colorDot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.backgroundColor = UIColor(hex: "#5B8DEF")
        return v
    }()

    private let hexLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-SemiBold", size: 13) ?? .monospacedSystemFont(ofSize: 13, weight: .semibold)
        l.textColor = .white
        l.text = "#5B8DEF"
        return l
    }()

    private let matchLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 12) ?? .systemFont(ofSize: 12)
        l.textColor = UIColor.white.withAlphaComponent(0.65)
        l.text = "99% 일치"
        return l
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        layer.cornerRadius = 19

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.layer.cornerRadius = 19
        blur.clipsToBounds = true
        insertSubview(blur, at: 0)

        [colorDot, hexLabel, matchLabel].forEach { addSubview($0) }

        blur.snp.makeConstraints { $0.edges.equalToSuperview() }

        colorDot.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(16)
        }
        hexLabel.snp.makeConstraints {
            $0.leading.equalTo(colorDot.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }
        matchLabel.snp.makeConstraints {
            $0.leading.equalTo(hexLabel.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
        }
    }

    // MARK: - Update

    func update(color: UIColor, hex: String, match: Int) {
        colorDot.backgroundColor = color
        hexLabel.text = hex
        matchLabel.text = "\(match)% 일치"
    }
}
