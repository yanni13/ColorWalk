//
//  GlassView.swift
//  ColorWalk
//
//  blur + dim 오버레이 기본 뷰.
//  CardGlassOverlayView, GlassPillButton, 페이지 카운터 등에서 공통 사용.
//

import UIKit
import SnapKit

final class GlassView: UIView {

    enum DimStyle {
        /// 밝은 유리 — #FFFFFF15 (버튼, 카운터 배경)
        case light
        /// 어두운 유리 — #0D0D0D88 (카드 오버레이)
        case dark
    }

    private let blurView: UIVisualEffectView
    private let dimView = UIView()

    init(dimStyle: DimStyle = .dark, cornerRadius: CGFloat = 0) {
        let blurStyle: UIBlurEffect.Style = dimStyle == .light
            ? .systemUltraThinMaterial
            : .systemUltraThinMaterialDark
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))

        super.init(frame: .zero)

        layer.cornerRadius = cornerRadius
        clipsToBounds = true
        isUserInteractionEnabled = false

        dimView.backgroundColor = dimStyle == .light
            ? UIColor.white.withAlphaComponent(0.082)           // #FFFFFF15
            : UIColor(red: 0.051, green: 0.051, blue: 0.051, alpha: 0.533) // #0D0D0D88

        addSubview(blurView)
        addSubview(dimView)
        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        dimView.snp.makeConstraints  { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }
}
