//
//  ScreenHeader.swift
//  ZeroWaste
//
//  Editorial screen title that replaces the system large navigation title: a small orange
//  overline, a tightly tracked title with an optional count tag, and trailing header buttons.
//

import SwiftUI

struct ScreenHeader<Trailing: View>: View {
    var overline: String?
    let title: String
    var count: Int?
    @ViewBuilder var trailing: () -> Trailing

    init(overline: String? = nil, title: String, count: Int? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.overline = overline
        self.title = title
        self.count = count
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                if let overline {
                    Overline(overline, tint: Constants.BrandOrange)
                }
                HStack(alignment: .top, spacing: 8) {
                    Text(title)
                        .font(.app(.largeTitle, weight: .semibold))
                        .tracking(-1)
                        .foregroundStyle(Constants.TextPrimary)
                        .accessibilityAddTraits(.isHeader)
                    if let count {
                        Text("\(count)")
                            .font(.app(.caption, weight: .semibold))
                            .foregroundStyle(Constants.TextSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Constants.ChipFill, in: RoundedRectangle(cornerRadius: Radius.control))
                            .padding(.top, 6)
                            .accessibilityLabel("\(count) items")
                    }
                }
            }
            Spacer(minLength: Spacing.md)
            HStack(spacing: Spacing.sm) { trailing() }
                .padding(.top, overline == nil ? 0 : 4)
        }
        .padding(.top, Spacing.sm)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(overline: String? = nil, title: String, count: Int? = nil) {
        self.init(overline: overline, title: title, count: count) { EmptyView() }
    }
}

/// Small tracked label used above titles and as section headings inside cards.
struct Overline: View {
    let text: String
    var tint: Color = Constants.TextSecondary

    init(_ text: String, tint: Color = Constants.TextSecondary) {
        self.text = text
        self.tint = tint
    }

    var body: some View {
        Text(text)
            .font(.app(.caption, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(tint)
    }
}

/// Section heading between groups of cards: label on the left, optional detail on the right.
struct SectionHeading: View {
    let title: String
    var detail: String?
    var tint: Color = Constants.TextPrimary
    var symbol: String?

    var body: some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol).font(.app(.caption, weight: .semibold))
            }
            Text(title).font(.app(.subheadline, weight: .semibold))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.app(.caption))
                    .foregroundStyle(Constants.TextSecondary)
            }
        }
        .foregroundStyle(tint)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        ScreenHeader(overline: "Tue 7 Oct", title: "Fridge", count: 14) {
            HeaderIconButtonLabel(symbol: "plus")
        }
        ScreenHeader(overline: "From your fridge", title: "Recipes")
        SectionHeading(title: "Expired", detail: "6 items", tint: Constants.StatusExpired, symbol: "xmark.octagon.fill")
    }
    .padding()
    .pageBackground()
}
