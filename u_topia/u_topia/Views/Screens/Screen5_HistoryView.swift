//
//  Screen5_HistoryView.swift
//  u_topia
//

import SwiftUI

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
                            HistoryCardRow(item: item, scale: viewModel.fontScale, bold: viewModel.isBoldText)
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
    let scale: CGFloat
    let bold: Bool

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
            line("Price", amount: item.priceAmount, currency: item.priceCurrencyCode, scale: scale, bold: bold)
            line("Paid", amount: item.paidAmount, currency: item.priceCurrencyCode, scale: scale, bold: bold)
            line("Expected change", amount: item.expectedChangeAmount, currency: item.priceCurrencyCode, scale: scale, bold: bold)
            line("Received", amount: item.receivedChangeAmount, currency: item.priceCurrencyCode, scale: scale, bold: true, color: .green)
            if let convertedPrice = item.convertedPrice {
                Text("≈ \(ExchangeRateService.format(convertedPrice, currencyCode: item.convertedCurrencyCode, decimals: 2))")
                    .font(.system(size: 13 * scale)).foregroundStyle(.blue)
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
