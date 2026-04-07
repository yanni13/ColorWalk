//
//  CameraFilterStripView.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CameraFilterStripView: UIView {

    // MARK: - Public
    let selectedFilter = BehaviorRelay<CameraFilter>(value: .normal)

    // MARK: - Private
    private var buttons: [UIButton] = []
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        scrollView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            $0.height.equalToSuperview()
        }

        CameraFilter.allCases.enumerated().forEach { idx, filter in
            let btn = makeButton(filter, tag: idx)
            buttons.append(btn)
            stack.addArrangedSubview(btn)
        }
        applySelection(.normal)
    }

    private func makeButton(_ filter: CameraFilter, tag: Int) -> UIButton {
        var cfg = UIButton.Configuration.plain()
        cfg.background.cornerRadius = 15
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)

        var title = AttributedString(filter.displayName)
        title.font = UIFont(name: "Pretendard-Medium", size: 13) ?? .systemFont(ofSize: 13)
        cfg.attributedTitle = title
        cfg.baseForegroundColor = .white

        let b = UIButton(configuration: cfg)
        b.tag = tag
        b.addTarget(self, action: #selector(didTap(_:)), for: .touchUpInside)
        return b
    }

    @objc private func didTap(_ sender: UIButton) {
        let filter = CameraFilter.allCases[sender.tag]
        selectedFilter.accept(filter)
        applySelection(filter)
    }

    private func applySelection(_ selected: CameraFilter) {
        zip(buttons, CameraFilter.allCases).forEach { btn, filter in
            let on = filter == selected
            var cfg = btn.configuration
            cfg?.background.backgroundColor = on ? .white : UIColor.white.withAlphaComponent(0.15)
            cfg?.baseForegroundColor = on ? UIColor(hex: "#191F28") : UIColor.white.withAlphaComponent(0.8)
            btn.configuration = cfg
        }
    }
}
