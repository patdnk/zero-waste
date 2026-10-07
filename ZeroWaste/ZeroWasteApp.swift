//
//  ZeroWasteApp.swift
//  ZeroWaste
//

import SwiftUI
import UserNotifications

@main
struct ZeroWasteApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var dependencies: AppDependencies
    @State private var flowController: AppFlowController
    @State private var coordinator: AppCoordinator
    private let notificationDelegate = NotificationDelegate()

    init() {
        AppFont.registerBundledFonts()
        AppFont.configureAppearance()
        let dependencies = AppDependencies.live()
        let coordinator = AppCoordinator(dependencies: dependencies)
        _dependencies = State(initialValue: dependencies)
        _flowController = State(initialValue: AppFlowController(settings: dependencies.settings))
        _coordinator = State(initialValue: coordinator)

        notificationDelegate.onOpenItem = { id in
            Task { @MainActor in coordinator.showItem(id: id) }
        }
        UNUserNotificationCenter.current().delegate = notificationDelegate

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--sample-data"), dependencies.inventory.items.isEmpty {
            dependencies.inventory.loadSampleData()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView(flowController: flowController, coordinator: coordinator)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await dependencies.notifications.refreshAuthorizationStatus()
                await dependencies.syncNotifications()
                await dependencies.refreshRecalls()
            }
        }
    }
}
