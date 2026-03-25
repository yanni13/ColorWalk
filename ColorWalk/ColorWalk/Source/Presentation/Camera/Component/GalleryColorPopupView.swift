
//
//  GalleryColorPopupView.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class GalleryColorPopupView: UIView {

    // MARK: - Callbacks
    var onRetry: (() -> Void)?
    var onCollect: (() -> Void)?

    private let disposeBag = DisposeBag()

    // MARK: - UI

    private let emojiLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 36)
        l.textAlignment = .center
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        l.textColor = UIColor(hex: "#1A1A1A")
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Medium", size: 14)
        l.textColor = UIColor(hex: "#999999")
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    // "다시 찾기" — dark primary
    private let retryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("다시 찾기", for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 15) ?? .boldSystemFont(ofSize: 15)
        b.tintColor = .white
        b.backgroundColor = UIColor(hex: "#2A2A2A")
        b.layer.cornerRadius = 14
        return b
    }()

    // "수집하기" — light secondary
    private let collectButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("수집하기", for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 15) ?? .boldSystemFont(ofSize: 15)
        b.tintColor = UIColor(hex: "#1A1A1A")
        b.backgroundColor = .white
        b.layer.cornerRadius = 14
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
        return b
    }()

    private lazy var buttonStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [retryButton, collectButton])
        s.axis = .horizontal
        s.spacing = 10
        s.distribution = .fillEqually
        return s
    }()

    private lazy var contentStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [emojiLabel, titleLabel, descLabel, buttonStack])
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 16
        return s
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = 24
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 32
        layer.shadowOpacity = 0.25

        addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().inset(20)
        }

        buttonStack.snp.makeConstraints { $0.width.equalTo(contentStack) }
        retryButton.snp.makeConstraints { $0.height.equalTo(48) }
        collectButton.snp.makeConstraints { $0.height.equalTo(48) }

        retryButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.onRetry?() })
            .disposed(by: disposeBag)

        collectButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.onCollect?() })
            .disposed(by: disposeBag)
    }

    // MARK: - Configure
    func configure(color: UIColor, hex: String, match: Int) {
        let canCollect = match >= 60

        let emoji: String
        let title: String

        switch match {
        case 80...:
            emoji = "🎯"; title = "딱 맞는 색이네요!"
        case 60..<80:
            emoji = "🎨"; title = "비슷한 색이네요!"
        case 40..<60:
            emoji = "🤔"; title = "좀 다른 색이네요..."
        default:
            emoji = "😅"; title = "많이 다른 색이에요..."
        }

        emojiLabel.text = emoji
        titleLabel.text = title

        if canCollect {
            descLabel.text = "검출 색상: \(hex)\n미션 일치율 \(match)%  · 이대로 수집할까요?"
        } else {
            descLabel.text = "검출 색상: \(hex)\n일치율 \(match)% · 60% 이상이어야 수집할 수 있어요"
        }

        collectButton.isEnabled = canCollect
        collectButton.alpha = canCollect ? 1.0 : 0.35
    }
}
