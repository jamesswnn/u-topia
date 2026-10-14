//
//  ExchangeRateService.swift
//  u_topia
//

import Foundation

public struct CurrencyOption: Identifiable, Hashable {
    public let code: String
    public let name: String
    public let symbol: String
    public var id: String { code }

    public static let common: [CurrencyOption] = [
        .init(code: "USD", name: "US Dollar", symbol: "$"),
        .init(code: "JPY", name: "Japanese Yen", symbol: "¥"),
        .init(code: "THB", name: "Thai Baht", symbol: "฿"),
        .init(code: "CNY", name: "Chinese Yuan", symbol: "¥"),
        .init(code: "EUR", name: "Euro", symbol: "€"),
        .init(code: "SGD", name: "Singapore Dollar", symbol: "S$")
    ]

    public static func option(for code: String) -> CurrencyOption {
        common.first(where: { $0.code == code }) ?? .init(code: code, name: code, symbol: code)
    }
}

public final class ExchangeRateService {
    public static let shared = ExchangeRateService()
    private init() {}

    public func rate(from: String, to: String) async throws -> Double {
        if from == to { return 1 }
        var components = URLComponents(string: "https://api.frankfurter.dev/v1/latest")!
        components.queryItems = [URLQueryItem(name: "base", value: from), URLQueryItem(name: "symbols", value: to)]
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(RateResponse.self, from: data)
        guard let value = result.rates[to], value > 0 else { throw URLError(.cannotParseResponse) }
        return value
    }

    private struct RateResponse: Decodable {
        let rates: [String: Double]
    }

    public static func format(_ amount: Double, currencyCode: String, decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currencyCode)"
    }
}
