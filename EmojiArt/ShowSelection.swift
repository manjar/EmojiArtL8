//
//  ShowSelection.swift
//  EmojiArt
//
//  Created by Eli Manjarrez on 11/17/20.
//  Copyright © 2020 CS193p Instructor. All rights reserved.
//

import SwiftUI

struct ShowSelection: ViewModifier {
    var isSelected: Bool
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack {
                content
                Rectangle()
                    .stroke(lineWidth: 3.0)
                    .frame(width: 100, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, alignment: .center)
                    .opacity(isSelected ? 1.0 : 0.0)
            }
        }
    }
}

extension View {
    func showSelection(isSelected: Bool) -> some View {
        self.modifier(ShowSelection(isSelected: isSelected))
    }
}

