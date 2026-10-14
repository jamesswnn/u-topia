//
//  CurrencyHeaderView.swift
//  u_topia
//

import SwiftUI
import UIKit

public struct CurrencyHeaderView: View {
    @Binding var priceCurrencyCode: String
    @Binding var changeCurrencyCode: String
    var isPriceCurrencyLocked = false

    public init(priceCurrencyCode: Binding<String>, changeCurrencyCode: Binding<String>, isPriceCurrencyLocked: Bool = false) {
        _priceCurrencyCode = priceCurrencyCode
        _changeCurrencyCode = changeCurrencyCode
        self.isPriceCurrencyLocked = isPriceCurrencyLocked
    }

    public var body: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(CurrencyOption.common) { currency in
                    Button("\(currency.code) · \(currency.name)") { priceCurrencyCode = currency.code }
                }
            } label: {
                currencyPill("Price", code: priceCurrencyCode, isDestination: false)
            }
            .disabled(isPriceCurrencyLocked)
            .opacity(isPriceCurrencyLocked ? 0.65 : 1)
            Image(systemName: "arrow.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Menu {
                ForEach(CurrencyOption.common) { currency in
                    Button("\(currency.code) · \(currency.name)") { changeCurrencyCode = currency.code }
                }
            } label: {
                currencyPill("To", code: changeCurrencyCode, isDestination: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func currencyPill(_ title: String, code: String, isDestination: Bool) -> some View {
        HStack(spacing: 5) {
            Text(title).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            Text(code).font(.system(size: 15, weight: .bold)).foregroundStyle(isDestination ? Color.blue : Color.primary)
            Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                .foregroundStyle(isDestination ? Color.blue : Color.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(isDestination ? Color.blue.opacity(0.12) : Color.primary.opacity(0.06))
                .overlay(Capsule().stroke(isDestination ? Color.blue.opacity(0.5) : Color.primary.opacity(0.25), lineWidth: 1.25))
        }
        .contentShape(Capsule())
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255, opacity: alpha)
    }

    static var appBackground: Color { Color(uiColor: .systemGroupedBackground) }
    static var appCard: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    static var appRow: Color { Color(uiColor: .secondarySystemBackground) }
}
