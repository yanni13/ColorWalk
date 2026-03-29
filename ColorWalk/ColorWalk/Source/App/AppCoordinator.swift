//
//  AppCoordinator.swift
//  ColorWalk
//

import UIKit

final class AppCoordinator {

    // MARK: - Properties

    private let window: UIWindow

    private enum Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }

    // MARK: - Init

    init(window: UIWindow) {
        self.window = window
    }

    // MARK: - Start

    func start() {
        if UserDefaults.standard.bool(forKey: Keys.hasLaunchedBefore) {
            showTabBar()
        } else {
            showOnboarding()
        }
    }

    // MARK: - Private

    private func showOnboarding() {
        let viewModel = OnboardingViewModel()
        let vc = OnboardingViewController(viewModel: viewModel)
        vc.onOnboardingComplete = { [weak self] in
            UserDefaults.standard.set(true, forKey: Keys.hasLaunchedBefore)
            self?.showTabBar()
        }
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }

    private func showTabBar() {
        window.rootViewController = MainTabBarController()
        window.makeKeyAndVisible()
    }
}
