//
//  AppDelegate.swift
//  ColorWalk

import UIKit
import UserNotifications
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    // MARK: - Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        FirebaseApp.configure()
        MissionAlertScheduler.shared.reschedule()
        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    // 포그라운드 상태에서 알림 배너 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // 알림 탭 (백그라운드 → 포그라운드)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleMissionNotification(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }

    // MARK: - Private

    func handleMissionNotification(userInfo: [AnyHashable: Any]) {
        guard let hex = userInfo[AppConstants.Notification.missionHexKey] as? String,
              let name = userInfo[AppConstants.Notification.missionNameKey] as? String else { return }

        if #available(iOS 16.1, *) {
            ColorActivityManager.shared.startTimedSession(
                missionName: name,
                missionHex: hex,
                missionColor: UIColor(hex: hex)
            )
        }

        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let tabBar = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController as? MainTabBarController
            else { return }
            tabBar.navigateToCamera()
        }
    }
}
