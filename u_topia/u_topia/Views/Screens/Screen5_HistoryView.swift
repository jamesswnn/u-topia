//
//  Screen5_HistoryView.swift
//  u_topia
//

import SwiftUI
import UIKit

public struct Screen5_HistoryView: View {
    @ObservedObject var viewModel: ScannerViewModel
    public init(viewModel: ScannerViewModel) { self.viewModel = viewModel }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.historyItems.isEmpty {
                    ContentUnavailableView("No history yet", systemImage: "clock.arrow.circlepath", description: Text("Completed change checks will appear here."))
                } else {
                    List {
                        ForEach(viewModel.historyItems) { item in
                            NavigationLink {
                                HistoryDetailView(item: item, viewModel: viewModel)
                            } label: {
                                HistoryCardRow(item: item, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.appBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                        }
                        .onDelete(perform: viewModel.deleteHistoryItem)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("History")
            .toolbar {
                if !viewModel.historyItems.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear") { viewModel.showClearAlert = true }.foregroundStyle(.red)
                    }
                }
            }
            .alert("Clear history?", isPresented: $viewModel.showClearAlert) {
                Button("Clear all", role: .destructive) { viewModel.clearAllHistory() }
                Button("Cancel", role: .cancel) { }
            } message: { Text("This removes all saved transactions from this iPad.") }
        }
    }
}

private struct HistoryCardRow: View {
    let item: ScanHistoryItem
    @ObservedObject var viewModel: ScannerViewModel
    private var scale: CGFloat { viewModel.fontScale }
    private var bold: Bool { viewModel.isBoldText }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.formattedDate).font(.system(size: 13 * scale, weight: .medium)).foregroundStyle(.secondary)
                    Text(item.formattedTime).font(.system(size: 12 * scale)).foregroundStyle(.secondary)
                }
                Spacer()
                Label(item.isVerified ? "Matched" : "Check difference", systemImage: item.isVerified ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 13 * scale, weight: bold ? .bold : .semibold))
                    .foregroundStyle(item.isVerified ? Color.green : Color.orange)
            }
            Divider()
            if item.products.isEmpty {
                Text("No product details were saved for this older check.")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("SAVED ITEMS")
                        .font(.system(size: 11 * scale, weight: .bold))
                        .foregroundStyle(.secondary)
                    ForEach(item.products) { product in
                        HStack(spacing: 12) {
                            ProductThumbnail(data: viewModel.historyImageData(for: product))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(product.name)
                                    .font(.system(size: 16 * scale, weight: bold ? .bold : .semibold))
                                Text(ExchangeRateService.format(product.price, currencyCode: product.currencyCode, decimals: 0))
                                    .font(.system(size: 14 * scale, weight: .medium))
                                    .foregroundStyle(.secondary)
                                if product.quantity > 1 {
                                    Text("Quantity: \(product.quantity)")
                                        .font(.system(size: 13 * scale))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                Divider()
            }
            line("Price", amount: item.priceAmount, currency: item.priceCurrencyCode, scale: scale, bold: bold)
            line("Paid", amount: item.paidAmount, currency: item.priceCurrencyCode, scale: scale, bold: bold)
            line("Expected change", amount: item.expectedChangeAmount, currency: item.priceCurrencyCode, scale: scale, bold: bold)
            line("Received", amount: item.receivedChangeAmount, currency: item.priceCurrencyCode, scale: scale, bold: true, color: .green)
            if let convertedPrice = item.convertedPrice {
                Text("≈ \(ExchangeRateService.format(convertedPrice, currencyCode: item.convertedCurrencyCode, decimals: 2))")
                    .font(.system(size: 13 * scale)).foregroundStyle(Color.utopiaBlue)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.appCard))
        .padding(.vertical, 4)
    }

    private func line(_ title: String, amount: Double, currency: String, scale: CGFloat, bold: Bool, color: Color = .primary) -> some View {
        HStack {
            Text(title).font(.system(size: 15 * scale, weight: .medium)).foregroundStyle(.secondary)
            Spacer()
            Text(ExchangeRateService.format(amount, currencyCode: currency, decimals: 0))
                .font(.system(size: 16 * scale, weight: bold ? .bold : .semibold)).foregroundStyle(color)
        }
    }
}

private struct HistoryDetailView: View {
    let item: ScanHistoryItem
    @ObservedObject var viewModel: ScannerViewModel

    var body: some View {
        ScrollView {
            HistoryCardRow(item: item, viewModel: viewModel)
                .padding(.horizontal, 16)
                .padding(.top, 12)
        }
        .background(Color.appBackground)
        .navigationTitle("History details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProductThumbnail: View {
    let data: Data?

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "tag.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .tertiarySystemFill))
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
