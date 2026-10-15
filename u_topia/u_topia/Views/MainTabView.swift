//
//  MainTabView.swift
//  u_topia
//

import SwiftUI

private enum MainSection: String, CaseIterable {
    case trip, booking, recommend, money
}

private enum ScannerModal: String, Identifiable {
    case manualAmount, cart
    var id: String { rawValue }
}

public struct MainTabView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var travelStore = TravelStore()
    @State private var selectedSection: MainSection = .trip
    @State private var isTripSheetPresented = false
    @State private var isScannerPresented = false
    @State private var scannerModal: ScannerModal?

    public init() {}

    public var body: some View {
        Group {
            switch selectedSection {
            case .trip:
                TripHomeView(travelStore: travelStore, viewModel: viewModel,
                             onOpenBooking: openBooking, onSettings: showTextSettings)
            case .booking:
                BookingView(travelStore: travelStore, viewModel: viewModel,
                            onCreateTrip: openTripComposer, onSettings: showTextSettings)
            case .recommend:
                RecommendationsView(viewModel: viewModel, onSettings: showTextSettings)
            case .money:
                MoneyDashboardView(travelStore: travelStore, viewModel: viewModel,
                                   onStartScan: startScan, onCreateTrip: openTripComposer, onSettings: showTextSettings)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { mainTabBar }
        .sheet(isPresented: $isTripSheetPresented) {
            NavigationStack {
                CreateTripView(travelStore: travelStore) {
                    selectedSection = .trip
                    isTripSheetPresented = false
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
        }
        .fullScreenCover(isPresented: $isScannerPresented) { scannerExperience }
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            TextSettingsView(viewModel: viewModel).presentationDetents([.medium])
        }
        .alert("Add another item?", isPresented: $viewModel.isDuplicateCartItemAlertPresented) {
            Button("Keep as separate item") { viewModel.addPendingCartItem() }.tint(Color.utopiaBlue)
            Button("Add 1 to existing item") { viewModel.addDuplicateToCartAsAnotherUnit() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("A product with this price is already in your cart. Add 1 to its quantity or keep it separate.")
        }
        .tint(Color.utopiaBlue)
    }

    private var mainTabBar: some View {
        HStack(spacing: 0) {
            tabButton(.trip, title: "Trip", symbol: "suitcase.rolling")
            tabButton(.booking, title: "Booking", symbol: "bed.double")
            Button {
                openTripComposer()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.utopiaBlue, in: Circle())
                    .shadow(color: Color.utopiaBlue.opacity(0.3), radius: 12, y: 6)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("New Trip")
            tabButton(.recommend, title: "Recommend", symbol: "map")
            tabButton(.money, title: "Money", symbol: "banknote")
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .glassEffect(.regular.interactive(), in: Capsule())
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private func tabButton(_ section: MainSection, title: String, symbol: String) -> some View {
        Button { selectedSection = section } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 18, weight: selectedSection == section ? .semibold : .regular))
                Text(title).font(.system(size: 10, weight: selectedSection == section ? .semibold : .medium))
            }
            .foregroundStyle(selectedSection == section ? Color.utopiaBlue : Color.secondary)
            .frame(maxWidth: .infinity).frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var scannerExperience: some View {
        ZStack(alignment: .topTrailing) {
            ScannerFlowContainer(viewModel: viewModel, cameraManager: cameraManager)
            Button { isScannerPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 12).padding(.trailing, 16)
            .accessibilityLabel("Close scanner")
        }
        .overlay(alignment: .bottom) { scannerDock }
        .onAppear {
            viewModel.tripIDForNextHistory = travelStore.selectedTripID
            viewModel.activeTab = .priceTag
            cameraManager.startSession()
            updateLiveGuideTracking()
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
        .onChange(of: viewModel.isManualAmountPresented) { _, isPresented in
            if isPresented { scannerModal = .manualAmount }
        }
        .onChange(of: viewModel.isCartPresented) { _, isPresented in
            if isPresented { scannerModal = .cart }
        }
        .sheet(item: $scannerModal, onDismiss: {
            viewModel.isManualAmountPresented = false
            viewModel.isCartPresented = false
        }) { modal in
            switch modal {
            case .manualAmount:
                Screen4_AdjustAmountView(viewModel: viewModel)
                    .presentationDetents([.large]).presentationDragIndicator(.visible).presentationCornerRadius(30)
            case .cart:
                CartView(viewModel: viewModel)
                    .presentationDetents([.large]).presentationDragIndicator(.visible).presentationCornerRadius(30)
            }
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
                            Image(systemName: "xmark").font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.black).frame(width: 58, height: 58).background(Circle().fill(.white))
                        }.accessibilityLabel("Close and return to Price tag")
                    } else {
                        Button {
                            if viewModel.currentStep == .priceTagScan && viewModel.isPriceCardVisible { viewModel.resetPriceScan() }
                            else { captureAmount() }
                        } label: {
                            ZStack {
                                Circle().stroke(.white.opacity(0.9), lineWidth: 3.5).frame(width: 64, height: 64)
                                Circle().fill(.white).frame(width: 52, height: 52)
                                if viewModel.currentStep == .priceTagScan && viewModel.isPriceCardVisible {
                                    Image(systemName: "arrow.counterclockwise.circle").font(.system(size: 25, weight: .semibold)).foregroundStyle(.black)
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle()).disabled(viewModel.isOCRRunning)
                        .accessibilityLabel(viewModel.isOCRRunning ? "Reading amount" : "Scan amount")
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
                .font(.system(size: 12, weight: .semibold)).padding(.horizontal, 12).padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule()).foregroundStyle(.primary)
            }
        }
        .padding(.bottom, 30)
    }

    private var cartButton: some View {
        Button { viewModel.isCartPresented = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "cart.fill").font(.system(size: 19, weight: .semibold)).foregroundStyle(.primary)
                    .frame(width: 48, height: 48).glassEffect(.regular.interactive(), in: Circle())
                if !viewModel.cartItems.isEmpty {
                    Text("\(viewModel.cartItems.reduce(0) { $0 + $1.quantity })")
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(.black).frame(minWidth: 18, minHeight: 18)
                        .background(Color(hex: 0x6DA3FF), in: Circle()).offset(x: 3, y: -3)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle()).accessibilityLabel("Cart, \(viewModel.cartItems.reduce(0) { $0 + $1.quantity }) items")
    }

    private func captureAmount() {
        viewModel.isOCRRunning = true
        cameraManager.captureAmount { result in
            viewModel.isOCRRunning = false
            viewModel.captureRecognizedAmount(result.amount, imageData: result.imageData)
        }
    }

    private func updateLiveGuideTracking() {
        guard isScannerPresented, !viewModel.isOCRRunning else {
            cameraManager.isLiveGuideTrackingEnabled = false
            return
        }
        switch viewModel.currentStep {
        case .priceTagScan: cameraManager.isLiveGuideTrackingEnabled = !viewModel.isPriceCardVisible
        case .tenderedScan: cameraManager.isLiveGuideTrackingEnabled = !viewModel.isTenderedCardVisible
        case .coinScan: cameraManager.isLiveGuideTrackingEnabled = !viewModel.isCoinCardVisible
        }
    }

    private func openTripComposer() {
        selectedSection = .trip
        isTripSheetPresented = true
    }
    private func openBooking() {
        isTripSheetPresented = false
        selectedSection = .booking
    }
    private func showTextSettings() { viewModel.isSettingsPresented = true }
    private func startScan() {
        viewModel.tripIDForNextHistory = travelStore.selectedTripID
        isScannerPresented = true
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
                case .priceTagScan: Screen1_PriceScanView(viewModel: viewModel, cameraManager: cameraManager)
                case .tenderedScan: Screen2_TenderedScanView(viewModel: viewModel, cameraManager: cameraManager)
                case .coinScan: Screen3_CoinScanView(viewModel: viewModel, cameraManager: cameraManager)
                }
            }
            .id(viewModel.currentStep).transition(.opacity)
            if let message = viewModel.scanMessage {
                Text(message).font(.callout.weight(.semibold)).foregroundStyle(.primary)
                    .padding(.horizontal, 16).padding(.vertical, 10).background(.ultraThinMaterial, in: Capsule()).padding(.top, 58)
            }
        }
        .animation(.smooth(duration: 0.25), value: viewModel.currentStep)
    }
}

private struct TextSettingsView: View {
    @ObservedObject var viewModel: ScannerViewModel
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Make it easy to read")
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.utopiaInk)
                        Text("Adjust text size across your trip and money screens.")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "textformat.size.smaller").font(.system(size: 15)).foregroundStyle(Color.utopiaBlue)
                            Slider(value: Binding(get: { Double(viewModel.textScale) }, set: { viewModel.setTextScale(CGFloat($0)) }), in: 0.85...1.45, step: 0.05)
                                .tint(Color.utopiaBlue)
                            Image(systemName: "textformat.size.larger").font(.system(size: 20)).foregroundStyle(Color.utopiaBlue)
                        }
                        HStack {
                            Text("Text size").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            Text("\(Int(viewModel.textScale * 100))%")
                                .font(.system(size: 13, weight: .bold, design: .rounded)).monospacedDigit()
                                .foregroundStyle(Color.utopiaBlue).contentTransition(.numericText())
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.utopiaBlue.opacity(0.09), in: Capsule())
                            Spacer()
                            if abs(viewModel.textScale - 1) > 0.001 {
                                HStack {
                                    Spacer()
                                    Button { viewModel.setTextScale(1) } label: {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color.utopiaBlue)
                                            .buttonStyle(ScaleButtonStyle())
                                    }
                                    .accessibilityLabel("Reset text size")
                                }
                            }
                        }
                    }
                    .padding(18).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 22))
                    Toggle("Bold text", isOn: Binding(get: { viewModel.isBoldText }, set: { viewModel.setBoldText($0) }))
                        .tint(Color.utopiaBlue).padding(16)
                        .background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(20)
            }
            .background(Color.utopiaCanvas.ignoresSafeArea())
            .navigationTitle("Text settings").navigationBarTitleDisplayMode(.inline)
        }
    }
}
