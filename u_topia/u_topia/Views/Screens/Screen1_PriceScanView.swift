//
//  Screen1_PriceScanView.swift
//  u_topia
//

import SwiftUI

public struct Screen1_PriceScanView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @ObservedObject var cameraManager: CameraManager
    public init(viewModel: ScannerViewModel, cameraManager: CameraManager) { self.viewModel = viewModel; self.cameraManager = cameraManager }

    public var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            VStack(spacing: 0) {
                CurrencyHeaderView(priceCurrencyCode: $viewModel.priceCurrencyCode, changeCurrencyCode: $viewModel.changeCurrencyCode,
                                   isPriceCurrencyLocked: !viewModel.cartItems.isEmpty)
                    .onChange(of: viewModel.priceCurrencyCode) { _, _ in viewModel.selectCurrencies(price: viewModel.priceCurrencyCode, change: viewModel.changeCurrencyCode) }
                    .onChange(of: viewModel.changeCurrencyCode) { _, _ in viewModel.selectCurrencies(price: viewModel.priceCurrencyCode, change: viewModel.changeCurrencyCode) }
                Text("Scan price").font(.system(size: 17 * viewModel.fontScale, weight: viewModel.isBoldText ? .bold : .semibold)).foregroundStyle(.primary).padding(.top, 14)
                Spacer(minLength: 12)
                if viewModel.isPriceCardVisible { priceCard.padding(.bottom, 12).transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
            .padding(.bottom, 108)
            LiveScanGuideView(cameraManager: cameraManager,
                              instruction: "Point at the price and tap Scan",
                              guideWidth: 170,
                              isVisible: !viewModel.isPriceCardVisible && !viewModel.isOCRRunning,
                              fontScale: viewModel.fontScale,
                              isBoldText: viewModel.isBoldText)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(1)
            if viewModel.isOCRRunning { ProgressView("Reading price…").tint(.primary).padding(14).background(.regularMaterial, in: Capsule()) }
        }
        .animation(.snappy(duration: 0.35), value: viewModel.isPriceCardVisible)
    }

    private var priceCard: some View {
        VStack(spacing: 12) {
            HStack {
                Button { viewModel.openManualAmountEntry(for: .price) } label: { Label("Edit", systemImage: "pencil").font(.system(size: 13 * viewModel.fontScale, weight: .semibold)) }
                    .accessibilityLabel("Edit detected price")
                Spacer()
                Button(action: viewModel.toggleFavorite) {
                    Image(systemName: viewModel.isCurrentPriceFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 19, weight: .semibold)).foregroundStyle(viewModel.isCurrentPriceFavorite ? Color.orange : Color.primary)
                }
                .accessibilityLabel(viewModel.isCurrentPriceFavorite ? "Remove favorite" : "Save favorite")
            }
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                Text("PRICE FOUND").font(.system(size: 11 * viewModel.fontScale, weight: .bold)).foregroundStyle(.secondary)
                    Text(ExchangeRateService.format(viewModel.detectedPrice, currencyCode: viewModel.priceCurrencyCode, decimals: 0))
                        .font(.system(size: 30 * viewModel.fontScale, weight: viewModel.isBoldText ? .heavy : .bold)).foregroundStyle(.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("CONVERTED").font(.system(size: 11 * viewModel.fontScale, weight: .bold)).foregroundStyle(.secondary)
                    if viewModel.isLoadingRate { ProgressView().tint(Color.utopiaBlue) }
                    else if viewModel.rateUnavailable { Text("—").font(.system(size: 25 * viewModel.fontScale, weight: .bold)).foregroundStyle(.secondary) }
                    else { Text(ExchangeRateService.format(viewModel.convertedPrice, currencyCode: viewModel.changeCurrencyCode, decimals: 2))
                        .font(.system(size: 25 * viewModel.fontScale, weight: viewModel.isBoldText ? .heavy : .bold)).foregroundStyle(Color.utopiaBlue) }
                }
            }
            TextField("Item name", text: $viewModel.detectedProductName)
                .font(.system(size: 15 * viewModel.fontScale))
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Scanned product name")
            if viewModel.isLoadingRate { ProgressView("Loading exchange rate…").tint(Color.utopiaBlue).frame(maxWidth: .infinity, alignment: .leading) }
            else if viewModel.rateUnavailable { Text("Exchange rate unavailable. Check your internet connection.").font(.footnote).foregroundStyle(.orange).frame(maxWidth: .infinity, alignment: .leading) }
            Button(action: viewModel.requestAddCurrentPriceToCart) {
                Label("Add to cart", systemImage: "cart.badge.plus")
                    .font(.system(size: 16 * viewModel.fontScale, weight: .bold))
                    .foregroundStyle(Color.utopiaBlue)
                    .frame(maxWidth: .infinity).frame(minHeight: 46).padding(.vertical, 6)
            }
            .buttonStyle(.glass).tint(Color.utopiaBlue)
            Button(action: viewModel.goToChang) {
                HStack { Text("Calculate change"); Image(systemName: "arrow.right") }
                    .font(.system(size: 17 * viewModel.fontScale, weight: .bold))
                    .foregroundStyle(.white).frame(maxWidth: .infinity).frame(minHeight: 54)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent).tint(Color.utopiaBlue)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.appCard).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.12), lineWidth: 1)))
        .padding(.horizontal, 16)
    }
}
