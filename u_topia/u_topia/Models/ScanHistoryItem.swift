//
//  ScanHistoryItem.swift
//  u_topia
//

import Foundation

public struct ScanHistoryItem: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let priceAmount: Double
    public let convertedPrice: Double?
    public let paidAmount: Double
    public let expectedChangeAmount: Double
    public let receivedChangeAmount: Double
    public let priceCurrencyCode: String
    public let changeCurrencyCode: String
    public let convertedCurrencyCode: String
    public let isVerified: Bool

    public init(id: UUID = UUID(), timestamp: Date = Date(), priceAmount: Double,
        convertedPrice: Double?, paidAmount: Double, expectedChangeAmount: Double,
        receivedChangeAmount: Double, priceCurrencyCode: String, changeCurrencyCode: String,
        convertedCurrencyCode: String,
        isVerified: Bool) {
        self.id = id; self.timestamp = timestamp; self.priceAmount = priceAmount
        self.convertedPrice = convertedPrice; self.paidAmount = paidAmount
        self.expectedChangeAmount = expectedChangeAmount; self.receivedChangeAmount = receivedChangeAmount
        self.priceCurrencyCode = priceCurrencyCode; self.changeCurrencyCode = changeCurrencyCode
        self.convertedCurrencyCode = convertedCurrencyCode
        self.isVerified = isVerified
    }

    public var formattedTime: String {
        let f = DateFormatter(); f.locale = .current; f.timeStyle = .short; f.dateStyle = .none
        return f.string(from: timestamp)
    }
    public var formattedDate: String {
        let f = DateFormatter(); f.locale = .current; f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: timestamp)
    }
}
