//
//  Screen4_AdjustAmountView.swift
//  u_topia
//

import SwiftUI
import UIKit

public struct Screen4_AdjustAmountView: View {
    @ObservedObject var viewModel: ScannerViewModel
    public init(viewModel: ScannerViewModel) { self.viewModel = viewModel }

    public var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Amount · \(viewModel.priceCurrencyCode)").font(.system(size: 16 * viewModel.fontScale, weight: .semibold)).foregroundStyle(.primary)
                    Spacer()
                    Button("Cancel") { viewModel.isManualAmountPresented = false }.foregroundStyle(Color.utopiaBlue)
                }
                .padding(.horizontal, 24).padding(.top, 16)
                Spacer()
                VStack(spacing: 8) {
                    Text("\(viewModel.priceCurrency.symbol)\(viewModel.keypadInput)")
                        .font(.system(size: 42 * viewModel.fontScale, weight: viewModel.isBoldText ? .heavy : .bold)).foregroundStyle(.primary)
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text("≈ \(ExchangeRateService.format(viewModel.keypadAmount * viewModel.conversionRate, currencyCode: viewModel.changeCurrencyCode))")
                        .font(.system(size: 15 * viewModel.fontScale)).foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                HStack(spacing: 12) {
                    QuickChipButton(title: "+100") { viewModel.onQuickAdd(100) }
                    QuickChipButton(title: "+10") { viewModel.onQuickAdd(10) }
                    QuickChipButton(title: "Clear", isClear: true) { viewModel.onKeypadClear() }
                }
                Spacer()
                VStack(spacing: 14) {
                    ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [".", "0", "⌫"]], id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(row, id: \.self) { key in
                                Button {
                                    if key == "⌫" { viewModel.onKeypadDelete() } else { viewModel.onKeypadDigit(key) }
                                } label: {
                                    Text(key).font(.system(size: 28 * viewModel.fontScale, weight: viewModel.isBoldText ? .bold : .regular))
                                        .foregroundStyle(.primary).frame(maxWidth: .infinity).frame(height: 58)
                                }
                                .buttonStyle(.glass)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 14)
                Button(action: viewModel.onKeypadConfirm) {
                    Text(viewModel.manualAmountTarget == .coins ? "Save and finish" : "Confirm")
                        .font(.system(size: 17 * viewModel.fontScale, weight: .bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.glassProminent).tint(Color.utopiaBlue).padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
    }
}

private struct QuickChipButton: View {
    let title: String
    var isClear = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isClear ? Color.red : Color.primary)
                .padding(.horizontal, 17).padding(.vertical, 9)
        }
        .buttonStyle(.glass)
    }
}
