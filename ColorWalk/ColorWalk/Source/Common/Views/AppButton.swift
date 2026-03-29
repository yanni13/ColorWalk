//
//  AppButton.swift
//  ColorWalk
//
//  디자인 시스템 버튼 — Primary / Secondary / Ghost / Icon
//

import UIKit
import SnapKit

enum AppButtonStyle {
    case primary
    case secondary
    case destructive
    case ghost
    case icon(String)
}

final class AppButton: UIButton {

    init(style: AppButtonStyle, title: String? = nil) {
        super.init(frame: .zero)

        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)

        switch style {
        case .primary:
            config.background.backgroundColor = UIColor.App.ink
            config.background.cornerRadius = 100
            config.attributedTitle = makeTitle(title, font: "Pretendard-SemiBold", color: .white)

        case .secondary:
            config.background.backgroundColor = .clear
            config.background.cornerRadius = 100
            config.background.strokeColor = UIColor.App.ink
            config.background.strokeWidth = 1.5
            config.attributedTitle = makeTitle(title, font: "Pretendard-SemiBold", color: UIColor.App.ink)

        case .destructive:
            config.background.backgroundColor = .clear
            config.background.cornerRadius = 100
            config.background.strokeColor = UIColor(hex: "#FF4D4F")
            config.background.strokeWidth = 1.5
            config.attributedTitle = makeTitle(title, font: "Pretendard-SemiBold", color: UIColor(hex: "#FF4D4F"))

        case .ghost:
            config.background.backgroundColor = .clear
            config.background.cornerRadius = 100
            config.attributedTitle = makeTitle(title, font: "Pretendard-Medium", color: UIColor.App.textSecondary)

        case .icon(let iconName):
            config.image = UIImage(systemName: iconName)?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
            config.baseForegroundColor = UIColor.App.textPrimary
            config.background.backgroundColor = UIColor.App.bgCard
            config.background.cornerRadius = 22
            config.background.strokeColor = UIColor.App.border
            config.background.strokeWidth = 1
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            snp.makeConstraints { $0.width.height.equalTo(44) }
        }

        configuration = config
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makeTitle(_ text: String?, font: String, color: UIColor) -> AttributedString? {
        guard let text else { return nil }
        var attr = AttributedString(text)
        attr.font = UIFont(name: font, size: 14) ?? .systemFont(ofSize: 14)
        attr.foregroundColor = color
        return attr
    }
}
