//
//  ScannerViewModel.swift
//  u_topia
//

import SwiftUI
import UIKit
import Combine

public enum ScannerStep: Int, CaseIterable { case priceTagScan = 1, tenderedScan = 2, coinScan = 3 }
public enum AppTab: Hashable { case priceTag, history, favorite }
public enum BottomDockMode { case priceTag, cash }
public enum ManualAmountTarget: Equatable { case price, tendered, coins }

public struct CartItem: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var unitPrice: Double
    public var quantity: Int
    public var currencyCode: String
    public var imageFileName: String?

    public init(id: UUID = UUID(), name: String, unitPrice: Double, quantity: Int = 1,
                currencyCode: String, imageFileName: String? = nil) {
        self.id = id; self.name = name; self.unitPrice = unitPrice; self.quantity = max(1, quantity)
        self.currencyCode = currencyCode; self.imageFileName = imageFileName
    }
    public var lineTotal: Double { unitPrice * Double(quantity) }
}

public struct FavoriteItem: Identifiable, Codable {
    public let id: UUID
    public let savedAt: Date
    public var price: Double
    public var currencyCode: String
    public var tendered: Double?
    public var expectedChange: Double?
    public var receivedChange: Double?
    public var changeCurrencyCode: String?

    public init(id: UUID = UUID(), savedAt: Date = Date(), price: Double, currencyCode: String) {
        self.id = id; self.savedAt = savedAt; self.price = price; self.currencyCode = currencyCode
        self.tendered = nil; self.expectedChange = nil; self.receivedChange = nil; self.changeCurrencyCode = nil
    }
}

public final class ScannerViewModel: ObservableObject {
    @Published public var activeTab: AppTab = .priceTag
    @Published public var currentStep: ScannerStep = .priceTagScan
    @Published public var isPriceCardVisible = false
    @Published public var isTenderedCardVisible = false
    @Published public var isCoinCardVisible = false
    @Published public var manualAmountTarget: ManualAmountTarget = .coins
    @Published public var isManualAmountPresented = false
    @Published public var isSettingsPresented = false
    @Published public var textScale: CGFloat = 1
    @Published public var isBoldText = UserDefaults.standard.bool(forKey: "uTopia.boldText")
    @Published public var priceCurrencyCode = UserDefaults.standard.string(forKey: "uTopia.priceCurrency") ?? "THB"
    @Published public var changeCurrencyCode = UserDefaults.standard.string(forKey: "uTopia.changeCurrency") ?? "USD"
    @Published public var conversionRate = 1.0
    @Published public var isLoadingRate = false
    @Published public var rateUnavailable = false
    @Published public var isOCRRunning = false
    @Published public var scanMessage: String?
    @Published public var showClearAlert = false
    @Published public var historyItems: [ScanHistoryItem] = []
    @Published public var favoriteItems: [FavoriteItem] = []
    @Published public var cartItems: [CartItem] = []
    @Published public var isCartPresented = false
    @Published public var isDuplicateCartItemAlertPresented = false
    @Published public var detectedPrice = 0.0
    @Published public var detectedProductName = "Scanned item"
    public var tripIDForNextHistory: UUID?
    @Published public var tenderedAmount = 0.0
    @Published public var detectedChange = 0.0
    @Published public var keypadInput = "0"
    private var currentFavoriteID: UUID?
    private var currentScanImageData: Data?
    private var isCartCheckout = false
    private var pendingCartAdd: (price: Double, currency: String, imageData: Data?)?
    private var rateRequestID = UUID()

    public init() {
        if let savedScale = UserDefaults.standard.object(forKey: "uTopia.textScale") as? Double {
            textScale = CGFloat(savedScale)
        } else if UserDefaults.standard.bool(forKey: "uTopia.largeText") {
            textScale = 1.2
        }
        historyItems = Self.load([ScanHistoryItem].self, key: "uTopia.history") ?? []
        favoriteItems = Self.load([FavoriteItem].self, key: "uTopia.favorites") ?? []
        cartItems = Self.load([CartItem].self, key: "uTopia.cart") ?? []
        var renamedLegacyItems = false
        for index in cartItems.indices {
            let name = cartItems[index].name
            let prefix = name.hasPrefix("สินค้า") ? "สินค้า" : (name.hasPrefix("Item ") ? "Item " : nil)
            guard let prefix, let number = Int(name.dropFirst(prefix.count)) else { continue }
            cartItems[index].name = "item \(number)"
            renamedLegacyItems = true
        }
        if renamedLegacyItems { Self.save(cartItems, key: "uTopia.cart") }
        if !UserDefaults.standard.bool(forKey: "uTopia.currencyPairV2") {
            if cartItems.isEmpty {
                priceCurrencyCode = "THB"
                changeCurrencyCode = "USD"
                UserDefaults.standard.set("THB", forKey: "uTopia.priceCurrency")
                UserDefaults.standard.set("USD", forKey: "uTopia.changeCurrency")
            }
            UserDefaults.standard.set(true, forKey: "uTopia.currencyPairV2")
        }
        if let cartCurrency = cartItems.first?.currencyCode {
            priceCurrencyCode = cartCurrency
            UserDefaults.standard.set(cartCurrency, forKey: "uTopia.priceCurrency")
        }
        loadRate()
    }

    public var priceCurrency: CurrencyOption { .option(for: priceCurrencyCode) }
    public var changeCurrency: CurrencyOption { .option(for: changeCurrencyCode) }
    public var convertedPrice: Double { detectedPrice * conversionRate }
    public var expectedChange: Double { max(0, tenderedAmount - detectedPrice) }
    public var convertedExpectedChange: Double { expectedChange * conversionRate }
    public var currentDifference: Double { detectedChange - expectedChange }
    public var keypadAmount: Double { Double(keypadInput) ?? 0 }
    public var fontScale: CGFloat { textScale }

    public func selectCurrencies(price: String, change: String) {
        guard cartItems.isEmpty || price == priceCurrencyCode else { return }
        priceCurrencyCode = price; changeCurrencyCode = change
        UserDefaults.standard.set(price, forKey: "uTopia.priceCurrency")
        UserDefaults.standard.set(change, forKey: "uTopia.changeCurrency")
        loadRate()
    }

    private func loadRate() {
        isLoadingRate = true; rateUnavailable = false
        let requestID = UUID()
        rateRequestID = requestID
        let from = priceCurrencyCode
        let to = changeCurrencyCode
        Task {
            do {
                let rate = try await ExchangeRateService.shared.rate(from: from, to: to)
                await MainActor.run {
                    guard self.rateRequestID == requestID else { return }
                    self.conversionRate = rate; self.isLoadingRate = false
                }
            } catch {
                await MainActor.run {
                    guard self.rateRequestID == requestID else { return }
                    self.conversionRate = from == to ? 1 : 0; self.rateUnavailable = true; self.isLoadingRate = false
                }
            }
        }
    }

    public func setTextScale(_ scale: CGFloat) {
        textScale = min(max(scale, 0.85), 1.45)
        UserDefaults.standard.set(Double(textScale), forKey: "uTopia.textScale")
    }
    public func setBoldText(_ bold: Bool) { isBoldText = bold; UserDefaults.standard.set(bold, forKey: "uTopia.boldText") }

    public func captureRecognizedAmount(_ amount: Double?, imageData: Data? = nil) {
        guard let amount, amount > 0 else { scanMessage = "No price found. Try again or enter the amount."; return }
        scanMessage = nil
        withAnimation(.snappy(duration: 0.22)) {
            switch currentStep {
            case .priceTagScan:
                detectedPrice = amount; detectedProductName = "Scanned item"; isPriceCardVisible = true
                currentScanImageData = imageData
                currentFavoriteID = favoriteItems.first(where: { $0.currencyCode == priceCurrencyCode && abs($0.price - amount) < 0.001 })?.id
            case .tenderedScan: tenderedAmount = amount; isTenderedCardVisible = true
            case .coinScan: detectedChange = amount; isCoinCardVisible = true
            }
        }
    }

    public func requestAddCurrentPriceToCart() {
        guard detectedPrice > 0 else { return }
        pendingCartAdd = (detectedPrice, priceCurrencyCode, currentScanImageData)
        let duplicateExists = cartItems.contains {
            $0.currencyCode == priceCurrencyCode && abs($0.unitPrice - detectedPrice) < 0.001
        }
        if duplicateExists {
            isDuplicateCartItemAlertPresented = true
        } else {
            addPendingCartItem()
        }
    }

    public func addDuplicateToCartAsAnotherUnit() {
        guard let pending = pendingCartAdd,
              let index = cartItems.firstIndex(where: {
                  $0.currencyCode == pending.currency && abs($0.unitPrice - pending.price) < 0.001
              }) else { addPendingCartItem(); return }
        cartItems[index].quantity += 1
        persistCart()
        pendingCartAdd = nil
        isDuplicateCartItemAlertPresented = false
    }

    public func addPendingCartItem() {
        guard let pending = pendingCartAdd else { return }
        let nextNumber = (cartItems.compactMap { item -> Int? in
            let prefix = item.name.hasPrefix("item ") ? "item " :
                (item.name.hasPrefix("Item ") ? "Item " : (item.name.hasPrefix("สินค้า") ? "สินค้า" : nil))
            guard let prefix else { return nil }
            return Int(item.name.dropFirst(prefix.count))
        }.max() ?? 0) + 1
        let imageFileName = pending.imageData.flatMap(saveCartImage)
        cartItems.append(CartItem(name: "item \(nextNumber)", unitPrice: pending.price,
                                  currencyCode: pending.currency, imageFileName: imageFileName))
        pendingCartAdd = nil
        isDuplicateCartItemAlertPresented = false
        persistCart()
    }

    public func updateCartItem(_ item: CartItem) {
        guard item.unitPrice > 0,
              let index = cartItems.firstIndex(where: { $0.id == item.id }) else { return }
        cartItems[index] = CartItem(id: item.id, name: item.name, unitPrice: item.unitPrice,
                                    quantity: max(1, item.quantity), currencyCode: item.currencyCode,
                                    imageFileName: item.imageFileName)
        persistCart()
    }

    public func adjustCartQuantity(for item: CartItem, by delta: Int) {
        guard let index = cartItems.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation(.snappy(duration: 0.18)) {
            let quantity = cartItems[index].quantity + delta
            if quantity < 1 { removeCartItem(at: index) }
            else { cartItems[index].quantity = quantity }
        }
        persistCart()
    }

    public func deleteCartItems(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) { removeCartItem(at: index) }
        persistCart()
    }

    public func clearCart() {
        cartItems.forEach { deleteCartImage($0.imageFileName) }
        cartItems.removeAll()
        persistCart()
    }

    public var cartTotal: Double { cartItems.reduce(0) { $0 + $1.lineTotal } }

    public func beginCartCheckout() {
        guard !cartItems.isEmpty, cartTotal > 0 else { return }
        detectedPrice = cartTotal
        tenderedAmount = 0
        detectedChange = 0
        currentFavoriteID = nil
        currentScanImageData = nil
        isPriceCardVisible = false
        isTenderedCardVisible = false
        isCoinCardVisible = false
        currentStep = .tenderedScan
        activeTab = .priceTag
        isCartCheckout = true
        scanMessage = nil
        isCartPresented = false
    }

    public func cartImageData(for item: CartItem) -> Data? {
        guard let name = item.imageFileName else { return nil }
        return try? Data(contentsOf: cartImageDirectory().appendingPathComponent(name))
    }

    public func historyImageData(for product: HistoryProduct) -> Data? {
        guard let name = product.imageFileName else { return nil }
        return (try? Data(contentsOf: historyImageDirectory().appendingPathComponent(name)))
            ?? (try? Data(contentsOf: cartImageDirectory().appendingPathComponent(name)))
    }

    private func removeCartItem(at index: Int) {
        deleteCartImage(cartItems[index].imageFileName)
        cartItems.remove(at: index)
    }

    private func persistCart() { Self.save(cartItems, key: "uTopia.cart") }

    private func cartImageDirectory() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CartImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func historyImageDirectory() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HistoryImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func saveHistoryImage(_ data: Data) -> String? {
        let name = "\(UUID().uuidString).jpg"
        do {
            let imageData = compressedCartImage(data) ?? data
            try imageData.write(to: historyImageDirectory().appendingPathComponent(name), options: .atomic)
            return name
        } catch { return nil }
    }

    private func deleteHistoryImage(_ name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: historyImageDirectory().appendingPathComponent(name))
    }

    private func saveCartImage(_ data: Data) -> String? {
        let name = "\(UUID().uuidString).jpg"
        do {
            let imageData = compressedCartImage(data) ?? data
            try imageData.write(to: cartImageDirectory().appendingPathComponent(name), options: .atomic)
            return name
        } catch { return nil }
    }

    private func compressedCartImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > 0 else { return nil }
        let scale = min(CGFloat(1), CGFloat(1024) / longestSide)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).jpegData(withCompressionQuality: 0.72) { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func deleteCartImage(_ name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: cartImageDirectory().appendingPathComponent(name))
    }

    public func onDockCloseTapped() {
        if currentStep == .coinScan, isCoinCardVisible { completeChangeFlow() }
        else { returnToPriceTag() }
    }

    public func resetPriceScan() {
        withAnimation(.snappy(duration: 0.35)) {
            isCartCheckout = false
            detectedPrice = 0
            currentScanImageData = nil
            tenderedAmount = 0
            detectedChange = 0
            isPriceCardVisible = false
            isTenderedCardVisible = false
            isCoinCardVisible = false
            currentFavoriteID = nil
            currentStep = .priceTagScan
            activeTab = .priceTag
            scanMessage = nil
        }
    }

    public func goToChang() {
        currentStep = .tenderedScan
        isTenderedCardVisible = false
        isCoinCardVisible = false
    }

    public func returnToPriceTag() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isCartCheckout = false
            currentStep = .priceTagScan; isTenderedCardVisible = false; isCoinCardVisible = false
            activeTab = .priceTag; scanMessage = nil
        }
    }

    public func openManualAmountEntry(for target: ManualAmountTarget) {
        manualAmountTarget = target
        switch target {
        case .price: keypadInput = detectedPrice == 0 ? "" : "\(Int(detectedPrice))"
        case .tendered: keypadInput = tenderedAmount == 0 ? "" : "\(Int(tenderedAmount))"
        case .coins: keypadInput = detectedChange == 0 ? "" : "\(Int(detectedChange))"
        }
        isManualAmountPresented = true
    }

    public func onVerifyChangeTapped() {
        guard expectedChange > 0 else {
            detectedChange = 0
            completeChangeFlow()
            return
        }
        currentStep = .coinScan
        isCoinCardVisible = false
    }
    public func onAdjustAmountTapped() { openManualAmountEntry(for: .coins) }

    public func toggleFavorite() {
        let existingID = currentFavoriteID ?? favoriteItems.first(where: {
            $0.currencyCode == priceCurrencyCode && abs($0.price - detectedPrice) < 0.001
        })?.id
        if let id = existingID {
            favoriteItems.removeAll { $0.id == id }; currentFavoriteID = nil
        } else {
            let item = FavoriteItem(price: detectedPrice, currencyCode: priceCurrencyCode)
            favoriteItems.insert(item, at: 0); currentFavoriteID = item.id
        }
        persistFavorites()
    }

    public var isCurrentPriceFavorite: Bool {
        if let id = currentFavoriteID { return favoriteItems.contains(where: { $0.id == id }) }
        return favoriteItems.contains { $0.currencyCode == priceCurrencyCode && abs($0.price - detectedPrice) < 0.001 }
    }

    public func onKeypadDigit(_ digit: String) {
        if digit == "." && keypadInput.contains(".") { return }
        if keypadInput == "0" && digit != "." { keypadInput = digit } else { keypadInput += digit }
    }
    public func onKeypadDelete() { if !keypadInput.isEmpty { keypadInput.removeLast() }; if keypadInput.isEmpty { keypadInput = "0" } }
    public func onQuickAdd(_ amount: Int) { keypadInput = "\((Double(keypadInput) ?? 0) + Double(amount))" }
    public func onKeypadClear() { keypadInput = "0" }

    public func onKeypadConfirm() {
        guard let parsedAmount = Double(keypadInput), !keypadInput.isEmpty else {
            scanMessage = "Enter a valid amount."
            return
        }
        let amount = parsedAmount
        switch manualAmountTarget {
        case .price:
            guard amount > 0 else { scanMessage = "Price must be greater than zero."; return }
            detectedPrice = amount; isPriceCardVisible = amount > 0
            if currentFavoriteID == nil {
                currentFavoriteID = favoriteItems.first(where: { $0.currencyCode == priceCurrencyCode && abs($0.price - amount) < 0.001 })?.id
            }
            if let id = currentFavoriteID, let index = favoriteItems.firstIndex(where: { $0.id == id }) {
                favoriteItems[index].price = amount; persistFavorites()
            }
        case .tendered:
            guard amount > 0 else { scanMessage = "Amount paid must be greater than zero."; return }
            tenderedAmount = amount; isTenderedCardVisible = true
        case .coins: detectedChange = amount; isCoinCardVisible = amount > 0; completeChangeFlow()
        }
        isManualAmountPresented = false
    }

    public func completeChangeFlow() {
        let products: [HistoryProduct]
        if isCartCheckout {
            products = cartItems.map {
                HistoryProduct(name: $0.name, price: $0.unitPrice, quantity: $0.quantity, currencyCode: $0.currencyCode,
                               imageFileName: cartImageData(for: $0).flatMap(saveHistoryImage))
            }
        } else {
            let name = detectedProductName.trimmingCharacters(in: .whitespacesAndNewlines)
            products = [HistoryProduct(name: name.isEmpty ? "Scanned item" : name, price: detectedPrice,
                                       currencyCode: priceCurrencyCode,
                                       imageFileName: currentScanImageData.flatMap(saveHistoryImage))]
        }
        let item = ScanHistoryItem(priceAmount: detectedPrice, convertedPrice: (isLoadingRate || rateUnavailable) ? nil : convertedPrice,
            paidAmount: tenderedAmount, expectedChangeAmount: expectedChange,
            receivedChangeAmount: detectedChange, priceCurrencyCode: priceCurrencyCode,
            changeCurrencyCode: priceCurrencyCode, convertedCurrencyCode: changeCurrencyCode,
            isVerified: abs(detectedChange - expectedChange) < 0.01, products: products,
            tripID: tripIDForNextHistory)
        historyItems.insert(item, at: 0); persistHistory()
        tripIDForNextHistory = nil
        if let id = currentFavoriteID, let index = favoriteItems.firstIndex(where: { $0.id == id }) {
            favoriteItems[index].tendered = tenderedAmount
            favoriteItems[index].expectedChange = expectedChange
            favoriteItems[index].receivedChange = detectedChange
            favoriteItems[index].changeCurrencyCode = priceCurrencyCode
            persistFavorites()
        }
        if isCartCheckout {
            clearCart()
            isCartCheckout = false
        }
        tenderedAmount = 0; detectedChange = 0; isPriceCardVisible = false
        currentScanImageData = nil
        isTenderedCardVisible = false; isCoinCardVisible = false; currentStep = .priceTagScan
        activeTab = .priceTag; scanMessage = "Saved to History"
    }

    public func resetScanFlow() {
        detectedPrice = 0; tenderedAmount = 0; detectedChange = 0; currentFavoriteID = nil
        currentScanImageData = nil
        isPriceCardVisible = false; isTenderedCardVisible = false; isCoinCardVisible = false
        currentStep = .priceTagScan; activeTab = .priceTag; scanMessage = nil
    }
    public func clearAllHistory() {
        historyItems.flatMap(\.products).forEach { deleteHistoryImage($0.imageFileName) }
        historyItems.removeAll()
        persistHistory()
    }
    public func deleteHistoryItem(at indexSet: IndexSet) {
        let removed = indexSet.map { historyItems[$0] }
        historyItems.remove(atOffsets: indexSet)
        removed.flatMap(\.products).forEach { deleteHistoryImage($0.imageFileName) }
        persistHistory()
    }
    public func deleteFavorite(at indexSet: IndexSet) { favoriteItems.remove(atOffsets: indexSet); persistFavorites() }
    public func removeFavorite(_ item: FavoriteItem) { favoriteItems.removeAll { $0.id == item.id }; persistFavorites() }
    private func persistHistory() { Self.save(historyItems, key: "uTopia.history") }
    private func persistFavorites() { Self.save(favoriteItems, key: "uTopia.favorites") }
    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }; return try? JSONDecoder().decode(type, from: data)
    }
    private static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }; UserDefaults.standard.set(data, forKey: key)
    }
}
