//
//  AppCoordinator.swift
//  ColorWalk
//

import UIKit
import CoreLocation

final class AppCoordinator {

    // MARK: - Properties

    private let window: UIWindow
    private let locationManager = CLLocationManager()

    private enum Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }

    // MARK: - Init

    init(window: UIWindow) {
        self.window = window
    }

    // MARK: - Start

    func start() {
        showSplash()
    }

    // MARK: - Private

    private func showSplash() {
        let splash = SplashViewController()
        splash.onAnimationComplete = { [weak self] in
            guard let self else { return }
            if UserDefaults.standard.bool(forKey: Keys.hasLaunchedBefore) {
                self.showTabBar()
            } else {
                self.showOnboarding()
            }
        }
        window.rootViewController = splash
        window.makeKeyAndVisible()
    }

    private func showOnboarding() {
        let viewModel = OnboardingViewModel()
        let vc = OnboardingViewController(viewModel: viewModel)
        vc.onOnboardingComplete = { [weak self] in
            UserDefaults.standard.set(true, forKey: Keys.hasLaunchedBefore)
            self?.showTabBar()
        }
        let win = window
        UIView.transition(with: win, duration: 0.35, options: .transitionCrossDissolve) {
            win.rootViewController = vc
        }
    }

    private func showTabBar() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        let win = window
        UIView.transition(with: win, duration: 0.35, options: .transitionCrossDissolve) {
            win.rootViewController = MainTabBarController()
        }
    }
}
