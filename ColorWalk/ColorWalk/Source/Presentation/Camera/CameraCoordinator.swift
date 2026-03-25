//
//  CameraCoordinator.swift
//  ColorWalk
//

import UIKit

final class CameraCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = CameraViewController()
        vc.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        navigationController.setViewControllers([vc], animated: false)
    }
}
