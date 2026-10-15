//
//  ScanHistoryItem.swift
//  u_topia
//

import Foundation

public struct HistoryProduct: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let price: Double
    public let quantity: Int
    public let currencyCode: String
    public let imageFileName: String?

    public init(id: UUID = UUID(), name: String, price: Double, quantity: Int = 1, currencyCode: String, imageFileName: String? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.currencyCode = currencyCode
        self.imageFileName = imageFileName
    }
}

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
    public let products: [HistoryProduct]
    public let tripID: UUID?

    public init(id: UUID = UUID(), timestamp: Date = Date(), priceAmount: Double,
        convertedPrice: Double?, paidAmount: Double, expectedChangeAmount: Double,
        receivedChangeAmount: Double, priceCurrencyCode: String, changeCurrencyCode: String,
        convertedCurrencyCode: String,
        isVerified: Bool, products: [HistoryProduct] = [], tripID: UUID? = nil) {
        self.id = id; self.timestamp = timestamp; self.priceAmount = priceAmount
        self.convertedPrice = convertedPrice; self.paidAmount = paidAmount
        self.expectedChangeAmount = expectedChangeAmount; self.receivedChangeAmount = receivedChangeAmount
        self.priceCurrencyCode = priceCurrencyCode; self.changeCurrencyCode = changeCurrencyCode
        self.convertedCurrencyCode = convertedCurrencyCode
        self.isVerified = isVerified
        self.products = products
        self.tripID = tripID
    }

    private enum CodingKeys: String, CodingKey {
        case id, timestamp, priceAmount, convertedPrice, paidAmount, expectedChangeAmount
        case receivedChangeAmount, priceCurrencyCode, changeCurrencyCode, convertedCurrencyCode
        case isVerified, products, tripID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        priceAmount = try container.decode(Double.self, forKey: .priceAmount)
        convertedPrice = try container.decodeIfPresent(Double.self, forKey: .convertedPrice)
        paidAmount = try container.decode(Double.self, forKey: .paidAmount)
        expectedChangeAmount = try container.decode(Double.self, forKey: .expectedChangeAmount)
        receivedChangeAmount = try container.decode(Double.self, forKey: .receivedChangeAmount)
        priceCurrencyCode = try container.decode(String.self, forKey: .priceCurrencyCode)
        changeCurrencyCode = try container.decode(String.self, forKey: .changeCurrencyCode)
        convertedCurrencyCode = try container.decode(String.self, forKey: .convertedCurrencyCode)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        products = try container.decodeIfPresent([HistoryProduct].self, forKey: .products) ?? []
        tripID = try container.decodeIfPresent(UUID.self, forKey: .tripID)
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
