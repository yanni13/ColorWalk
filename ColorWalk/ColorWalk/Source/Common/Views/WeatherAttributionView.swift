//
//  WeatherAttributionView.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class WeatherAttributionView: UIView {
    
    // MARK: - Properties
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 3
        s.alignment = .center
        return s
    }()
    
    private let appleLogoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "applelogo")
        iv.tintColor = UIColor.App.textSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let weatherLabel: UILabel = {
        let l = UILabel()
        l.text = "Weather"
        l.font = UIFont(name: "Pretendard-Medium", size: 12) ?? .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor.App.textSecondary
        return l
    }()
    
    private let attributionButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = .clear
        return b
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        bind()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Setup
    
    private func setupViews() {
        addSubview(stackView)
        stackView.addArrangedSubview(appleLogoImageView)
        stackView.addArrangedSubview(weatherLabel)
        addSubview(attributionButton)
    }
    
    private func setupConstraints() {
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        appleLogoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }
        
        attributionButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func bind() {
        attributionButton.rx.tap
            .subscribe(onNext: {
                if let url = URL(string: "https://developer.apple.com/weatherkit/data-source-attribution/") {
                    UIApplication.shared.open(url)
                }
            })
            .disposed(by: disposeBag)
    }
}
