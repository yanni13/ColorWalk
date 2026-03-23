//
//  GlassPillButton.swift
//  ColorWalk
//
//  44×44 원형 글래스 버튼. Detail 화면 back / share 버튼에 사용.
//

import UIKit
import SnapKit

final class GlassPillButton: UIButton {

    init(icon: String) {
        super.init(frame: .zero)
        layer.cornerRadius = 22
        clipsToBounds = true

        let glass = GlassView(dimStyle: .light)
        glass.isUserInteractionEnabled = false

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        addSubview(glass)
        addSubview(iconView)
        glass.snp.makeConstraints   { $0.edges.equalToSuperview() }
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(22) }
    }

    required init?(coder: NSCoder) { fatalError() }
}
