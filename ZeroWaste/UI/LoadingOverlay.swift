//
//  LoadingOverlay.swift
//  ZeroWaste
//
//  Dimmed, tap-blocking overlay with a spinner and message while work is in flight.
//

import SwiftUI

private struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String

    func body(content: Content) -> some View {
        content.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().tint(.white).scaleEffect(1.3)
                        Text(message).font(.app(.subheadline)).foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.card))
                }
                .contentShape(Rectangle())
                .onTapGesture {}
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool, message: String = "Working…") -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}
