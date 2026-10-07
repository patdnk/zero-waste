//
//  SettingsView.swift
//  ZeroBite
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let dependencies: AppDependencies

    private enum Route: Hashable { case alerts }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    ScreenHeader(overline: "Zero Bite \(viewModel.appVersion)", title: "Settings")

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

                    CardSection("Food safety", footer: "Checks the Food Standards Agency for UK recalls and tells you if something in your fridge might be affected.") {
                        Toggle(isOn: $viewModel.recallChecksEnabled) {
                            Text("Check UK food recalls").font(.app(.subheadline, weight: .medium))
                        }
                        .tint(Constants.BrandOrange)
                        .accessibilityIdentifier("settings.recallsToggle")

                        NavigationLink(value: Route.alerts) {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Food alerts").font(.app(.subheadline, weight: .medium))
                                    Text(viewModel.alertsSummary)
                                        .font(.app(.caption))
                                        .foregroundStyle(Constants.TextSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Constants.TextMuted)
                            }
                            .foregroundStyle(Constants.TextPrimary)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settings.foodAlerts")
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Overline("Your allergies")
                        FlowLayout(spacing: 6) {
                            ForEach(Allergen.allCases) { allergen in
                                let isOn = viewModel.isSelected(allergen)
                                Button { viewModel.toggle(allergen) } label: {
                                    Text(allergen.label)
                                        .font(.app(.subheadline, weight: isOn ? .semibold : .regular))
                                        .foregroundStyle(isOn ? Constants.OnInk : Constants.TextSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(isOn ? Constants.TextPrimary : Constants.ChipFill,
                                                    in: RoundedRectangle(cornerRadius: Radius.control))
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(isOn ? .isSelected : [])
                            }
                        }
                        Text("Allergy alerts for these show under Food alerts → For you.")
                            .font(.app(.caption))
                            .foregroundStyle(Constants.TextSecondary)
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

                    CardSection("About", footer: "Dates and barcodes are read on your device with Apple Vision. Product names come from Open Food Facts. Food alerts come from the Food Standards Agency under the Open Government Licence v3.0.") {
                        ActionRow(title: "How Zero Bite works", symbol: "book.pages", tint: Constants.BrandOrange) {
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
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .alerts: FoodAlertsFactory.makeList(dependencies: dependencies)
                }
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let coordinator = AppCoordinator(dependencies: dependencies)
    SettingsFactory.make(coordinator: coordinator.settingsCoordinator, dependencies: dependencies)
}
