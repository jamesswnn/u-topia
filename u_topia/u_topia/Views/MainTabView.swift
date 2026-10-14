//
//  MainTabView.swift
//  u_topia
//

import SwiftUI

public struct MainTabView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @StateObject private var cameraManager = CameraManager()

    public init() {}

    public var body: some View {
        TabView(selection: $viewModel.activeTab) {
            ScannerFlowContainer(viewModel: viewModel, cameraManager: cameraManager)
                .tabItem { Label("Price tag", systemImage: "tag") }
                .tag(AppTab.priceTag)
            Screen5_HistoryView(viewModel: viewModel)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(AppTab.history)
            FavoriteListView(viewModel: viewModel)
                .tabItem { Label("Favorite", systemImage: "bookmark") }
                .tag(AppTab.favorite)
        }
        .overlay(alignment: .topTrailing) {
            Button { viewModel.isSettingsPresented = true } label: {
                Image(systemName: "textformat.size")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: Circle())
            }
            .accessibilityLabel("Text settings")
            .padding(.top, 8)
            .padding(.trailing, 16)
        }
        .overlay(alignment: .bottom) {
            if viewModel.activeTab == .priceTag {
                scannerDock
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.activeTab)
        .sheet(isPresented: $viewModel.isManualAmountPresented) {
            Screen4_AdjustAmountView(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .sheet(isPresented: $viewModel.isSettingsPresented) { TextSettingsView(viewModel: viewModel).presentationDetents([.medium]) }
        .sheet(isPresented: $viewModel.isCartPresented) {
            CartView(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .alert("Add another item?", isPresented: $viewModel.isDuplicateCartItemAlertPresented) {
            Button("Keep as separate item") { viewModel.addPendingCartItem() }
                .tint(.blue)
            Button("Add 1 to existing item") { viewModel.addDuplicateToCartAsAnotherUnit() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("A product with this price is already in your cart. Add 1 to its quantity or keep it separate.")
        }
        .tint(.blue)
        .onAppear { cameraManager.startSession() }
        .onChange(of: viewModel.activeTab) { _, tab in
            if tab == .priceTag {
                cameraManager.startSession()
                updateLiveGuideTracking()
            } else {
                cameraManager.isLiveGuideTrackingEnabled = false
                cameraManager.stopSession()
            }
        }
        .onChange(of: viewModel.currentStep) { _, _ in updateLiveGuideTracking() }
        .onChange(of: viewModel.isPriceCardVisible) { _, _ in updateLiveGuideTracking() }
        .onChange(of: viewModel.isTenderedCardVisible) { _, _ in updateLiveGuideTracking() }
        .onChange(of: viewModel.isCoinCardVisible) { _, _ in updateLiveGuideTracking() }
        .onChange(of: viewModel.isOCRRunning) { _, _ in updateLiveGuideTracking() }
        .onDisappear {
            cameraManager.isLiveGuideTrackingEnabled = false
            cameraManager.stopSession()
        }
    }

    private var scannerDock: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                Color.clear.frame(width: 48, height: 48).accessibilityHidden(true)
                Spacer(minLength: 0)
                ZStack {
                if (viewModel.currentStep == .tenderedScan && viewModel.isTenderedCardVisible) ||
                    (viewModel.currentStep == .coinScan && viewModel.isCoinCardVisible) {
                    Button(action: viewModel.onDockCloseTapped) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 58, height: 58)
                            .background(Circle().fill(.white))
                    }
                    .accessibilityLabel("Close and return to Price tag")
                } else {
                    Button {
                        if viewModel.currentStep == .priceTagScan && viewModel.isPriceCardVisible {
                            viewModel.resetPriceScan()
                        } else {
                            captureAmount()
                        }
                    } label: {
                        ZStack {
                            Circle().stroke(.white.opacity(0.9), lineWidth: 3.5).frame(width: 64, height: 64)
                            Circle().fill(.white).frame(width: 52, height: 52)
                            if viewModel.currentStep == .priceTagScan && viewModel.isPriceCardVisible {
                                Image(systemName: "arrow.counterclockwise.circle")
                                    .font(.system(size: 25, weight: .semibold)).foregroundStyle(.black)
                            }
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(viewModel.isOCRRunning)
                    .accessibilityLabel(viewModel.isOCRRunning ? "Reading amount" : (viewModel.currentStep == .priceTagScan && viewModel.isPriceCardVisible ? "Scan another price" : "Scan amount"))
                }
            }
                Spacer(minLength: 0)
                cartButton.frame(width: 48, height: 48)
            }
            .padding(.horizontal, 16)

            if viewModel.currentStep == .priceTagScan || viewModel.currentStep == .tenderedScan ||
                (viewModel.currentStep == .coinScan && !viewModel.isCoinCardVisible) {
                Button("Enter amount") {
                    let target: ManualAmountTarget
                    switch viewModel.currentStep {
                    case .priceTagScan: target = .price
                    case .tenderedScan: target = .tendered
                    case .coinScan: target = .coins
                    }
                    viewModel.openManualAmountEntry(for: target)
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundStyle(.primary)
            }
        }
        .padding(.bottom, 84)
    }

    private var cartButton: some View {
        Button { viewModel.isCartPresented = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .glassEffect(.regular.interactive(), in: Circle())
                if !viewModel.cartItems.isEmpty {
                    Text("\(viewModel.cartItems.reduce(0) { $0 + $1.quantity })")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Color(hex: 0x6DA3FF), in: Circle())
                        .offset(x: 3, y: -3)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .contentShape(Rectangle())
        .zIndex(2)
        .accessibilityLabel("Cart, \(viewModel.cartItems.reduce(0) { $0 + $1.quantity }) items")
    }

    private func captureAmount() {
        viewModel.isOCRRunning = true
        cameraManager.captureAmount { result in
            viewModel.isOCRRunning = false
            viewModel.captureRecognizedAmount(result.amount, imageData: result.imageData)
        }
    }

    private func updateLiveGuideTracking() {
        guard viewModel.activeTab == .priceTag, !viewModel.isOCRRunning else {
            cameraManager.isLiveGuideTrackingEnabled = false
            return
        }
        switch viewModel.currentStep {
        case .priceTagScan:
            cameraManager.isLiveGuideTrackingEnabled = !viewModel.isPriceCardVisible
        case .tenderedScan:
            cameraManager.isLiveGuideTrackingEnabled = !viewModel.isTenderedCardVisible
        case .coinScan:
            cameraManager.isLiveGuideTrackingEnabled = !viewModel.isCoinCardVisible
        }
    }

}

private struct ScannerFlowContainer: View {
    @ObservedObject var viewModel: ScannerViewModel
    @ObservedObject var cameraManager: CameraManager
    var body: some View {
        ZStack(alignment: .top) {
            CameraPreviewView(cameraManager: cameraManager)
            Group {
                switch viewModel.currentStep {
                case .priceTagScan:
                    Screen1_PriceScanView(viewModel: viewModel, cameraManager: cameraManager)
                case .tenderedScan:
                    Screen2_TenderedScanView(viewModel: viewModel, cameraManager: cameraManager)
                case .coinScan:
                    Screen3_CoinScanView(viewModel: viewModel, cameraManager: cameraManager)
                }
            }
            .id(viewModel.currentStep)
            .transition(.opacity)
            if let message = viewModel.scanMessage {
                Text(message).font(.callout.weight(.semibold)).foregroundStyle(.primary)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule()).padding(.top, 58)
            }
        }
        .animation(.smooth(duration: 0.25), value: viewModel.currentStep)
    }
}

private struct TextSettingsView: View {
    @ObservedObject var viewModel: ScannerViewModel
    var body: some View {
        NavigationStack {
            Form {
                Section("Text") {
                    Toggle("Larger text", isOn: Binding(get: { viewModel.isLargeText }, set: { viewModel.setTextSize(large: $0) }))
                    Toggle("Bold text", isOn: Binding(get: { viewModel.isBoldText }, set: { viewModel.setBoldText($0) }))
                }
                Text("Your choices are saved on this iPad.").font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Text settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct FavoriteListView: View {
    @ObservedObject var viewModel: ScannerViewModel
    var body: some View {
        NavigationStack {
            List {
                if viewModel.favoriteItems.isEmpty {
                    ContentUnavailableView("No favorites yet", systemImage: "bookmark", description: Text("Save a price with the bookmark on its scan card."))
                }
                ForEach(viewModel.favoriteItems) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ExchangeRateService.format(item.price, currencyCode: item.currencyCode, decimals: 0))
                            .font(.system(size: 21 * viewModel.fontScale, weight: viewModel.isBoldText ? .bold : .semibold))
                        if let paid = item.tendered {
                            Text("Paid: \(ExchangeRateService.format(paid, currencyCode: item.currencyCode, decimals: 0))")
                                .font(.system(size: 16 * viewModel.fontScale, weight: viewModel.isBoldText ? .bold : .regular)).foregroundStyle(.secondary)
                        }
                        if let expected = item.expectedChange {
                            Text("Expected change: \(ExchangeRateService.format(expected, currencyCode: item.currencyCode, decimals: 0))")
                                .font(.system(size: 16 * viewModel.fontScale, weight: viewModel.isBoldText ? .bold : .regular)).foregroundStyle(.secondary)
                        }
                        if let received = item.receivedChange, let code = item.changeCurrencyCode {
                            Text("Change received: \(ExchangeRateService.format(received, currencyCode: code, decimals: 0))")
                                .font(.system(size: 17 * viewModel.fontScale, weight: viewModel.isBoldText ? .bold : .regular)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.appCard))
                    .listRowBackground(Color.appBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    .swipeActions { Button("Remove", systemImage: "trash", role: .destructive) { viewModel.removeFavorite(item) } }
                }
                .onDelete(perform: viewModel.deleteFavorite)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Favorite")
        }
    }
}
