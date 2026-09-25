//
//  SplashView.swift
//  ZeroWaste
//

import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Constants.BackgroundSecondary.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Constants.Brand)
                Text("Zero Waste")
                    .font(.app(.largeTitle, weight: .bold))
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
