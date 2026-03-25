//
//  HomeCoordinator.swift
//  ColorWalk
//

import UIKit

final class HomeCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = HomeViewModel()
        let viewController = HomeViewController(viewModel: viewModel)
        viewController.onCardTap = { [weak self, weak viewController] index in
            guard let self, let vc = viewController else { return }
            self.showDetail(cards: vc.allCards, startIndex: index)
        }
        viewController.onMissionTap = { [weak self] in
            self?.showMission()
        }
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func showMission() {
        let viewModel = MissionHomeViewModel()
        let vc = MissionHomeViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }

    private func showDetail(cards: [ColorCard], startIndex: Int) {
        let viewModel = ColorDetailViewModel(cards: cards, startIndex: startIndex)
        let vc = ColorDetailViewController(viewModel: viewModel)
        viewModel.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(vc, animated: true)
    }
}
