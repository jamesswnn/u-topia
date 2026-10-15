import SwiftUI
import UIKit

struct CartView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @State private var editingItem: CartItem?
    @State private var isClearConfirmationPresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.cartItems.isEmpty {
                    ContentUnavailableView("Your cart is empty", systemImage: "cart", description: Text("Scan a price and tap Add to cart."))
                    Spacer(minLength: 0)
                } else {
                    List {
                        ForEach(viewModel.cartItems) { item in
                            CartItemRow(item: item, imageData: viewModel.cartImageData(for: item),
                                        onEdit: { editingItem = item },
                                        onQuantityChange: { delta in viewModel.adjustCartQuantity(for: item, by: delta) })
                                .listRowBackground(Color.appCard)
                        }
                        .onDelete(perform: viewModel.deleteCartItems)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    VStack(spacing: 12) {
                        HStack(alignment: .center) {
                            Text("Total · \(viewModel.priceCurrencyCode)")
                                .font(.system(size: 17 * viewModel.fontScale, weight: viewModel.isBoldText ? .bold : .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(ExchangeRateService.format(viewModel.cartTotal, currencyCode: viewModel.priceCurrencyCode, decimals: 2))
                                .font(.system(size: 23 * viewModel.fontScale, weight: viewModel.isBoldText ? .heavy : .bold))
                                .foregroundStyle(.primary)
                        }
                        Button(action: viewModel.beginCartCheckout) {
                            Label("Checkout · Calculate change", systemImage: "arrow.right")
                                .font(.system(size: 17 * viewModel.fontScale, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(minHeight: 54)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Color.utopiaBlue)
                    }
                    .padding(20)
                    .background(Color.appCard)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Cart · \(viewModel.cartItems.reduce(0) { $0 + $1.quantity })")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { viewModel.isCartPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.cartItems.isEmpty {
                        Button("Clear", role: .destructive) { isClearConfirmationPresented = true }
                    }
                }
            }
            .confirmationDialog("Clear all items from the cart?", isPresented: $isClearConfirmationPresented, titleVisibility: .visible) {
                Button("Clear cart", role: .destructive) { viewModel.clearCart() }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(item: $editingItem) { item in
                CartItemEditView(item: item) { viewModel.updateCartItem($0) }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(26)
            }
        }
    }
}

private struct CartItemRow: View {
    let item: CartItem
    let imageData: Data?
    let onEdit: () -> Void
    let onQuantityChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Group {
                    if let imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Image(systemName: "tag").font(.system(size: 23)).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(uiColor: .tertiarySystemFill))
                    }
                }
                .frame(width: 62, height: 62).clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name).font(.system(size: 17, weight: .semibold)).foregroundStyle(.primary)
                    Text("Each · \(ExchangeRateService.format(item.unitPrice, currencyCode: item.currencyCode, decimals: 2))")
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                    Text("Total · \(ExchangeRateService.format(item.lineTotal, currencyCode: item.currencyCode, decimals: 2))")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.utopiaBlue)
                }
                Spacer(minLength: 4)
                Button(action: onEdit) {
                    Image(systemName: "pencil").font(.system(size: 15, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(Color(uiColor: .tertiarySystemFill), in: Circle())
                }
                .buttonStyle(.borderless).tint(Color.utopiaBlue).accessibilityLabel("Edit \(item.name)")
            }
            HStack(spacing: 14) {
                Text("Quantity").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                Spacer()
                Button { onQuantityChange(-1) } label: { Image(systemName: "minus.circle.fill").font(.system(size: 25)) }
                    .accessibilityLabel("Decrease quantity of \(item.name)")
                    .buttonStyle(.borderless).foregroundStyle(Color.utopiaBlue).frame(width: 44, height: 44).contentShape(Rectangle())
                Text("\(item.quantity)").font(.system(size: 16, weight: .bold).monospacedDigit()).frame(minWidth: 26)
                Button { onQuantityChange(1) } label: { Image(systemName: "plus.circle.fill").font(.system(size: 25)) }
                    .accessibilityLabel("Increase quantity of \(item.name)")
                    .buttonStyle(.borderless).foregroundStyle(Color.utopiaBlue).frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .foregroundStyle(.primary)
        }
        .padding(.vertical, 7)
    }
}

private struct CartItemEditView: View {
    @Environment(\.dismiss) private var dismiss
    let item: CartItem
    let onSave: (CartItem) -> Void
    @State private var name: String
    @State private var price: String
    @State private var quantity: String

    init(item: CartItem, onSave: @escaping (CartItem) -> Void) {
        self.item = item; self.onSave = onSave
        _name = State(initialValue: item.name)
        _price = State(initialValue: String(item.unitPrice))
        _quantity = State(initialValue: String(item.quantity))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                    TextField("Unit price (\(item.currencyCode))", text: $price).keyboardType(.decimalPad)
                    TextField("Quantity", text: $quantity).keyboardType(.numberPad)
                }
                Section {
                    Text("Currency: \(item.currencyCode)")
                    Text("Line total: \(ExchangeRateService.format((Double(price) ?? 0) * Double(max(1, Int(quantity) ?? 1)), currencyCode: item.currencyCode, decimals: 2))")
                }
            }
            .navigationTitle("Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(CartItem(id: item.id, name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? item.name : name,
                                        unitPrice: Double(price) ?? item.unitPrice, quantity: Int(quantity) ?? item.quantity,
                                        currencyCode: item.currencyCode, imageFileName: item.imageFileName))
                        dismiss()
                    }
                    .disabled((Double(price) ?? 0) <= 0 || (Int(quantity) ?? 0) < 1)
                }
            }
        }
    }
}
