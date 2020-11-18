//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        VStack {
            HStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: self.defaultEmojiSize))
                                .onDrag { NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
                Button("🗑") {
                    deleteSelectedEmojis()
                }
            }
            .padding(.horizontal)
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                    .onTapGesture() {
                        deselectAllEmojis()
                    }
                        .gesture(self.doubleTapToZoom(in: geometry.size))
                    ForEach(self.document.emojis) { emoji in
                        Text(emoji.text)
                            .font(animatableWithSize: emoji.fontSize * zoomScaleForEmoji(emoji))
                            .position(self.position(for: emoji, in: geometry.size))
                            .onTapGesture() {
                                toggleSelection(forEmoji: emoji)
                            }
                            .showSelection(isSelected: isSelected(forEmoji: emoji), atPosition:self.position(for: emoji, in: geometry.size), withFontSize: emoji.fontSize * self.emojiZoomScale)
                            .simultaneousGesture(self.emojisPanGesture())
                    }
                }
                .clipped()
                .gesture(self.backgroundPanGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
                    // SwiftUI bug (as of 13.4)? the location is supposed to be in our coordinate system
                    // however, the y coordinate appears to be in the global coordinate system
                    var location = CGPoint(x: location.x, y: geometry.convert(location, from: .global).y)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                    return self.drop(providers: providers, at: location)
                }
            }
        }
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureBackgroundZoomScale: CGFloat = 1.0
    @GestureState private var gestureEmojisZoomScale: CGFloat = 1.0
    
    private func zoomScaleForEmoji(_ emoji: EmojiArt.Emoji) -> CGFloat {
        isSelected(forEmoji: emoji) ? emojiZoomScale : zoomScale
    }
    
    private var emojiZoomScale: CGFloat {
        steadyStateZoomScale * gestureBackgroundZoomScale * gestureEmojisZoomScale
    }

    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureBackgroundZoomScale
    }
    
    @State private var selectedEmoji = Set<EmojiArt.Emoji>()
    
    private func toggleSelection(forEmoji emoji: EmojiArt.Emoji) {
        if selectedEmoji.contains(matching: emoji) {
            selectedEmoji.remove(emoji)
        } else {
            selectedEmoji.insert(emoji)
        }
    }
    
    private func deselectAllEmojis() {
        selectedEmoji.removeAll()
    }
    
    private func isSelected(forEmoji emoji: EmojiArt.Emoji) -> Bool {
        return selectedEmoji.contains(matching: emoji)
    }
    
    private func zoomGesture() -> some Gesture {
        if (selectedEmoji.count > 0) {
            return MagnificationGesture()
                .updating($gestureEmojisZoomScale) { latestGestureScale, gestureEmojiZoomScale, transaction in
                    gestureEmojiZoomScale = latestGestureScale
                }
                .onEnded { finalGestureScale in
                    for emoji in selectedEmoji {
                        document.scaleEmoji(emoji, by: finalGestureScale)
                    }
                }
        } else {
            return MagnificationGesture()
                .updating($gestureBackgroundZoomScale) { latestGestureScale, gestureBackgroundZoomScale, transaction in
                    gestureBackgroundZoomScale = latestGestureScale
                }
                .onEnded { finalGestureScale in
                    self.steadyStateZoomScale *= finalGestureScale
                }
        }
}
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func backgroundPanGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
        }
        .onEnded { finalDragGestureValue in
            self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
        }
    }
    
    @GestureState private var emojisGesturePanOffset: CGSize = .zero
    
    private func emojisPanGesture() -> some Gesture {
        DragGesture()
            .updating($emojisGesturePanOffset) { latestDragGestureValue, emojisGesturePanOffset, transaction in
                emojisGesturePanOffset = latestDragGestureValue.translation / self.zoomScale
        }
        .onEnded { finalDragGestureValue in
            for emoji in selectedEmoji {
                document.moveEmoji(emoji, by:finalDragGestureValue.translation / zoomScale)
            }
        }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(self.document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.steadyStatePanOffset = .zero
            self.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
        
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        if selectedEmoji.contains(matching: emoji) {
            location = CGPoint(x: location.x + (emojisGesturePanOffset.width * zoomScale), y: location.y + (emojisGesturePanOffset.height * zoomScale))
        }
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private func deleteSelectedEmojis() {
        for emoji in selectedEmoji {
            document.deleteEmoji(emoji)
        }
    }
    
    private let defaultEmojiSize: CGFloat = 40
}
