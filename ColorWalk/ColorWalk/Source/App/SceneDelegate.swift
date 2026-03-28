//
//  SceneDelegate.swift
//  ColorWalk

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Properties

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?
    private var pendingMissionUserInfo: [AnyHashable: Any]?

    // MARK: - Scene Lifecycle

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // 앱 킬 상태에서 알림 탭으로 진입 시 저장
        if let response = connectionOptions.notificationResponse {
            pendingMissionUserInfo = response.notification.request.content.userInfo
        }

        let win = UIWindow(windowScene: windowScene)
        win.makeKeyAndVisible()
        window = win

        let coordinator = AppCoordinator(window: win)
        coordinator.start()
        appCoordinator = coordinator
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        MissionAlertScheduler.shared.reschedule()
        handlePendingNotificationIfNeeded()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}

    // MARK: - Private

    private func handlePendingNotificationIfNeeded() {
        guard let userInfo = pendingMissionUserInfo else { return }
        pendingMissionUserInfo = nil

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.handleMissionNotification(userInfo: userInfo)
    }
}
