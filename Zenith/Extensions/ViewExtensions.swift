//
//  ViewExtensions.swift
//  Zenith
//
//  Created by Shahmeer on 1/31/26.
//

import SwiftUI

public extension View {
  /// Modify a view with a `ViewBuilder` closure.
  ///
  /// This represents a streamlining of the
  /// [`modifier`](https://developer.apple.com/documentation/swiftui/view/modifier(_:))
  /// \+ [`ViewModifier`](https://developer.apple.com/documentation/swiftui/viewmodifier)
  /// pattern.
  /// - Note: Useful only when you don't need to reuse the closure.
  /// If you do, turn the closure into an extension! ♻️
  func modifier<ModifiedContent: View>(
    @ViewBuilder body: (_ content: Self) -> ModifiedContent
  ) -> ModifiedContent {
    body(self)
  }
}

public extension View {
    func blurredView() -> some View {
        self.modifier(BlurredView())
    }
}

private struct BlurredView: ViewModifier {
    @State private var height: CGFloat = 300
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.surfaceBackground.opacity(0.1),
                            Color.surfaceBackground.opacity(0.7),
                            Color.surfaceBackground.opacity(0.9),
                            Color.surfaceBackground,
                            Color.surfaceBackground,
                            Color.surfaceBackground,
                            Color.surfaceBackground
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
                .frame(height: height)
            
            content
                .onGeometryChange(for: CGSize.self) { geometry in
                    geometry.size
                } action: { newValue in
                    height = newValue.height
                }
        }
    }
}
