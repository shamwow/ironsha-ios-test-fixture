//
//  ViewExtensions.swift
//  Zenith
//
//  Created by Shahmeer on 2/2/26.
//

import SwiftUI

extension View {
    func modify<Content: View>(@ViewBuilder transform: (Self) -> Content) -> Content {
        transform(self)
    }
}
