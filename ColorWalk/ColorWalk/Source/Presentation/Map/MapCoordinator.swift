import UIKit

final class MapCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = MapViewModel()
        let vc = MapViewController(viewModel: viewModel)
        navigationController.setViewControllers([vc], animated: false)
    }
}
