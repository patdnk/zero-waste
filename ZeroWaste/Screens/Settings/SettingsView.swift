//
//  SettingsView.swift
//  ZeroWaste
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Expiry reminders", isOn: Binding(
                        get: { viewModel.notificationsEnabled },
                        set: { enabled in Task { await viewModel.setNotificationsEnabled(enabled) } }
                    ))
                    .disabled(viewModel.isUpdatingNotifications)
                    .accessibilityIdentifier("settings.notificationsToggle")

                    if viewModel.notificationState == .denied {
                        Button("Allow in Settings app") { viewModel.openSystemSettings() }
                    }

                    Stepper("Remind me \(viewModel.leadDays) days before", value: $viewModel.leadDays, in: 1...14)
                    DatePicker("At", selection: $viewModel.notifyTime, displayedComponents: .hourAndMinute)

                    Button("Send a test notification") {
                        Task { await viewModel.sendTestNotification() }
                    }
                    .disabled(!viewModel.notificationsEnabled)
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("You'll get a heads-up before the date, one on the day, and one if it slips past.")
                }

                Section {
                    Stepper("“Expiring soon” means within \(viewModel.soonThresholdDays) days", value: $viewModel.soonThresholdDays, in: 1...14)
                } header: {
                    Text("Fridge")
                } footer: {
                    Text("Recipes that use food inside this window are ranked higher.")
                }

                Section("Data") {
                    LabeledContent("In your fridge", value: "\(viewModel.activeItemCount)")
                    LabeledContent("Used up", value: "\(viewModel.usedItemCount)")
                    Button("Add sample food") { viewModel.loadSampleData() }
                    Button("Clear used-up history") { viewModel.clearUsedHistory() }
                        .disabled(viewModel.usedItemCount == 0)
                    Button("Delete everything", role: .destructive) { viewModel.deleteEverything() }
                        .disabled(viewModel.activeItemCount == 0 && viewModel.usedItemCount == 0)
                }

                Section("About") {
                    LabeledContent("Version", value: viewModel.appVersion)
                    LabeledContent("Recipes", value: "\(viewModel.recipeCount)")
                    Text("Dates and barcodes are read on your device with Apple Vision. Product names come from Open Food Facts.")
                        .font(.app(.footnote))
                        .foregroundStyle(Constants.TextSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Constants.BackgroundSecondary)
            .navigationTitle("Settings")
            .task { await viewModel.refresh() }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let coordinator = AppCoordinator(dependencies: dependencies)
    SettingsFactory.make(coordinator: coordinator.settingsCoordinator, dependencies: dependencies)
}
