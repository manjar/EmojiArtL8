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
    var position: CGPoint
    var fontSize: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            content
            Rectangle()
                .stroke(lineWidth: 3.0)
                .opacity(isSelected ? 1.0 : 0.0)
                .frame(width: fontSize, height: fontSize, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                .position(position)
        }
    }
}

extension View {
    func showSelection(isSelected: Bool, atPosition position: CGPoint, withFontSize fontSize: CGFloat) -> some View {
        self.modifier(ShowSelection(isSelected: isSelected, position: position, fontSize: fontSize))
    }
}

