//
//  Screen2_TenderedScanView.swift
//  u_topia
//

import SwiftUI

public struct Screen2_TenderedScanView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @ObservedObject var cameraManager: CameraManager
    public init(viewModel: ScannerViewModel, cameraManager: CameraManager) { self.viewModel = viewModel; self.cameraManager = cameraManager }

    public var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("\(viewModel.priceCurrencyCode)  →  \(viewModel.changeCurrencyCode)")
                    .font(.system(size: 15 * viewModel.fontScale, weight: .semibold)).foregroundStyle(.primary).padding(.top, 10)
                Text("Scan amount paid").font(.system(size: 17 * viewModel.fontScale, weight: .semibold)).foregroundStyle(.primary).padding(.top, 14)
                Spacer()
                if viewModel.isTenderedCardVisible { tenderedCard.padding(.bottom, 12).transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
            .padding(.bottom, 108)
            LiveScanGuideView(cameraManager: cameraManager,
                              instruction: "Point at the amount paid and tap Scan",
                              guideWidth: 170,
                              isVisible: !viewModel.isTenderedCardVisible && !viewModel.isOCRRunning,
                              fontScale: viewModel.fontScale,
                              isBoldText: viewModel.isBoldText)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            if viewModel.isOCRRunning { ProgressView("Reading amount…").tint(.primary).padding(14).background(.regularMaterial, in: Capsule()) }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.isTenderedCardVisible)
    }

    private var tenderedCard: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                Button { viewModel.openManualAmountEntry(for: .tendered) } label: { Label("Edit", systemImage: "pencil").font(.system(size: 13 * viewModel.fontScale, weight: .semibold)) }
                    .foregroundStyle(Color.utopiaBlue).accessibilityLabel("Edit detected amount paid")
            }
            valueRow("Price", value: viewModel.detectedPrice, currency: viewModel.priceCurrencyCode, bold: false)
            valueRow("Amount paid", value: viewModel.tenderedAmount, currency: viewModel.priceCurrencyCode, bold: true)
            Divider()
            HStack(alignment: .center) {
                Text("Expected change").font(.system(size: 17 * viewModel.fontScale, weight: .bold)).foregroundStyle(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(ExchangeRateService.format(viewModel.expectedChange, currencyCode: viewModel.priceCurrencyCode, decimals: 0))
                        .font(.system(size: 28 * viewModel.fontScale, weight: .heavy)).foregroundStyle(.primary)
                    Text("≈ \(ExchangeRateService.format(viewModel.convertedExpectedChange, currencyCode: viewModel.changeCurrencyCode))")
                        .font(.system(size: 14 * viewModel.fontScale, weight: .semibold)).foregroundStyle(Color.utopiaBlue)
                }
            }
            Button(action: viewModel.onVerifyChangeTapped) {
                HStack {
                    Text(viewModel.expectedChange == 0 ? "Finish" : "Verify change")
                    Image(systemName: viewModel.expectedChange == 0 ? "checkmark" : "arrow.right")
                }
                    .font(.system(size: 17 * viewModel.fontScale, weight: .bold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(minHeight: 56)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent).tint(Color.utopiaBlue)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.appCard).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.12), lineWidth: 1)).shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8))
        .padding(.horizontal, 16)
    }

    private func valueRow(_ title: String, value: Double, currency: String, bold: Bool) -> some View {
        HStack {
            Text(title).font(.system(size: 15 * viewModel.fontScale, weight: .medium)).foregroundStyle(.secondary)
            Spacer()
            Text(ExchangeRateService.format(value, currencyCode: currency, decimals: 0))
                .font(.system(size: 16 * viewModel.fontScale, weight: bold ? .bold : .semibold)).foregroundStyle(bold ? Color.utopiaBlue : Color.primary)
        }
    }
}
