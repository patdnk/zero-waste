//
//  TopBar.swift
//  ZeroBite
//
//  Replaces the system navigation bar on pushed screens and sheets with square header buttons
//  that match the rest of the app, pinned above the scrolling content.
//

import SwiftUI
import UIKit

enum TopBarLeading {
    /// Pops the current screen.
    case back
    /// Closes a sheet or flow.
    case close(() -> Void)
    case none
}

struct TopBar<Trailing: View>: View {
    let leading: TopBarLeading
    @ViewBuilder var trailing: () -> Trailing

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: Spacing.sm) {
            switch leading {
            case .back:
                Button { dismiss() } label: { HeaderIconButtonLabel(symbol: "chevron.left") }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("topBar.back")
            case .close(let action):
                Button(action: action) { HeaderIconButtonLabel(symbol: "xmark", bordered: false) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("topBar.close")
            case .none:
                EmptyView()
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, Spacing.gutter)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.sm)
        .background(Constants.BackgroundPrimary)
    }
}

extension View {
    /// Hides the system navigation bar and pins a `TopBar` above the content.
    func topBar<Trailing: View>(_ leading: TopBarLeading, @ViewBuilder trailing: @escaping () -> Trailing) -> some View {
        self
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                TopBar(leading: leading, trailing: trailing)
            }
    }

    func topBar(_ leading: TopBarLeading) -> some View {
        topBar(leading) { EmptyView() }
    }
}

// Hiding the navigation bar also disables the edge-swipe back gesture; re-enable it whenever
// there is something to pop back to.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
