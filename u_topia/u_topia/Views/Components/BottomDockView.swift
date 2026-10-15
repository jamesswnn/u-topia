//
//  BottomDockView.swift
//  u_topia
//

import SwiftUI

public struct BottomDockView: View {
    let mode: BottomDockMode
    let onShutterTapped: () -> Void
    
    public init(
        mode: BottomDockMode,
        onShutterTapped: @escaping () -> Void
    ) {
        self.mode = mode
        self.onShutterTapped = onShutterTapped
    }
    
    public var body: some View {
        HStack(spacing: 24) {
            // Price Tag Mode Pill
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Price tag")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(mode == .priceTag ? .white : Color.white.opacity(0.55))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(mode == .priceTag ? Color.utopiaBlue : Color.clear)
            )
            
            // Central Camera Shutter Button
            Button(action: onShutterTapped) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: 3.5)
                        .frame(width: 58, height: 58)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Cash Mode Pill
            HStack(spacing: 6) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Cash")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(mode == .cash ? .white : Color.white.opacity(0.55))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(mode == .cash ? Color.utopiaBlue : Color.clear)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(white: 0.12, opacity: 0.90))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
        )
        .padding(.bottom, 12)
    }
}

public struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
