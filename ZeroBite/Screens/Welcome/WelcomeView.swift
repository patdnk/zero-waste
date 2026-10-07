//
//  WelcomeView.swift
//  ZeroBite
//

import SwiftUI

@MainActor
enum WelcomeFactory {
    static func make(
        mode: WelcomeViewModel.Mode = .firstRun,
        dependencies: AppDependencies,
        onComplete: @escaping () -> Void
    ) -> some View {
        ViewModelHost(WelcomeViewModel(
            mode: mode,
            settings: dependencies.settings,
            notifications: dependencies.notifications,
            onComplete: onComplete
        )) { viewModel in
            WelcomeView(viewModel: viewModel)
        }
    }
}

struct WelcomeView: View {
    @Bindable var viewModel: WelcomeViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $viewModel.currentPage) {
                ForEach(viewModel.pages, id: \.self) { page in
                    OnboardingPage(page: page, isDenied: viewModel.step == .denied)
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.snappy, value: viewModel.currentPage)

            footer
        }
        .pageBackground()
    }

    private var header: some View {
        HStack {
            PageIndicator(count: viewModel.pages.count, index: viewModel.pageIndex)
            Spacer()
            if !viewModel.isLastPage {
                Button(viewModel.mode == .replay ? "Close" : "Skip") { viewModel.skipIntro() }
                    .font(.app(.subheadline, weight: .medium))
                    .foregroundStyle(Constants.TextSecondary)
                    .accessibilityIdentifier("welcome.skip")
            }
        }
        .frame(height: 38)
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.sm)
    }

    private var footer: some View {
        VStack(spacing: Spacing.sm) {
            PrimaryButton(
                viewModel.primaryTitle,
                systemImage: viewModel.currentPage == .reminders && viewModel.step != .denied ? "bell.badge" : nil,
                isLoading: viewModel.isRequesting,
                kind: viewModel.currentPage == .reminders ? .brand : .ink
            ) {
                Task { await viewModel.primaryAction() }
            }
            .accessibilityIdentifier("welcome.primary")

            if viewModel.currentPage == .reminders, viewModel.step != .denied {
                SecondaryButton("Not now") { viewModel.skip() }
                    .accessibilityIdentifier("welcome.notNow")
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.lg)
    }
}

/// Bespoke page dots: short bars, the current one stretched and orange.
private struct PageIndicator: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { position in
                Rectangle()
                    .fill(position == index ? Constants.BrandOrange : Constants.ChipFill)
                    .frame(width: position == index ? 22 : 8, height: 4)
            }
        }
        .animation(.snappy, value: index)
        .accessibilityElement()
        .accessibilityLabel("Page \(index + 1) of \(count)")
    }
}

// MARK: - Pages

private struct OnboardingPage: View {
    let page: WelcomeViewModel.Page
    var isDenied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: Spacing.lg)
            illustration
                .frame(maxWidth: .infinity)
                .frame(height: 300)
            Spacer(minLength: Spacing.lg)
            VStack(alignment: .leading, spacing: Spacing.md) {
                if page == .welcome {
                    BrandLockup(size: 30)
                        .padding(.bottom, Spacing.xs)
                } else {
                    Overline(overline, tint: Constants.BrandOrange)
                }
                Text(title)
                    .font(.app(.largeTitle, weight: .semibold))
                    .tracking(-1)
                    .foregroundStyle(Constants.TextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.app(.body))
                    .foregroundStyle(Constants.TextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Spacing.xl)
        }
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .contain)
    }

    private var overline: String {
        switch page {
        case .welcome: "Zero Bite"
        case .scan: "1 · Scan"
        case .remind: "2 · Get reminded"
        case .cook: "3 · Cook"
        case .reminders: "Last step"
        }
    }

    private var title: String {
        switch page {
        case .welcome: "Waste less,\ncook more."
        case .scan: "Scan the label, skip the typing."
        case .remind: "Know what to use first."
        case .cook: "Cook with what you have."
        case .reminders: isDenied ? "Reminders are off." : "Want a nudge before food goes off?"
        }
    }

    private var message: String {
        switch page {
        case .welcome:
            "Keep track of what's in your fridge, freezer and cupboard, and use it up before the date."
        case .scan:
            "Point the camera at a best-before or use-by date. A barcode fills in the product name. Everything is read on your phone."
        case .remind:
            "Your fridge is sorted by urgency. The most urgent item sits at the top, with one-tap Used it and Freeze."
        case .cook:
            "Recipes are ranked by what's already in your fridge, with food that's about to expire counted first."
        case .reminders:
            isDenied
                ? "You can turn them on any time in Settings."
                : "We'll remind you a few days before the date, on the day, and if it slips past. You choose when."
        }
    }

    @ViewBuilder
    private var illustration: some View {
        switch page {
        case .welcome: WelcomeIllustration()
        case .scan: ScanIllustration()
        case .remind: RemindIllustration()
        case .cook: CookIllustration()
        case .reminders: RemindersIllustration()
        }
    }
}

// MARK: - Illustrations (composed from the app's own components, with placeholder data)

/// The app icon in miniature, for mock notifications.
private struct AppIconTile: View {
    var size: CGFloat = 36

    var body: some View {
        BrandMark()
            .padding(size * 0.08)
            .frame(width: size, height: size)
            .background(BrandMark.ink, in: RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
    }
}

private struct MockItemTile: View {
    let symbol: String
    let name: String
    let detail: String
    let label: String
    let tint: Color
    var accent = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IconTile(symbol: symbol, tint: tint)
            Text(name)
                .font(.app(.subheadline, weight: .semibold))
                .foregroundStyle(Constants.TextPrimary)
                .lineLimit(1)
                .padding(.top, 10)
            HStack {
                Text(detail).foregroundStyle(Constants.TextSecondary)
                Spacer()
                Text(label).fontWeight(.semibold).foregroundStyle(tint)
            }
            .font(.app(.caption))
            .padding(.top, 2)
        }
        .cardStyle(accent: accent ? tint : nil)
    }
}

private struct WelcomeIllustration: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                MockItemTile(symbol: "drop.fill", name: "Greek yogurt", detail: "500 g", label: "Today", tint: Constants.StatusToday)
                MockItemTile(symbol: "carrot.fill", name: "Spinach", detail: "1 bag", label: "2d", tint: Constants.StatusSoon)
            }
            HStack(spacing: Spacing.sm) {
                MockItemTile(symbol: "fish.fill", name: "Salmon", detail: "2 pcs", label: "3 Nov", tint: Constants.StatusFresh, accent: false)
                MockItemTile(symbol: "basket.fill", name: "Spaghetti", detail: "500 g", label: "Jun", tint: Constants.StatusFresh, accent: false)
            }
            HStack(spacing: Spacing.sm) {
                MockItemTile(symbol: "birthday.cake.fill", name: "Sourdough", detail: "1 loaf", label: "4d", tint: Constants.StatusFresh, accent: false)
                MockItemTile(symbol: "leaf.fill", name: "Lemons", detail: "3 pcs", label: "9d", tint: Constants.StatusFresh, accent: false)
            }
            .opacity(0.5)
        }
        .accessibilityHidden(true)
    }
}

private struct ScanIllustration: View {
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("SEMI SKIMMED MILK")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Constants.TextSecondary)
                Text("2 PINTS · 1.136 L")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Constants.TextMuted)
                Text("USE BY 12 OCT")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(Constants.TextPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Constants.BrandOrange.opacity(0.15))
                    .overlay { Rectangle().strokeBorder(Constants.BrandOrange, lineWidth: 2) }
                Image(systemName: "barcode")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(Constants.TextPrimary)
            }
            .padding(Spacing.xl)
            .cardStyle(padding: 0)
            .frame(width: 250)

            ViewfinderCorners()
                .stroke(Constants.BrandOrange, style: StrokeStyle(lineWidth: 4, lineCap: .square))
                .frame(width: 300, height: 260)
        }
        .accessibilityHidden(true)
    }
}

/// Four corner brackets of a camera viewfinder.
private struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length: CGFloat = 28
        var path = Path()
        for (corner, dx, dy) in [
            (CGPoint(x: rect.minX, y: rect.minY), 1.0, 1.0),
            (CGPoint(x: rect.maxX, y: rect.minY), -1.0, 1.0),
            (CGPoint(x: rect.minX, y: rect.maxY), 1.0, -1.0),
            (CGPoint(x: rect.maxX, y: rect.maxY), -1.0, -1.0),
        ] {
            path.move(to: CGPoint(x: corner.x, y: corner.y + dy * length))
            path.addLine(to: corner)
            path.addLine(to: CGPoint(x: corner.x + dx * length, y: corner.y))
        }
        return path
    }
}

private struct RemindIllustration: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Overline("Use first")
                    Spacer()
                    Text("2 more need attention").font(.app(.caption)).foregroundStyle(Constants.TextSecondary)
                }
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spinach").font(.app(.title3, weight: .semibold)).foregroundStyle(Constants.TextPrimary)
                        Text("1 bag · Fridge").font(.app(.caption)).foregroundStyle(Constants.TextSecondary)
                    }
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("1").font(.system(size: 40, weight: .semibold)).tracking(-1.5)
                        Text("day").font(.app(.subheadline))
                    }
                    .foregroundStyle(Constants.StatusToday)
                }
                .padding(.vertical, 10)
                ShelfLifeBar(progress: 0.86, tint: Constants.StatusToday)
                HStack(spacing: 6) {
                    Text("Used it").frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Constants.TextPrimary, in: RoundedRectangle(cornerRadius: Radius.control))
                        .foregroundStyle(Constants.OnInk)
                    Text("Freeze").frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Constants.ChipFill, in: RoundedRectangle(cornerRadius: Radius.control))
                        .foregroundStyle(Constants.TextPrimary)
                }
                .font(.app(.subheadline, weight: .semibold))
                .padding(.top, Spacing.md)
            }
            .cardStyle()

            HStack(alignment: .top, spacing: Spacing.md) {
                AppIconTile(size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Zero Bite").font(.app(.caption, weight: .semibold))
                        Spacer()
                        Text("now").font(.app(.caption2))
                    }
                    .foregroundStyle(Constants.TextSecondary)
                    Text("Spinach goes off tomorrow").font(.app(.subheadline, weight: .semibold)).foregroundStyle(Constants.TextPrimary)
                    Text("It's in 3 recipes you can make tonight.").font(.app(.caption)).foregroundStyle(Constants.TextSecondary)
                }
            }
            .cardStyle()
            .padding(.horizontal, Spacing.md)
        }
        .accessibilityHidden(true)
    }
}

private struct CookIllustration: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Constants.BrandOrange.opacity(0.14))
                .frame(height: 120)
                .overlay {
                    Image(systemName: "frying.pan.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(Constants.BrandOrange)
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Spinach and egg frittata").font(.app(.headline, weight: .semibold)).foregroundStyle(Constants.TextPrimary)
                    Spacer()
                    Text("92%").font(.app(.headline, weight: .semibold)).foregroundStyle(Constants.BrandOrange)
                }
                Text("20 min · serves 2 · uses 2 expiring").font(.app(.caption)).foregroundStyle(Constants.TextSecondary)
                HStack(spacing: 6) {
                    Tag(text: "Spinach", tint: Constants.BrandOrange)
                    Tag(text: "Eggs", tint: Constants.BrandOrange)
                    Tag(text: "+3")
                }
                .padding(.top, 6)
            }
            .padding(Spacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .cardStyle(padding: 0)
        .accessibilityHidden(true)
    }
}

private struct RemindersIllustration: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            reminderRow(when: "3 days before", text: "Greek yogurt is due on Friday", tint: Constants.StatusSoon)
            reminderRow(when: "On the day", text: "Use your spinach today", tint: Constants.StatusToday)
            reminderRow(when: "Day after", text: "Milk went past its date yesterday", tint: Constants.StatusExpired)
        }
        .accessibilityHidden(true)
    }

    private func reminderRow(when: String, text: String, tint: Color) -> some View {
        HStack(spacing: Spacing.md) {
            IconTile(symbol: "bell.fill", tint: tint, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Overline(when, tint: tint)
                Text(text).font(.app(.subheadline, weight: .medium)).foregroundStyle(Constants.TextPrimary)
            }
            Spacer()
        }
        .cardStyle(accent: tint)
    }
}

#Preview("First run") {
    WelcomeFactory.make(dependencies: .preview(), onComplete: {})
}

#Preview("Replay") {
    WelcomeFactory.make(mode: .replay, dependencies: .preview(), onComplete: {})
}
