//
//  AppFlowController.swift
//  ZeroWaste
//
//  State-driven app flow: holds the current phase and exposes transitions.
//

import Foundation
import Observation

/// Which root screen is shown. The single source of truth for app-level flow.
enum AppFlowPhase: Equatable {
    case launch
    case welcome
    case main
}

@MainActor
@Observable
final class AppFlowController {

    private(set) var phase: AppFlowPhase = .launch
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    // MARK: - Transitions

    /// Call when the splash is done. Skips the welcome flow once it has been completed.
    func transitionFromLaunch() {
        phase = settings.hasCompletedWelcome ? .main : .welcome
    }

    /// Call when the welcome flow finishes (with or without notifications enabled).
    func transitionToMain() {
        settings.hasCompletedWelcome = true
        phase = .main
    }

    /// Re-run the welcome flow (e.g. from Settings).
    func transitionToWelcome() {
        phase = .welcome
    }
}
