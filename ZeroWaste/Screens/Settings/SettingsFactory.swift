//
//  SettingsFactory.swift
//  ZeroWaste
//

import SwiftUI

@MainActor
enum SettingsFactory {

    static func make(coordinator: SettingsCoordinator, dependencies: AppDependencies) -> some View {
        ViewModelHost(SettingsViewModel(dependencies: dependencies, coordinator: coordinator)) { viewModel in
            SettingsView(viewModel: viewModel)
        }
    }
}
