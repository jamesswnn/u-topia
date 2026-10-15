//
//  ARCoinBadgeView.swift
//  u_topia
//

import SwiftUI

public struct ARCoinBadgeView: View {
    let amount: String
    let isPrimary: Bool
    
    public init(amount: String, isPrimary: Bool = false) {
        self.amount = amount
        self.isPrimary = isPrimary
    }
    
    public var body: some View {
        ZStack {
            // AR Target Ring
            Circle()
                .stroke(isPrimary ? Color.utopiaBlue : Color.white.opacity(0.8), lineWidth: 1.5)
                .frame(width: 44, height: 44)
            
            // Subtle pulse ring
            Circle()
                .stroke(isPrimary ? Color.utopiaBlue.opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 54, height: 54)
            
            // Center indicator dot
            Circle()
                .fill(isPrimary ? Color.utopiaBlue : Color.white)
                .frame(width: 5, height: 5)
            
            // Value pill tag on top right
            Text(amount)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                        )
                )
                .offset(x: 24, y: -20)
        }
    }
}
