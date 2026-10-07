//
//  AppTabBar.swift
//  ZeroBite
//
//  Full-width flat tab bar modelled on drivvy-ios' CustomTabBar: hairline on top, icon + label
//  per tab, and a short indicator that slides along the top edge to the selected tab.
//

import SwiftUI

struct AppTabBar: View {
    @Binding var selection: AppCoordinator.AppTab
    var tabs: [AppCoordinator.AppTab] = AppCoordinator.AppTab.allCases

    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                let isSelected = tab == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: isSelected ? tab.selectedSymbol : tab.symbol)
                            .font(.system(size: 21, weight: isSelected ? .semibold : .regular))
                            .frame(height: 24)
                        Text(tab.title)
                            .font(.app(.caption2, weight: isSelected ? .semibold : .medium))
                    }
                    .foregroundStyle(isSelected ? Constants.TextPrimary : Constants.TextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                    .overlay(alignment: .top) {
                        if isSelected {
                            Rectangle()
                                .fill(Constants.BrandOrange)
                                .frame(width: 44, height: 3)
                                .matchedGeometryEffect(id: "indicator", in: indicator)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("tab.\(tab.title.lowercased())")
            }
        }
        .background(alignment: .top) {
            Constants.BackgroundPrimary
                .overlay(alignment: .top) { Rectangle().fill(Constants.Hairline).frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    @Previewable @State var selection = AppCoordinator.AppTab.fridge
    VStack {
        Spacer()
        AppTabBar(selection: $selection)
    }
    .pageBackground()
}
