import UIKit

final class CollectionCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = CollectionViewModel()
        let viewController = CollectionViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }
}
