//
//  PaginationView.swift
//  ColorWalk
//

import UIKit
import SnapKit

final class PaginationView: UIView {

    private var dotViews: [UIView] = []
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(count: Int) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        dotViews = (0..<count).map { _ in makeDot(active: false) }
        dotViews.forEach { stackView.addArrangedSubview($0) }
        setActive(index: 0)
    }

    func setActive(index: Int) {
        dotViews.enumerated().forEach { i, dot in
            let isActive = i == index
            // 제약 업데이트는 애니메이션 블록 밖에서
            dot.snp.updateConstraints {
                $0.width.equalTo(isActive ? 8 : 6)
                $0.height.equalTo(isActive ? 8 : 6)
            }
            dot.layer.cornerRadius = isActive ? 4 : 3
            dot.backgroundColor = isActive
                ? UIColor(hex: "#191F28")
                : UIColor(hex: "#B0B8C1")
        }
        // layoutIfNeeded()를 애니메이션 블록 안에서 호출해야 크기 변경이 애니메이션됨
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            self.stackView.layoutIfNeeded()
        }
    }

    private func makeDot(active: Bool) -> UIView {
        let v = UIView()
        let size: CGFloat = active ? 8 : 6
        v.backgroundColor = active ? UIColor(hex: "#191F28") : UIColor(hex: "#B0B8C1")
        v.layer.cornerRadius = size / 2
        v.snp.makeConstraints {
            $0.width.equalTo(size)
            $0.height.equalTo(size)
        }
        return v
    }
}
