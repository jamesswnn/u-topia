import Combine
import Foundation

@MainActor
public final class TravelStore: ObservableObject {
    @Published public private(set) var trips: [TravelTrip]
    @Published public private(set) var bookings: [DemoHotelBooking]
    @Published public var selectedTripID: UUID? {
        didSet {
            if let selectedTripID { Self.save(selectedTripID, key: "uTopia.selectedTrip") }
            else { UserDefaults.standard.removeObject(forKey: "uTopia.selectedTrip") }
        }
    }

    public init() {
        trips = Self.load([TravelTrip].self, key: "uTopia.trips") ?? []
        bookings = Self.load([DemoHotelBooking].self, key: "uTopia.hotelBookings") ?? []
        selectedTripID = Self.load(UUID.self, key: "uTopia.selectedTrip")
        var correctedBookings = false
        bookings = bookings.map { booking in
            guard let trip = trips.first(where: { $0.id == booking.tripID }) else { return booking }
            let allowedNights = trip.maximumHotelNights
            guard booking.nights > allowedNights else { return booking }
            correctedBookings = true
            return DemoHotelBooking(id: booking.id, tripID: booking.tripID, hotelID: booking.hotelID,
                                    hotelName: booking.hotelName, area: booking.area, nights: allowedNights,
                                    guests: booking.guests, pricePerNight: booking.pricePerNight,
                                    currencyCode: booking.currencyCode, bookedAt: booking.bookedAt)
        }
        if correctedBookings { Self.save(bookings, key: "uTopia.hotelBookings") }
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
    public func createBangkokTrip(days: Int, budget: TripBudget, preferences: [TripPreference],
                                  startDate: Date? = nil, endDate: Date? = nil) -> TravelTrip {
        let trip = TravelTrip(days: days, budget: budget, preferences: preferences,
                              startDate: startDate, endDate: endDate)
        trips.insert(trip, at: 0)
        selectedTripID = trip.id
        persistTrips()
        return trip
    }

    @discardableResult
    public func duplicateTrip(_ trip: TravelTrip) -> TravelTrip {
        let copy = TravelTrip(city: trip.city, countryCode: trip.countryCode, days: trip.days,
                              budget: trip.budget, preferences: trip.preferences,
                              currencyCode: trip.currencyCode, startDate: trip.startDate, endDate: trip.endDate)
        trips.insert(copy, at: 0)
        selectedTripID = copy.id
        persistTrips()
        return copy
    }

    public func deleteTrip(_ trip: TravelTrip) {
        trips.removeAll { $0.id == trip.id }
        bookings.removeAll { $0.tripID == trip.id }
        if selectedTripID == trip.id {
            selectedTripID = trips.first?.id
        }
        persistTrips()
        Self.save(bookings, key: "uTopia.hotelBookings")
    }

    public func selectTrip(_ trip: TravelTrip) {
        selectedTripID = trip.id
    }

    @discardableResult
    public func confirmHotelBooking(hotel: DemoHotel, nights: Int) -> DemoHotelBooking? {
        guard let trip = currentTrip, trip.maximumHotelNights > 0 else { return nil }
        let bookedNights = min(max(nights, 1), trip.maximumHotelNights)
        let booking = DemoHotelBooking(tripID: trip.id, hotelID: hotel.id, hotelName: hotel.name,
                                       area: hotel.area, nights: bookedNights, guests: 1,
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
