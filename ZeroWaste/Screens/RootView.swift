//
//  RootView.swift
//  ZeroWaste
//
//  Root view driven by app flow phase: Launch → Welcome → Main.
//

import SwiftUI

struct RootView: View {
    let flowController: AppFlowController
    let coordinator: AppCoordinator

    var body: some View {
        Group {
            switch flowController.phase {
            case .launch:
                SplashView(onFinish: { flowController.transitionFromLaunch() })
            case .welcome:
                WelcomeFactory.make(dependencies: coordinator.dependencies) {
                    flowController.transitionToMain()
                }
            case .main:
                MainView(coordinator: coordinator)
            }
        }
        .font(.app(.body))
        .animation(.easeInOut(duration: 0.3), value: flowController.phase)
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    RootView(
        flowController: AppFlowController(settings: dependencies.settings),
        coordinator: AppCoordinator(dependencies: dependencies)
    )
}
