//
//  AppTag.swift
//  ColorWalk
//
//  디자인 시스템 태그 — Tag/Weather (아이콘 + 텍스트 pill)
//

import UIKit
import SnapKit

final class AppTag: UIView {

    private let iconView = UIImageView()
    private let label    = UILabel()

    /// - Parameters:
    ///   - icon: SF Symbol 이름
    ///   - text: 태그 텍스트
    ///   - tintColor: 아이콘·텍스트 색 (기본 accentBlue)
    ///   - bgColor: 배경색 (기본 #EBF2FF)
    init(icon: String,
         text: String,
         tintColor: UIColor = UIColor.App.accentBlue,
         bgColor: UIColor = UIColor(hex: "#EBF2FF")) {
        super.init(frame: .zero)

        iconView.image = UIImage(systemName: icon)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
        iconView.tintColor = tintColor
        iconView.contentMode = .scaleAspectFit

        label.text = text
        label.font = UIFont(name: "Pretendard-Medium", size: 12) ?? .systemFont(ofSize: 12, weight: .medium)
        label.textColor = tintColor

        backgroundColor = bgColor
        layer.cornerRadius = 100

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        addSubview(stack)

        stack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(6)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        iconView.snp.makeConstraints { $0.width.height.equalTo(14) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(text: String) { label.text = text }
    func update(icon: String) {
        iconView.image = UIImage(systemName: icon)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
    }
}
