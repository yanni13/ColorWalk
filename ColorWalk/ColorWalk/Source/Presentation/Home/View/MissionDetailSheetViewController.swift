//
//  MissionDetailSheetViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MissionDetailSheetViewController: UIViewController {

    // MARK: - Properties
    private var mission: ColorMission
    private let weatherData: WeatherData
    private let disposeBag = DisposeBag()
    var onNameUpdate: ((String) -> Void)?

    // MARK: - UI
    private let sheetView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 32
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E5E7EB")
        v.layer.cornerRadius = 2.5
        return v
    }()

    private let colorBigView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 40
        v.layer.shadowOffset = CGSize(width: 0, height: 10)
        v.layer.shadowRadius = 20
        v.layer.shadowOpacity = 0.2
        return v
    }()

    private let missionNameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 24)
        l.textColor = UIColor(hex: "#191F28")
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let editNameButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "pencil")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#B0B8C1")
        return b
    }()

    private lazy var missionNameStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [missionNameLabel, editNameButton])
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    private let hexBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F2F4F6")
        v.layer.cornerRadius = 12
        return v
    }()

    private let hexLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Medium", size: 14)
        l.textColor = UIColor(hex: "#4E5968")
        return l
    }()

    private let weatherSectionTitle: UILabel = {
        let l = UILabel()
        l.text = L10n.missionDetailWeatherTitle
        l.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        l.textColor = UIColor(hex: "#8B95A1")
        return l
    }()

    private let weatherInfoContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F9FAFB")
        v.layer.cornerRadius = 20
        return v
    }()

    private let weatherIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(hex: "#4E5968")
        return iv
    }()

    private let weatherStatusLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 18)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let weatherDetailLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 14)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private let weatherAttributionView = WeatherAttributionView()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(L10n.buttonConfirm, for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 16)
        b.tintColor = .white
        b.backgroundColor = UIColor(hex: "#191F28")
        b.layer.cornerRadius = 16
        return b
    }()

    // MARK: - Init
    init(mission: ColorMission, weatherData: WeatherData) {
        self.mission = mission
        self.weatherData = weatherData
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        configureContent()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .clear
        sheetView.transform = CGAffineTransform(translationX: 0, y: 600)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.sheetView.transform = .identity
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(sheetView)
        sheetView.addSubview(handleView)
        sheetView.addSubview(colorBigView)
        sheetView.addSubview(missionNameStack)
        sheetView.addSubview(hexBadge)
        hexBadge.addSubview(hexLabel)
        
        sheetView.addSubview(weatherSectionTitle)
        sheetView.addSubview(weatherInfoContainer)
        weatherInfoContainer.addSubview(weatherIconView)
        weatherInfoContainer.addSubview(weatherStatusLabel)
        weatherInfoContainer.addSubview(weatherDetailLabel)
        sheetView.addSubview(weatherAttributionView)
        
        sheetView.addSubview(closeButton)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSheet))
        view.addGestureRecognizer(tap)
    }

    private func setupConstraints() {
        sheetView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }
        
        colorBigView.snp.makeConstraints {
            $0.top.equalTo(handleView.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(100)
        }
        
        missionNameStack.snp.makeConstraints {
            $0.top.equalTo(colorBigView.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().inset(40)
            $0.trailing.lessThanOrEqualToSuperview().inset(40)
        }
        
        editNameButton.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }
        
        hexBadge.snp.makeConstraints {
            $0.top.equalTo(missionNameStack.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(24)
        }
        
        hexLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
        
        weatherSectionTitle.snp.makeConstraints {
            $0.top.equalTo(hexBadge.snp.bottom).offset(40)
            $0.leading.equalToSuperview().offset(24)
        }
        
        weatherInfoContainer.snp.makeConstraints {
            $0.top.equalTo(weatherSectionTitle.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(100)
        }
        
        weatherIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44)
        }
        
        weatherStatusLabel.snp.makeConstraints {
            $0.leading.equalTo(weatherIconView.snp.trailing).offset(16)
            $0.top.equalToSuperview().offset(28)
        }
        
        weatherDetailLabel.snp.makeConstraints {
            $0.leading.equalTo(weatherStatusLabel)
            $0.top.equalTo(weatherStatusLabel.snp.bottom).offset(4)
        }
        
        weatherAttributionView.snp.makeConstraints {
            $0.top.equalTo(weatherInfoContainer.snp.bottom).offset(8)
            $0.trailing.equalTo(weatherInfoContainer)
        }
        
        closeButton.snp.makeConstraints {
            $0.top.equalTo(weatherInfoContainer.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(56)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
    }

    private func configureContent() {
        colorBigView.backgroundColor = mission.color
        colorBigView.layer.shadowColor = mission.color.cgColor
        missionNameLabel.text = mission.name
        hexLabel.text = mission.hexColor
        
        weatherIconView.image = UIImage(systemName: weatherData.symbolName)
        weatherStatusLabel.text = weatherData.displayText
        weatherDetailLabel.text = L10n.missionDetailWeatherDetail(celsius: weatherData.celsius, humidity: weatherData.humidity)
    }

    private func bind() {
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.dismissSheet() })
            .disposed(by: disposeBag)

        editNameButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentEditNameAlert()
            })
            .disposed(by: disposeBag)
    }

    private func presentEditNameAlert() {
        let alert = UIAlertController(title: L10n.alertEditNameTitle, message: L10n.alertEditNameMessage, preferredStyle: .alert)
        alert.addTextField { [weak self] tf in
            tf.text = self?.mission.name
            tf.placeholder = L10n.textFieldMissionNamePlaceholder
        }
        alert.addAction(UIAlertAction(title: L10n.buttonCancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.buttonChange, style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self?.updateName(name)
        })
        present(alert, animated: true)
    }

    private func updateName(_ name: String) {
        missionNameLabel.text = name
        let updated = ColorMission(
            name: name,
            hexColor: mission.hexColor,
            color: mission.color,
            weatherInfo: mission.weatherInfo,
            progress: mission.progress
        )
        self.mission = updated
        onNameUpdate?(name)
    }

    @objc private func dismissSheet() {
        UIView.animate(withDuration: 0.3, animations: {
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: 600)
            self.view.backgroundColor = .clear
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}
