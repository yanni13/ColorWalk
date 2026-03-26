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
        let viewModel = MissionHomeViewModel()
        let vc = MissionHomeViewController(viewModel: viewModel)
        vc.onCardTap = { [weak self, weak vc] index in
            guard let self, let vc else { return }
            self.showDetail(cards: vc.allCards, startIndex: index)
        }
        navigationController.setViewControllers([vc], animated: false)
    }

    // MARK: - Private

    private func showDetail(cards: [ColorCard], startIndex: Int) {
        let viewModel = ColorDetailViewModel(cards: cards, startIndex: startIndex)
        let vc = ColorDetailViewController(viewModel: viewModel)
        viewModel.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.pushViewController(vc, animated: true)
    }
}
