//
//  MainTabBarController.swift
//  ColorWalk
//

import UIKit

final class MainTabBarController: UITabBarController {

    // Coordinator를 프로퍼티로 보유해야 weak self가 nil이 되지 않음
    private var coordinators: [Coordinator] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        // 홈
        let homeNav = UINavigationController()
        homeNav.isNavigationBarHidden = true
        let homeCoordinator = HomeCoordinator(navigationController: homeNav)
        coordinators.append(homeCoordinator)
        homeCoordinator.start()
        homeNav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // 촬영
        let cameraNav = UINavigationController()
        cameraNav.isNavigationBarHidden = true
        let cameraCoordinator = CameraCoordinator(navigationController: cameraNav)
        coordinators.append(cameraCoordinator)
        cameraCoordinator.start()
        cameraNav.tabBarItem = UITabBarItem(
            title: "촬영",
            image: UIImage(systemName: "camera"),
            selectedImage: UIImage(systemName: "camera.fill")
        )

        // 컬렉션
        let collectionNav = UINavigationController()
        collectionNav.isNavigationBarHidden = true
        let collectionCoordinator = CollectionCoordinator(navigationController: collectionNav)
        coordinators.append(collectionCoordinator)
        collectionCoordinator.start()
        collectionNav.tabBarItem = UITabBarItem(
            title: "컬렉션",
            image: UIImage(systemName: "rectangle.grid.2x2"),
            selectedImage: UIImage(systemName: "rectangle.grid.2x2.fill")
        )

        // 지도
        let mapNav = UINavigationController()
        mapNav.isNavigationBarHidden = true
        let mapCoordinator = MapCoordinator(navigationController: mapNav)
        coordinators.append(mapCoordinator)
        mapCoordinator.start()
        mapNav.tabBarItem = UITabBarItem(
            title: "지도",
            image: UIImage(systemName: "mappin.and.ellipse"),
            selectedImage: UIImage(systemName: "mappin.and.ellipse")
        )

        viewControllers = [homeNav, cameraNav, collectionNav, mapNav]
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(hex: "#6B7684")
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(hex: "#6B7684"),
            .font: UIFont(name: "Pretendard-Medium", size: 10) ?? .systemFont(ofSize: 10)
        ]
        itemAppearance.selected.iconColor = UIColor(hex: "#3182F6")
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(hex: "#3182F6"),
            .font: UIFont(name: "Pretendard-Bold", size: 10) ?? .boldSystemFont(ofSize: 10)
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
