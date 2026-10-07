//
//  SettingsView.swift
//  ZeroWaste
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    ScreenHeader(overline: "Zero Waste \(viewModel.appVersion)", title: "Settings")

                    CardSection("Reminders", footer: "You'll get a heads-up before the date, one on the day, and one if it slips past.") {
                        Toggle(isOn: Binding(
                            get: { viewModel.notificationsEnabled },
                            set: { enabled in Task { await viewModel.setNotificationsEnabled(enabled) } }
                        )) {
                            Text("Expiry reminders").font(.app(.subheadline, weight: .medium))
                        }
                        .tint(Constants.BrandOrange)
                        .disabled(viewModel.isUpdatingNotifications)
                        .accessibilityIdentifier("settings.notificationsToggle")

                        if viewModel.notificationState == .denied {
                            ActionRow(title: "Allow in Settings app", symbol: "gear", tint: Constants.BrandOrange) {
                                viewModel.openSystemSettings()
                            }
                        }

                        Stepper(value: $viewModel.leadDays, in: 1...14) {
                            Text("Remind me \(viewModel.leadDays) days before").font(.app(.subheadline))
                        }
                        InfoRow("At", symbol: "clock") {
                            DatePicker("At", selection: $viewModel.notifyTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        ActionRow(title: "Send a test notification", symbol: "bell", tint: Constants.BrandOrange) {
                            Task { await viewModel.sendTestNotification() }
                        }
                        .disabled(!viewModel.notificationsEnabled)
                        .opacity(viewModel.notificationsEnabled ? 1 : 0.45)
                    }

                    CardSection("Fridge", footer: "Recipes that use food inside this window are ranked higher.") {
                        Stepper(value: $viewModel.soonThresholdDays, in: 1...14) {
                            Text("“Expiring soon” means within \(viewModel.soonThresholdDays) days").font(.app(.subheadline))
                        }
                    }

                    CardSection("Data") {
                        InfoRow("In your fridge", symbol: "refrigerator", value: "\(viewModel.activeItemCount)")
                        InfoRow("Used up", symbol: "checkmark", value: "\(viewModel.usedItemCount)")
                        ActionRow(title: "Add sample food", symbol: "sparkles") { viewModel.loadSampleData() }
                        ActionRow(title: "Clear used-up history", symbol: "clock.arrow.circlepath") { viewModel.clearUsedHistory() }
                            .disabled(viewModel.usedItemCount == 0)
                            .opacity(viewModel.usedItemCount == 0 ? 0.45 : 1)
                        ActionRow(title: "Delete everything", symbol: "trash", tint: Constants.StatusExpired) { viewModel.deleteEverything() }
                            .disabled(viewModel.activeItemCount == 0 && viewModel.usedItemCount == 0)
                    }

                    CardSection("About", footer: "Dates and barcodes are read on your device with Apple Vision. Product names come from Open Food Facts.") {
                        ActionRow(title: "How Zero Waste works", symbol: "book.pages", tint: Constants.BrandOrange) {
                            viewModel.showHowItWorks()
                        }
                        .accessibilityIdentifier("settings.howItWorks")
                        InfoRow("Version", value: viewModel.appVersion)
                        InfoRow("Recipes", value: "\(viewModel.recipeCount)")
                    }
                }
                .padding(.horizontal, Spacing.gutter)
                .padding(.bottom, Spacing.xl)
            }
            .pageBackground()
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.refresh() }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let coordinator = AppCoordinator(dependencies: dependencies)
    SettingsFactory.make(coordinator: coordinator.settingsCoordinator, dependencies: dependencies)
}
