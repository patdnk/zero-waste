//
//  WelcomeView.swift
//  ZeroWaste
//

import SwiftUI

@MainActor
enum WelcomeFactory {
    static func make(dependencies: AppDependencies, onComplete: @escaping () -> Void) -> some View {
        WelcomeView(viewModel: WelcomeViewModel(
            settings: dependencies.settings,
            notifications: dependencies.notifications,
            onComplete: onComplete
        ))
    }
}

struct WelcomeView: View {
    @Bindable var viewModel: WelcomeViewModel

    var body: some View {
        ZStack {
            Constants.BackgroundSecondary.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 28) {
                Spacer()
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Constants.Brand)
                Text("Waste less, cook more")
                    .font(.app(.largeTitle, weight: .bold))
                    .foregroundStyle(Constants.TextPrimary)

                VStack(alignment: .leading, spacing: 18) {
                    feature("camera.viewfinder", "Scan labels", "Point the camera at a best-before date or barcode and it's catalogued.")
                    feature("bell.badge", "Get reminded", "A nudge a few days before food expires, and on the day.")
                    feature("frying.pan", "Cook what you have", "Recipes ranked by what's in your fridge, expiring first.")
                }

                Spacer()

                if viewModel.step == .denied {
                    Text("Notifications are off. You can turn them on later in Settings.")
                        .font(.app(.footnote))
                        .foregroundStyle(Constants.TextSecondary)
                    PrimaryButton("Continue") { viewModel.continueAfterDenied() }
                } else {
                    PrimaryButton("Turn on reminders", systemImage: "bell.badge", isLoading: viewModel.isRequesting) {
                        Task { await viewModel.enableReminders() }
                    }
                    SecondaryButton("Not now") { viewModel.skip() }
                }
            }
            .padding(24)
        }
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.app(.title2))
                .foregroundStyle(Constants.Brand)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.app(.headline, weight: .semibold)).foregroundStyle(Constants.TextPrimary)
                Text(detail).font(.app(.subheadline)).foregroundStyle(Constants.TextSecondary)
            }
        }
    }
}

#Preview {
    WelcomeFactory.make(dependencies: .preview(), onComplete: {})
}
