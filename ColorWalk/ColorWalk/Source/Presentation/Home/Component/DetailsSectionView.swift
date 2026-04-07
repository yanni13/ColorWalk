//
//  DetailsSectionView.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class DetailsSectionView: UIView {

    // MARK: - Observables
    var shareTap: Observable<Void> { shareButton.rx.tap.asObservable() }
    var saveTap: Observable<Void> { saveButton.rx.tap.asObservable() }

    // MARK: - Match Row
    private let matchLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.detailsColorAccuracy
        l.font = UIFont(name: "Pretendard-Medium", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private let matchValueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 13)
        l.textColor = UIColor(hex: "#1A1A1A")
        return l
    }()

    private lazy var matchRow: UIView = makeSpacedRow(left: matchLabel, right: matchValueLabel)

    // MARK: - Progress Bar
    private let progressTrack: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E0E0E0")
        v.layer.cornerRadius = 3
        v.clipsToBounds = true
        return v
    }()

    private let progressFill: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 3
        return v
    }()

    private let progressGradient = CAGradientLayer()

    // MARK: - Mission Row
    private let missionLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.detailsMissionProgress
        l.font = UIFont(name: "Pretendard-Medium", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private let missionBadge: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 100
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
        return v
    }()

    private let missionBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-SemiBold", size: 12)
        l.textColor = UIColor(hex: "#1A1A1A")
        return l
    }()

    private lazy var missionRow: UIView = makeSpacedRow(left: missionLabel, right: missionBadge)

    // MARK: - Divider
    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E0E0E0")
        return v
    }()

    // MARK: - Action Buttons
    private let shareButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = L10n.buttonShare
        config.image = UIImage(systemName: "square.and.arrow.up")
        config.imagePadding = 8
        config.baseForegroundColor = UIColor(hex: "#6B7684")
        config.background.backgroundColor = .white
        config.background.cornerRadius = 12
        config.background.strokeColor = UIColor(hex: "#E0E0E0")
        config.background.strokeWidth = 1
        let b = UIButton(configuration: config)
        return b
    }()

    private let saveButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = L10n.buttonSave
        config.image = UIImage(systemName: "arrow.down.to.line")
        config.imagePadding = 8
        config.baseForegroundColor = .white
        config.background.backgroundColor = UIColor(hex: "#1A1A1A")
        config.background.cornerRadius = 12
        let b = UIButton(configuration: config)
        return b
    }()

    private lazy var actionRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [shareButton, saveButton])
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()

    // MARK: - Main Stack
    private lazy var mainStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [
            matchRow,
            progressTrack,
            missionRow,
            divider,
            actionRow
        ])
        s.axis = .vertical
        s.spacing = 16
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
        addSubview(mainStack)
        progressTrack.addSubview(progressFill)
        missionBadge.addSubview(missionBadgeLabel)

        // Gradient setup
        progressGradient.colors = [
            UIColor(hex: "#3182F6").cgColor,
            UIColor(hex: "#5B9CF6").cgColor
        ]
        progressGradient.startPoint = CGPoint(x: 0, y: 0.5)
        progressGradient.endPoint = CGPoint(x: 1, y: 0.5)
        progressFill.layer.addSublayer(progressGradient)
    }

    private func setupConstraints() {
        mainStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        progressTrack.snp.makeConstraints {
            $0.height.equalTo(6)
        }

        progressFill.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.98) // default 98%
        }

        divider.snp.makeConstraints {
            $0.height.equalTo(1)
        }

        shareButton.snp.makeConstraints {
            $0.height.equalTo(48)
        }

        saveButton.snp.makeConstraints {
            $0.height.equalTo(48)
        }

        missionBadgeLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.trailing.equalToSuperview().inset(10)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressGradient.frame = progressFill.bounds
    }

    // MARK: - Configure

    func setProgress(ratio: Float) {
        let clampedRatio = CGFloat(max(0, min(1, ratio)))
        // multiplier는 읽기 전용 → remakeConstraints로 재생성
        progressFill.snp.remakeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(clampedRatio)
        }
        UIView.animate(withDuration: 0.4) {
            self.progressTrack.layoutIfNeeded()
        }
        matchValueLabel.text = "\(Int(ratio * 100))%"
    }

    func setMission(text: String) {
        missionBadgeLabel.text = text
    }

    // MARK: - Helpers

    private func makeSpacedRow(left: UIView, right: UIView) -> UIView {
        let container = UIView()
        container.addSubview(left)
        container.addSubview(right)
        left.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }
        right.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }
        container.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(20)
        }
        return container
    }
}
