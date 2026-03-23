//
//  BaseViewController.swift
//  ColorWalk
//

import UIKit
import RxSwift

class BaseViewController: UIViewController {

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        bind()
    }

    /// 뷰 계층 구성 — 서브클래스에서 오버라이드
    func setupViews() {}

    /// SnapKit 레이아웃 — 서브클래스에서 오버라이드
    func setupConstraints() {}

    /// RxSwift 바인딩 — 서브클래스에서 오버라이드
    func bind() {}
}
