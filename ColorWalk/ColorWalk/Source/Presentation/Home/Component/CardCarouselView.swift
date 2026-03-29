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

    // MARK: - State
    private var currentIndex: Int = 0
    private var totalCount: Int = 0

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
        backCard2.snp.makeConstraints {
            $0.width.equalTo(305)
            $0.height.equalTo(380)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(4)
        }

        backCard1.snp.makeConstraints {
            $0.width.equalTo(325)
            $0.height.equalTo(395)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(14)
        }

        frontCard.snp.makeConstraints {
            $0.width.equalTo(345)
            $0.height.equalTo(420)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(32)
        }

        // GlassOverlay: 카드 하단
        glassOverlay.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(120)
        }
    }

    private func setupGesture() {
        frontCard.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
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
            frontCard.transform = CGAffineTransform(translationX: translation.x * 0.85, y: 0)

        case .ended:
            let velocity = gesture.velocity(in: self)
            let threshold: CGFloat = 80

            if translation.x < -threshold || velocity.x < -500 {
                if currentIndex < totalCount - 1 {
                    animateSwipe(direction: .left)
                } else {
                    resetCardPosition()
                }
            } else if translation.x > threshold || velocity.x > 500 {
                if currentIndex > 0 {
                    animateSwipe(direction: .right)
                } else {
                    resetCardPosition()
                }
            } else {
                resetCardPosition()
            }

        case .cancelled:
            resetCardPosition()

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
        self.currentIndex = currentIndex
        self.totalCount = cards.count
        let total = cards.count

        let frontCardData = cards[currentIndex]
        loadImage(into: frontCard, card: frontCardData)
        glassOverlay.configure(card: frontCardData)

        backCard1.isHidden = total < 2
        backCard2.isHidden = total < 3

        if total >= 2 {
            loadImage(into: backCard1, card: cards[(currentIndex + 1) % total])
        }
        if total >= 3 {
            loadImage(into: backCard2, card: cards[(currentIndex + 2) % total])
        }
    }

    private func loadImage(into imageView: UIImageView, card: ColorCard) {
        if let img = card.capturedImage {
            imageView.image = img
        } else if let url = card.imageURL {
            imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            imageView.image = nil
        }
    }

    func updateLocationVisibility(_ authorized: Bool) {
        glassOverlay.updateLocationVisibility(authorized)
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

// MARK: - UIGestureRecognizerDelegate

extension CardCarouselView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: self)
        return abs(velocity.x) > abs(velocity.y)
    }
}
