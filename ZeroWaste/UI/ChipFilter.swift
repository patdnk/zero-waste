//
//  ChipFilter.swift
//  ZeroWaste
//
//  Horizontally scrolling single-select chips; replaces the segmented picker.
//

import SwiftUI

struct ChipFilter<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection
                    Button {
                        withAnimation(.snappy(duration: 0.2)) { selection = option }
                    } label: {
                        Text(title(option))
                            .font(.app(.subheadline, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Constants.OnInk : Constants.TextSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                isSelected ? Constants.TextPrimary : Constants.ChipFill,
                                in: RoundedRectangle(cornerRadius: Radius.control)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Spacing.gutter)
        }
        .scrollClipDisabled()
        .padding(.horizontal, -Spacing.gutter)
    }
}

/// Small static tag (ingredient names, recipe tags).
struct Tag: View {
    let text: String
    var tint: Color?

    var body: some View {
        Text(text)
            .font(.app(.caption, weight: .medium))
            .foregroundStyle(tint ?? Constants.TextSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background((tint?.opacity(0.12)) ?? Constants.ChipFill, in: RoundedRectangle(cornerRadius: Radius.control))
    }
}

#Preview {
    @Previewable @State var selection = "All"
    VStack(alignment: .leading) {
        ChipFilter(options: ["All", "Fridge", "Freezer", "Cupboard"], selection: $selection) { $0 }
        HStack { Tag(text: "Spinach", tint: Constants.BrandOrange); Tag(text: "+3") }
    }
    .padding()
    .pageBackground()
}
