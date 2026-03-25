//
//  MissionHomeViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MissionHomeViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: MissionHomeViewModel
    var onCameraTap: (() -> Void)?

    // MARK: - UI: Header

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "ColorWalk"
        l.font = UIFont(name: "Pretendard-Bold", size: 28)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "새로운 하루, 새로운 색!"
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var titleStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        s.axis = .vertical
        s.spacing = 2
        s.alignment = .leading
        return s
    }()

    private let bellButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "bell")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#191F28")
        return b
    }()

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E5E8EB")
        v.layer.cornerRadius = 16
        return v
    }()

    private lazy var rightStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [bellButton, avatarView])
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    private let headerRow = UIView()

    // MARK: - UI: Mission Card

    private let missionSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "오늘의 미션"
        l.font = UIFont(name: "Pretendard-SemiBold", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(hex: "#ECEEF2").cgColor
        return v
    }()

    private let colorDotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.backgroundColor = UIColor(hex: "#34D399")
        return v
    }()

    private let missionNameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 18)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let missionDetailLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var missionTextStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [missionNameLabel, missionDetailLabel])
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .leading
        return s
    }()

    private let shuffleButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "arrow.2.circlepath")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#B0B8C1")
        return b
    }()

    private let progressTrack: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F2F4F6")
        v.layer.cornerRadius = 4
        return v
    }()

    private let progressFill: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        v.backgroundColor = UIColor(hex: "#34D399")
        return v
    }()

    // MARK: - UI: Change Mission Link

    private let changeMissionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("색상이 마음에 안 드시나요?  →", for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-Regular", size: 14)
        b.tintColor = UIColor(hex: "#6B7684")
        return b
    }()

    // MARK: - Rx

    private let shuffleSubject = PublishSubject<Void>()
    private let changeMissionSubject = PublishSubject<Void>()

    // MARK: - Init

    init(viewModel: MissionHomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - setupViews

    override func setupViews() {
        view.backgroundColor = .white

        view.addSubview(headerRow)
        headerRow.addSubview(titleStack)
        headerRow.addSubview(rightStack)

        view.addSubview(missionSectionLabel)
        view.addSubview(cardView)
        cardView.addSubview(colorDotView)
        cardView.addSubview(missionTextStack)
        cardView.addSubview(shuffleButton)
        cardView.addSubview(progressTrack)
        progressTrack.addSubview(progressFill)

        view.addSubview(changeMissionButton)
    }

    // MARK: - setupConstraints

    override func setupConstraints() {
        headerRow.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(57)
        }
        titleStack.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        rightStack.snp.makeConstraints { $0.trailing.centerY.equalToSuperview() }
        bellButton.snp.makeConstraints { $0.width.height.equalTo(22) }
        avatarView.snp.makeConstraints { $0.width.height.equalTo(32) }

        // Mission section label
        missionSectionLabel.snp.makeConstraints {
            $0.top.equalTo(headerRow.snp.bottom).offset(36)
            $0.leading.equalToSuperview().offset(44)
        }

        // Card
        cardView.snp.makeConstraints {
            $0.top.equalTo(missionSectionLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        // Color dot (40x40)
        colorDotView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalTo(missionTextStack)
            $0.width.height.equalTo(40)
        }

        // Mission text
        missionTextStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalTo(colorDotView.snp.trailing).offset(12)
            $0.trailing.equalTo(shuffleButton.snp.leading).offset(-12)
        }

        // Shuffle button (28x28)
        shuffleButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalTo(missionTextStack)
            $0.width.height.equalTo(28)
        }

        // Progress track
        progressTrack.snp.makeConstraints {
            $0.top.equalTo(missionTextStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(8)
            $0.bottom.equalToSuperview().inset(20)
        }

        // Progress fill (width 0 initially)
        progressFill.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(0)
        }

        // Change mission link
        changeMissionButton.snp.makeConstraints {
            $0.top.equalTo(cardView.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
        }
    }

    // MARK: - bind

    override func bind() {
        shuffleButton.rx.tap
            .bind(to: shuffleSubject)
            .disposed(by: disposeBag)

        changeMissionButton.rx.tap
            .bind(to: changeMissionSubject)
            .disposed(by: disposeBag)

        let output = viewModel.transform(input: MissionHomeViewModel.Input(
            shuffleTap: shuffleSubject.asObservable(),
            changeMissionTap: changeMissionSubject.asObservable()
        ))

        output.mission
            .drive(onNext: { [weak self] mission in
                self?.applyMission(mission)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Apply

    private func applyMission(_ mission: ColorMission) {
        UIView.animate(withDuration: 0.25) {
            self.colorDotView.backgroundColor = mission.color
            self.progressFill.backgroundColor = mission.color
        }

        missionNameLabel.text = mission.name
        missionDetailLabel.text = "\(mission.hexColor)  ·  \(mission.weatherInfo)"

        // Progress bar width 애니메이션
        progressFill.snp.updateConstraints {
            $0.width.equalTo(0) // 새 미션이면 0에서 시작
        }
        layoutIfNeeded()

        let targetWidth = progressTrack.bounds.width * CGFloat(mission.progress)
        progressFill.snp.updateConstraints {
            $0.width.equalTo(targetWidth)
        }
        UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseOut) {
            self.progressTrack.layoutIfNeeded()
        }
    }

    private func layoutIfNeeded() {
        view.layoutIfNeeded()
    }
}
