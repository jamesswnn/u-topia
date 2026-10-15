import Combine
import Foundation

@MainActor
public final class TravelStore: ObservableObject {
    @Published public private(set) var trips: [TravelTrip]
    @Published public private(set) var bookings: [DemoHotelBooking]
    @Published public var selectedTripID: UUID? {
        didSet { Self.save(selectedTripID, key: "uTopia.selectedTrip") }
    }

    public init() {
        trips = Self.load([TravelTrip].self, key: "uTopia.trips") ?? []
        bookings = Self.load([DemoHotelBooking].self, key: "uTopia.hotelBookings") ?? []
        selectedTripID = Self.load(UUID.self, key: "uTopia.selectedTrip")
        if let selectedTripID, !trips.contains(where: { $0.id == selectedTripID }) {
            self.selectedTripID = trips.first?.id
        }
    }

    public var currentTrip: TravelTrip? {
        guard let selectedTripID else { return nil }
        return trips.first(where: { $0.id == selectedTripID })
    }

    public var currentTripBooking: DemoHotelBooking? {
        guard let selectedTripID else { return nil }
        return bookings.first(where: { $0.tripID == selectedTripID })
    }

    @discardableResult
    public func createBangkokTrip(days: Int, budget: TripBudget, preferences: [TripPreference]) -> TravelTrip {
        let trip = TravelTrip(days: days, budget: budget, preferences: preferences)
        trips.insert(trip, at: 0)
        selectedTripID = trip.id
        persistTrips()
        return trip
    }

    public func selectTrip(_ trip: TravelTrip) {
        selectedTripID = trip.id
    }

    @discardableResult
    public func confirmDemoBooking(hotel: DemoHotel, guests: Int) -> DemoHotelBooking? {
        guard let trip = currentTrip else { return nil }
        let booking = DemoHotelBooking(tripID: trip.id, hotelID: hotel.id, hotelName: hotel.name,
                                       area: hotel.area, nights: trip.days, guests: guests,
                                       pricePerNight: hotel.pricePerNight, currencyCode: trip.currencyCode)
        bookings.removeAll { $0.tripID == trip.id }
        bookings.insert(booking, at: 0)
        Self.save(bookings, key: "uTopia.hotelBookings")
        return booking
    }

    public func spentAmount(for trip: TravelTrip?, history: [ScanHistoryItem]) -> Double {
        guard let trip else { return 0 }
        return history
            .filter { $0.tripID == trip.id }
            .reduce(0) { total, item in
                if item.priceCurrencyCode == trip.currencyCode { return total + item.priceAmount }
                if item.convertedCurrencyCode == trip.currencyCode, let converted = item.convertedPrice {
                    return total + converted
                }
                return total
            }
    }

    private func persistTrips() { Self.save(trips, key: "uTopia.trips") }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func save<T: Encodable>(_ value: T?, key: String) {
        guard let value, let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
