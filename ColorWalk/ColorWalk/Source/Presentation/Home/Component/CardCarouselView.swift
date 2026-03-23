//
//  CardCarouselView.swift
//  ColorWalk
//

import UIKit
import SnapKit
import Kingfisher
import RxSwift
import RxCocoa

final class CardCarouselView: UIView {

    // MARK: - Observables
    private let swipeLeftSubject  = PublishSubject<Void>()
    private let swipeRightSubject = PublishSubject<Void>()
    private let cardTappedSubject = PublishSubject<Void>()
    var swipeLeft:   Observable<Void> { swipeLeftSubject.asObservable() }
    var swipeRight:  Observable<Void> { swipeRightSubject.asObservable() }
    var cardTapped:  Observable<Void> { cardTappedSubject.asObservable() }

    // MARK: - UI Components

    private let backCard2: UIImageView = makeCardImageView(alpha: 0.55)
    private let backCard1: UIImageView = makeCardImageView(alpha: 0.8)
    private let frontCard: UIImageView = makeCardImageView(alpha: 1.0)
    private let glassOverlay = CardGlassOverlayView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        [backCard2, backCard1, frontCard].forEach { addSubview($0) }
        frontCard.addSubview(glassOverlay)

        frontCard.layer.shadowColor = UIColor.black.withAlphaComponent(0.38).cgColor
        frontCard.layer.shadowOffset = CGSize(width: 0, height: 8)
        frontCard.layer.shadowRadius = 16
        frontCard.layer.shadowOpacity = 1.0

        backCard1.layer.shadowColor = UIColor.black.withAlphaComponent(0.25).cgColor
        backCard1.layer.shadowOffset = CGSize(width: 0, height: 6)
        backCard1.layer.shadowRadius = 12
        backCard1.layer.shadowOpacity = 1.0
    }

    private func setupConstraints() {
        // backCard2: width 305, x 44, y 4
        backCard2.snp.makeConstraints {
            $0.width.equalTo(305)
            $0.height.equalTo(380)
            $0.centerX.equalToSuperview().offset(44 - 24) // x:44 from parent (parent x starts at 0)
            $0.top.equalToSuperview().offset(4)
        }

        // backCard1: width 325, x 34, y 14
        backCard1.snp.makeConstraints {
            $0.width.equalTo(325)
            $0.height.equalTo(395)
            $0.centerX.equalToSuperview().offset(34 - 24)
            $0.top.equalToSuperview().offset(14)
        }

        // frontCard: width 345, x 24, y 32, height 420
        frontCard.snp.makeConstraints {
            $0.width.equalTo(345)
            $0.height.equalTo(420)
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalToSuperview().offset(32)
        }

        // GlassOverlay: 카드 하단 — AFc3C height 140
        glassOverlay.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(140)
        }
    }

    private func setupGesture() {
        frontCard.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        frontCard.addGestureRecognizer(pan)
        frontCard.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        cardTappedSubject.onNext(())
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)

        switch gesture.state {
        case .changed:
            frontCard.transform = CGAffineTransform(translationX: translation.x * 0.3, y: 0)

        case .ended:
            let velocity = gesture.velocity(in: self)
            let threshold: CGFloat = 80

            if translation.x < -threshold || velocity.x < -500 {
                animateSwipe(direction: .left)
            } else if translation.x > threshold || velocity.x > 500 {
                animateSwipe(direction: .right)
            } else {
                resetCardPosition()
            }

        default:
            break
        }
    }

    private enum SwipeDirection { case left, right }

    private func animateSwipe(direction: SwipeDirection) {
        let offsetX: CGFloat = direction == .left ? -UIScreen.main.bounds.width : UIScreen.main.bounds.width

        let animator = UIViewPropertyAnimator(duration: 0.35, dampingRatio: 0.85) {
            self.frontCard.transform = CGAffineTransform(translationX: offsetX, y: 0)
            self.frontCard.alpha = 0
        }
        animator.addCompletion { _ in
            self.frontCard.transform = .identity
            // Subject 먼저 발화 → VC가 configure() 호출 → 콘텐츠 갱신 (alpha=0 상태)
            if direction == .left {
                self.swipeLeftSubject.onNext(())
            } else {
                self.swipeRightSubject.onNext(())
            }
            // 콘텐츠 갱신 후 카드 페이드인
            UIView.animate(withDuration: 0.15) {
                self.frontCard.alpha = 1
            }
        }
        animator.startAnimation()
    }

    private func resetCardPosition() {
        UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.8) {
            self.frontCard.transform = .identity
        }.startAnimation()
    }

    // MARK: - Configure

    func configure(cards: [ColorCard], currentIndex: Int) {
        let total = cards.count

        // front card
        let frontCardData = cards[currentIndex]
        loadImage(into: frontCard, url: frontCardData.imageURL)
        glassOverlay.configure(card: frontCardData)

        // back1 card (next)
        let back1Index = (currentIndex + 1) % total
        loadImage(into: backCard1, url: cards[back1Index].imageURL)

        // back2 card
        let back2Index = (currentIndex + 2) % total
        loadImage(into: backCard2, url: cards[back2Index].imageURL)
    }

    private func loadImage(into imageView: UIImageView, url: URL?) {
        guard let url else { return }
        imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
    }

    // MARK: - Helpers

    private static func makeCardImageView(alpha: CGFloat) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.alpha = alpha
        iv.backgroundColor = UIColor(hex: "#E0E0E0")
        return iv
    }
}
