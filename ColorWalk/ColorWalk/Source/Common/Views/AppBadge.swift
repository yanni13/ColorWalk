//
//  AppBadge.swift
//  ColorWalk
//
//  디자인 시스템 배지 — Badge/Status · Badge/Mission
//

import UIKit

enum AppBadgeStyle {
    case status                              // 완료 — 초록
    case mission                             // 3/9  — 보라
    case custom(bg: UIColor, text: UIColor)  // 커스텀
}

final class AppBadge: UILabel {

    private let insets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)

    init(style: AppBadgeStyle, text: String = "") {
        super.init(frame: .zero)
        self.text = text
        font = UIFont(name: "Pretendard-SemiBold", size: 11) ?? .systemFont(ofSize: 11, weight: .semibold)
        textAlignment = .center
        layer.cornerRadius = 100
        layer.masksToBounds = true

        switch style {
        case .status:
            backgroundColor = UIColor.App.accentGreen
            textColor = .white
        case .mission:
            backgroundColor = UIColor(hex: "#F0EBFF")
            textColor = UIColor.App.accentPurple
        case .custom(let bg, let text):
            backgroundColor = bg
            textColor = text
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}
