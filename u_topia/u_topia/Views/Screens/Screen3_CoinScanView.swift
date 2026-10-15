//
//  Screen3_CoinScanView.swift
//  u_topia
//

import SwiftUI

public struct Screen3_CoinScanView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @ObservedObject var cameraManager: CameraManager
    public init(viewModel: ScannerViewModel, cameraManager: CameraManager) { self.viewModel = viewModel; self.cameraManager = cameraManager }

    public var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("\(viewModel.priceCurrencyCode)  →  \(viewModel.changeCurrencyCode)")
                    .font(.system(size: 15 * viewModel.fontScale, weight: .semibold)).foregroundStyle(.primary).padding(.top, 10)
                Text("Scan change received").font(.system(size: 17 * viewModel.fontScale, weight: .semibold)).foregroundStyle(.primary).padding(.top, 14)
                Spacer()
                if viewModel.isCoinCardVisible { resultCard.padding(.bottom, 12).transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
            .padding(.bottom, 108)
            LiveScanGuideView(cameraManager: cameraManager,
                              instruction: "Point at the returned amount and tap Scan",
                              guideWidth: 170,
                              isVisible: !viewModel.isCoinCardVisible && !viewModel.isOCRRunning,
                              fontScale: viewModel.fontScale,
                              isBoldText: viewModel.isBoldText)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            if viewModel.isOCRRunning { ProgressView("Reading amount…").tint(.primary).padding(14).background(.regularMaterial, in: Capsule()) }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.isCoinCardVisible)
    }

    private var resultCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("EXPECTED").font(.system(size: 11 * viewModel.fontScale, weight: .bold)).foregroundStyle(.secondary)
                    Text(ExchangeRateService.format(viewModel.expectedChange, currencyCode: viewModel.priceCurrencyCode, decimals: 0))
                        .font(.system(size: 23 * viewModel.fontScale, weight: .bold)).foregroundStyle(.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("RECEIVED").font(.system(size: 11 * viewModel.fontScale, weight: .bold)).foregroundStyle(.secondary)
                    Text(ExchangeRateService.format(viewModel.detectedChange, currencyCode: viewModel.priceCurrencyCode, decimals: 0))
                        .font(.system(size: 23 * viewModel.fontScale, weight: .bold)).foregroundStyle(.orange)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: abs(viewModel.currentDifference) < 0.01 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                Text(abs(viewModel.currentDifference) < 0.01 ? "Correct change" : "Difference: \(ExchangeRateService.format(abs(viewModel.currentDifference), currencyCode: viewModel.priceCurrencyCode, decimals: 0))")
            }
            .font(.system(size: 15 * viewModel.fontScale, weight: .semibold))
            .foregroundStyle(abs(viewModel.currentDifference) < 0.01 ? Color.green : Color.orange)
            Button(action: viewModel.onAdjustAmountTapped) {
                Label("Adjust amount", systemImage: "pencil")
                    .font(.system(size: 16 * viewModel.fontScale, weight: .bold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(minHeight: 52)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent).tint(Color.utopiaBlue)
            Text("Close to save this transaction to History").font(.system(size: 13 * viewModel.fontScale)).foregroundStyle(.primary)
                .padding(.horizontal, 12).padding(.vertical, 7).background(.ultraThinMaterial, in: Capsule())
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.appCard).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.12), lineWidth: 1)))
        .padding(.horizontal, 16)
    }
}
