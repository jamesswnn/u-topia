import CoreLocation
import Foundation
import SwiftUI
import UIKit

public enum TripBudget: String, CaseIterable, Codable, Identifiable {
    case ultraBudget, budget, moderate, upscale, luxury

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .ultraBudget: "Shoestring"
        case .budget: "Budget"
        case .moderate: "Moderate"
        case .upscale: "Upscale"
        case .luxury: "Luxury"
        }
    }
    public var detail: String {
        switch self {
        case .ultraBudget: "Spend as little as possible"
        case .budget: "Great value, thoughtful choices"
        case .moderate: "A comfortable balance"
        case .upscale: "A few special moments"
        case .luxury: "Make it unforgettable"
        }
    }
}

public enum TripPreference: String, CaseIterable, Codable, Identifiable {
    case shopping, popular, foodie, culture, nature, nightlife

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .shopping: "Shopping"
        case .popular: "Popular"
        case .foodie: "Foodie"
        case .culture: "Culture"
        case .nature: "Nature"
        case .nightlife: "Nightlife"
        }
    }
    public var symbol: String {
        switch self {
        case .shopping: "bag"
        case .popular: "sparkles"
        case .foodie: "fork.knife"
        case .culture: "building.columns"
        case .nature: "leaf"
        case .nightlife: "moon.stars"
        }
    }
}

public struct TravelTrip: Identifiable, Codable, Equatable {
    public let id: UUID
    public let city: String
    public let countryCode: String
    public let days: Int
    public let budget: TripBudget
    public let preferences: [TripPreference]
    public let createdAt: Date
    public let currencyCode: String
    public let startDate: Date?
    public let endDate: Date?

    public var maximumHotelNights: Int { max(days - 1, 0) }

    public init(id: UUID = UUID(), city: String = "Bangkok", countryCode: String = "TH", days: Int,
                budget: TripBudget, preferences: [TripPreference], createdAt: Date = Date(), currencyCode: String = "THB",
                startDate: Date? = nil, endDate: Date? = nil) {
        self.id = id
        self.city = city
        self.countryCode = countryCode
        self.days = days
        self.budget = budget
        self.preferences = preferences
        self.createdAt = createdAt
        self.currencyCode = currencyCode
        self.startDate = startDate
        self.endDate = endDate
    }
}

public enum PlaceCategory: String, CaseIterable, Identifiable {
    case attraction, food, hotel

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .attraction: "Things to do"
        case .food: "Food"
        case .hotel: "Hotels"
        }
    }
    public var symbol: String {
        switch self {
        case .attraction: "sparkle"
        case .food: "fork.knife"
        case .hotel: "bed.double"
        }
    }
    public var tint: Color {
        switch self {
        case .attraction: Color(hex: 0x82A9D6)
        case .food: Color(hex: 0xE9B85B)
        case .hotel: Color(hex: 0x7DB99A)
        }
    }
}

public struct TravelPlace: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let category: PlaceCategory
    public let latitude: Double
    public let longitude: Double
    public let imageURL: String
    public let description: String
    public let rating: String
    public let walkingMinutes: Int
    public let drivingMinutes: Int
    public let busMinutes: Int
    public let trainMinutes: Int

    public var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }

    public static let bangkokHighlights: [TravelPlace] = [
        TravelPlace(id: "wat-arun", name: "Wat Arun", subtitle: "Temple of Dawn · Riverside", category: .attraction,
                    latitude: 13.7437, longitude: 100.4889,
                    imageURL: "https://images.unsplash.com/photo-1666418096686-da94c2e70e6d?auto=format&fit=crop&w=1200&q=82",
                    description: "A riverside landmark known for its porcelain-covered central prang and beautiful late-afternoon light.", rating: "4.8", walkingMinutes: 18, drivingMinutes: 12, busMinutes: 22, trainMinutes: 16),
        TravelPlace(id: "yaowarat", name: "Yaowarat Road", subtitle: "Chinatown · Street food", category: .food,
                    latitude: 13.7394, longitude: 100.5101,
                    imageURL: "https://images.unsplash.com/photo-1753272379004-2c2b342073f7?auto=format&fit=crop&w=1200&q=82",
                    description: "A lively food street packed with family-run restaurants, local snacks, and neon-lit evening stalls.", rating: "4.7", walkingMinutes: 14, drivingMinutes: 10, busMinutes: 18, trainMinutes: 12),
        TravelPlace(id: "chatuchak", name: "Chatuchak Weekend Market", subtitle: "Shopping · Local finds", category: .attraction,
                    latitude: 13.7999, longitude: 100.5507,
                    imageURL: "https://images.unsplash.com/photo-1672934324126-257a393a9aa8?auto=format&fit=crop&w=1200&q=82",
                    description: "Explore a sprawling weekend market for vintage finds, clothing, crafts, and casual local eats.", rating: "4.6", walkingMinutes: 9, drivingMinutes: 8, busMinutes: 16, trainMinutes: 11),
        TravelPlace(id: "grand-palace", name: "The Grand Palace", subtitle: "Historic · Old City", category: .attraction,
                    latitude: 13.7500, longitude: 100.4913,
                    imageURL: "https://images.unsplash.com/photo-1587308688353-bc58083be441?auto=format&fit=crop&w=1200&q=82",
                    description: "A landmark complex of royal halls and ornate temples at the heart of Bangkok's historic district.", rating: "4.8", walkingMinutes: 12, drivingMinutes: 9, busMinutes: 18, trainMinutes: 15),
        TravelPlace(id: "sathorn-hotel", name: "Riverside Boutique Stay", subtitle: "Hotel · Chao Phraya", category: .hotel,
                    latitude: 13.7217, longitude: 100.5131,
                    imageURL: "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=82",
                    description: "A relaxed riverside stay with easy access to ferry piers and the old town.", rating: "4.6", walkingMinutes: 11, drivingMinutes: 8, busMinutes: 16, trainMinutes: 13),
        TravelPlace(id: "ari-cafe", name: "Ari Café Quarter", subtitle: "Cafés · Neighbourhood", category: .food,
                    latitude: 13.7797, longitude: 100.5448,
                    imageURL: "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=82",
                    description: "Independent cafés, bakeries, and small restaurants make this neighbourhood an easygoing food stop.", rating: "4.5", walkingMinutes: 7, drivingMinutes: 6, busMinutes: 15, trainMinutes: 9)
    ]
}

public struct DemoHotel: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let area: String
    public let imageURL: String
    public let rating: String
    public let pricePerNight: Double
    public let description: String
    public let walkToTransit: Int

    public static let bangkok: [DemoHotel] = [
        DemoHotel(id: "riverside-house", name: "Riverside House Bangkok", area: "Bang Rak · River view",
                  imageURL: "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1400&q=82",
                  rating: "4.8", pricePerNight: 2450, description: "A calm riverside base with a pool, breakfast, and easy ferry access.", walkToTransit: 6),
        DemoHotel(id: "citrus-sukhumvit", name: "Citrus Sukhumvit Stay", area: "Sukhumvit · City centre",
                  imageURL: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1400&q=82",
                  rating: "4.6", pricePerNight: 1890, description: "A bright city stay close to shopping, dining, and the BTS.", walkToTransit: 4),
        DemoHotel(id: "old-city-hideaway", name: "Old City Hideaway", area: "Phra Nakhon · Historic quarter",
                  imageURL: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=1400&q=82",
                  rating: "4.7", pricePerNight: 3150, description: "A boutique retreat within easy reach of temples and local markets.", walkToTransit: 9)
    ]
}

public struct DemoHotelBooking: Identifiable, Codable, Equatable {
    public let id: UUID
    public let tripID: UUID
    public let hotelID: String
    public let hotelName: String
    public let area: String
    public let nights: Int
    public let guests: Int
    public let pricePerNight: Double
    public let currencyCode: String
    public let bookedAt: Date

    public init(id: UUID = UUID(), tripID: UUID, hotelID: String, hotelName: String, area: String,
                nights: Int, guests: Int, pricePerNight: Double, currencyCode: String = "THB", bookedAt: Date = Date()) {
        self.id = id
        self.tripID = tripID
        self.hotelID = hotelID
        self.hotelName = hotelName
        self.area = area
        self.nights = nights
        self.guests = guests
        self.pricePerNight = pricePerNight
        self.currencyCode = currencyCode
        self.bookedAt = bookedAt
    }

    public var totalPrice: Double { pricePerNight * Double(nights) }
}

extension Color {
    public static let utopiaBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.43, blue: 0.79, alpha: 1)
            : UIColor(red: 0.10, green: 0.40, blue: 0.82, alpha: 1)
    })
    public static let utopiaInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.91, green: 0.95, blue: 1.00, alpha: 1)
            : UIColor(red: 0.08, green: 0.16, blue: 0.27, alpha: 1)
    })
    public static let utopiaCanvas = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.082, blue: 0.125, alpha: 1)
            : UIColor(red: 0.955, green: 0.972, blue: 0.997, alpha: 1)
    })
    public static let utopiaCard = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.125, blue: 0.18, alpha: 1)
            : UIColor.white
    })
    public static let utopiaSoftGray = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.26, blue: 0.35, alpha: 1)
            : UIColor(red: 0.84, green: 0.89, blue: 0.96, alpha: 1)
    })
    public static let utopiaSuccess = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.82, blue: 0.64, alpha: 1)
            : UIColor(red: 0.30, green: 0.52, blue: 0.37, alpha: 1)
    })
    public static let utopiaSuccessBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.20, blue: 0.14, alpha: 1)
            : UIColor(red: 0.91, green: 0.96, blue: 0.92, alpha: 1)
    })
}
