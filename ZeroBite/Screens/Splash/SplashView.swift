//
//  SplashView.swift
//  ZeroBite
//

import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Constants.BackgroundPrimary.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                BrandMark()
                    .frame(width: 112, height: 112)
                Text("Zero Bite")
                    .font(.app(.largeTitle, weight: .semibold))
                    .tracking(-1)
                    .foregroundStyle(Constants.TextPrimary)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            onFinish()
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
