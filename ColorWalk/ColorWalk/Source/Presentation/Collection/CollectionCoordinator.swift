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
        viewController.coordinator = self
        navigationController.setViewControllers([viewController], animated: false)
    }

    func presentEdit(missionDateIdentifier: String) {
        let viewModel = CollectionEditViewModel(missionDateIdentifier: missionDateIdentifier)
        let viewController = CollectionEditViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: viewController)
        nav.isNavigationBarHidden = true
        nav.modalPresentationStyle = .fullScreen
        navigationController.present(nav, animated: true)
    }
}
