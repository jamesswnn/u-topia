import MapKit
import SwiftUI
import UIKit

private struct TravelHeader: View {
    let eyebrow: String
    let title: String
    var scale: CGFloat = 1
    var isBoldText = false
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased()).font(.system(size: 10 * scale, weight: .bold, design: .rounded)).tracking(1.1).foregroundStyle(.secondary)
                Text(title).font(.system(size: 27 * scale, weight: isBoldText ? .black : .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
            }
            Spacer(minLength: 8)
            Button(action: onSettings) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                    .frame(width: 42, height: 42).background(.white, in: Circle())
                    .overlay(Circle().stroke(Color.utopiaSoftGray, lineWidth: 1))
            }
            .accessibilityLabel("Text settings")
        }
    }
}

struct NewTripMenuView: View {
    let onNewTrip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule().fill(Color.utopiaSoftGray).frame(width: 36, height: 5).frame(maxWidth: .infinity).padding(.top, 10)
            Text("Add to your plans").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
            Button(action: onNewTrip) {
                HStack(spacing: 14) {
                    Image(systemName: "plus").font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 42, height: 42).background(Color.utopiaCoral, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("New Trip").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                        Text("Build an itinerary for Bangkok").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
                }
                .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).background(Color.utopiaCanvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

struct CreateTripView: View {
    @ObservedObject var travelStore: TravelStore
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var days = 3.0
    @State private var budget = 2.0
    @State private var selectedPreferences: Set<TripPreference> = [.popular, .foodie]

    private var selectedBudget: TripBudget { TripBudget.allCases[Int(budget)] }
    private let cityOptions = ["Bangkok, Thailand", "Chiang Mai, Thailand", "Phuket, Thailand", "Tokyo, Japan", "Seoul, South Korea"]
    private var matchingCities: [String] {
        query.isEmpty ? [] : cityOptions.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Let’s plan somewhere great.").font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                    Text("Tell us what you’re looking for and we’ll shape a Bangkok demo itinerary.").font(.system(size: 14)).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 11) {
                    sectionLabel("WHERE", symbol: "magnifyingglass")
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Search city or country", text: $query).textInputAutocapitalization(.words)
                    }
                    .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 15))
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse").foregroundStyle(Color.utopiaCoral)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bangkok").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            Text("Thailand · Demo destination").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.utopiaCoral)
                    }
                    .padding(14).background(Color.utopiaCoral.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                    if !matchingCities.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(matchingCities, id: \.self) { city in
                                HStack {
                                    Text(city).foregroundStyle(city.hasPrefix("Bangkok") ? Color.utopiaInk : .secondary)
                                    Spacer()
                                    if city.hasPrefix("Bangkok") { Text("Selected").font(.caption.weight(.semibold)).foregroundStyle(Color.utopiaCoral) }
                                    else { Image(systemName: "lock.fill").font(.caption).foregroundStyle(.tertiary) }
                                }
                                .font(.system(size: 14)).padding(.vertical, 11)
                                .overlay(alignment: .bottom) { if city != matchingCities.last { Divider() } }
                            }
                        }
                        .padding(.horizontal, 14).background(.white, in: RoundedRectangle(cornerRadius: 15))
                        Text("More destinations will be available soon.").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 11) {
                    HStack { sectionLabel("WHEN", symbol: "calendar"); Spacer(); Text("\(Int(days)) days").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.utopiaInk) }
                    Slider(value: $days, in: 1...14, step: 1).tint(Color.utopiaCoral)
                    HStack { Text("1 day"); Spacer(); Text("14 days") }.font(.system(size: 11)).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 11) {
                    HStack { sectionLabel("BUDGET", symbol: "bahtsign.circle"); Spacer(); Text(selectedBudget.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.utopiaCoral) }
                    HStack(spacing: 4) {
                        ForEach(TripBudget.allCases.indices, id: \.self) { index in
                            Button { budget = Double(index) } label: {
                                VStack(spacing: 7) {
                                    Text(TripBudget.allCases[index].symbol).font(.system(size: 12, weight: .bold))
                                    Text(["Shoestring", "Budget", "Moderate", "Upscale", "Luxury"][index])
                                        .font(.system(size: 9, weight: Int(budget) == index ? .bold : .medium)).lineLimit(1).minimumScaleFactor(0.75)
                                }
                                .foregroundStyle(Int(budget) == index ? Color.utopiaCoral : Color.secondary)
                                .frame(maxWidth: .infinity).padding(.vertical, 11)
                                .background(Int(budget) == index ? Color.utopiaCoral.opacity(0.09) : .white, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Int(budget) == index ? Color.utopiaCoral.opacity(0.4) : Color.utopiaSoftGray, lineWidth: 1))
                            }.buttonStyle(.plain)
                        }
                    }
                    Text(selectedBudget.detail).font(.system(size: 12)).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("PREFERENCES", symbol: "slider.horizontal.3")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                        ForEach(TripPreference.allCases) { preference in
                            let isSelected = selectedPreferences.contains(preference)
                            Button {
                                if isSelected { selectedPreferences.remove(preference) }
                                else { selectedPreferences.insert(preference) }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: preference.symbol).font(.system(size: 17, weight: .medium))
                                    Text(preference.title).font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundStyle(isSelected ? Color.utopiaCoral : Color.utopiaInk)
                                .frame(maxWidth: .infinity).frame(height: 72)
                                .background(isSelected ? Color.utopiaCoral.opacity(0.09) : .white, in: RoundedRectangle(cornerRadius: 15))
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(isSelected ? Color.utopiaCoral.opacity(0.45) : Color.utopiaSoftGray, lineWidth: 1))
                            }.buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "sparkles").foregroundStyle(Color.utopiaCoral)
                    Text("Bangkok suggestions are demo recommendations. Personalised AI planning can be connected later.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 15))
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 28)
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .navigationTitle("New Trip").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundStyle(Color.utopiaInk) }
            ToolbarItem(placement: .confirmationAction) {
                Button { createTrip() } label: { Image(systemName: "arrow.right").fontWeight(.semibold) }
                    .tint(Color.utopiaCoral).accessibilityLabel("Create trip")
            }
            ToolbarItem(placement: .bottomBar) {
                Button(action: createTrip) {
                    HStack { Image(systemName: "sparkles"); Text("Create New Trip") }
                        .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15).background(Color.utopiaCoral, in: Capsule())
                }.buttonStyle(.plain)
            }
        }
    }

    private func sectionLabel(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol).font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(Color.utopiaInk)
    }
    private func createTrip() {
        travelStore.createBangkokTrip(days: Int(days), budget: selectedBudget,
                                      preferences: TripPreference.allCases.filter { selectedPreferences.contains($0) })
        onCreated()
    }
}

struct TripHomeView: View {
    @ObservedObject var travelStore: TravelStore
    @ObservedObject var viewModel: ScannerViewModel
    let onCreateTrip: () -> Void
    let onSettings: () -> Void
    @State private var activeSheet: TripHomeSheet?

    private let highlights = Array(TravelPlace.bangkokHighlights.prefix(3))

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 25) {
                TravelHeader(eyebrow: "Your location", title: "Bangkok, TH", scale: viewModel.fontScale,
                             isBoldText: viewModel.isBoldText, onSettings: onSettings)
                Button(action: onCreateTrip) {
                    HStack {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("MAKE IT A TRIP").font(.system(size: 10, weight: .bold)).tracking(1.1).foregroundStyle(.white.opacity(0.8))
                            Text("Create New Trip").font(.system(size: 21, weight: .bold, design: .rounded)).foregroundStyle(.white)
                            Text("Build your days around what you love").font(.system(size: 12)).foregroundStyle(.white.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.utopiaCoral)
                            .frame(width: 43, height: 43).background(.white, in: Circle())
                    }
                    .padding(20).background(LinearGradient(colors: [Color.utopiaCoral, Color(hex: 0xE98A70)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 23))
                }.buttonStyle(.plain)

                if !travelStore.trips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            sectionTitle("Your trips", subtitle: "Pick up where you left off")
                            Spacer()
                            Button("Open plan") {
                                if let trip = travelStore.currentTrip { activeSheet = .trip(trip) }
                            }
                                .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.utopiaCoral)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(travelStore.trips) { trip in
                                    Button {
                                        travelStore.selectTrip(trip)
                                        activeSheet = .trip(trip)
                                    } label: { TripCarouselCard(trip: trip, selected: trip.id == travelStore.selectedTripID) }
                                        .buttonStyle(.plain)
                                    }
                            }.padding(.vertical, 2)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Recommended in Bangkok", subtitle: "A little inspiration for your first day")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 13) {
                            ForEach(highlights) { place in
                                Button { activeSheet = .place(place) } label: { PlaceFeatureCard(place: place) }.buttonStyle(.plain)
                            }
                        }.padding(.vertical, 2)
                    }
                }

                if let trip = travelStore.currentTrip {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("A taste of your plan", subtitle: "A demo itinerary based on your preferences")
                        Button { activeSheet = .trip(trip) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "sparkles").font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.utopiaCoral)
                                    .frame(width: 44, height: 44).background(Color.utopiaCoral.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(trip.days)-day Bangkok itinerary").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                                    Text("\(trip.budget.title) · \(trip.preferences.prefix(2).map(\.title).joined(separator: " + "))")
                                        .font(.system(size: 12)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
                            }.padding(15).background(.white, in: RoundedRectangle(cornerRadius: 18))
                        }.buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 28)
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .place(let place): PlaceDetailSheet(place: place)
            case .trip(let trip): TripDetailSheet(trip: trip).presentationDetents([.large]).presentationDragIndicator(.visible)
            }
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
}

private enum TripHomeSheet: Identifiable {
    case place(TravelPlace)
    case trip(TravelTrip)
    var id: String {
        switch self {
        case .place(let place): "place-\(place.id)"
        case .trip(let trip): "trip-\(trip.id.uuidString)"
        }
    }
}

private struct TripCarouselCard: View {
    let trip: TravelTrip
    let selected: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill").font(.system(size: 13)).foregroundStyle(Color.utopiaCoral)
                Spacer()
                if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.utopiaCoral) }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(trip.city).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                Text("\(trip.days) days · \(trip.budget.title)").font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
        .padding(15).frame(width: 175, height: 108, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? Color.utopiaCoral.opacity(0.5) : Color.utopiaSoftGray, lineWidth: 1))
    }
}

private struct PlaceFeatureCard: View {
    let place: TravelPlace
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TravelImage(url: place.imageURL, symbol: place.category.symbol).frame(width: 245, height: 190)
            LinearGradient(colors: [.clear, .black.opacity(0.68)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 5) {
                Text(place.category.title.uppercased()).font(.system(size: 9, weight: .bold)).tracking(0.9).foregroundStyle(.white.opacity(0.8))
                Text(place.name).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Label(place.rating, systemImage: "star.fill").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
            }.padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20)).overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.utopiaInk)
                .frame(width: 30, height: 30).background(.white.opacity(0.93), in: Circle()).padding(11)
        }
    }
}

struct BookingView: View {
    @ObservedObject var travelStore: TravelStore
    @ObservedObject var viewModel: ScannerViewModel
    let onCreateTrip: () -> Void
    let onSettings: () -> Void
    @State private var selectedHotel: DemoHotel?
    @State private var showConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                TravelHeader(eyebrow: "Stay somewhere lovely", title: "Booking", scale: viewModel.fontScale,
                             isBoldText: viewModel.isBoldText, onSettings: onSettings)
                if let trip = travelStore.currentTrip {
                    HStack(spacing: 10) {
                        Image(systemName: "suitcase.rolling.fill").foregroundStyle(Color.utopiaCoral)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("For your Bangkok trip").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            Text("\(trip.days) nights · Demo booking only").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 16))

                    if let booking = travelStore.currentTripBooking {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("DEMO BOOKING SAVED", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(Color(hex: 0x568F6B))
                            Text(booking.hotelName).font(.system(size: 16, weight: .bold)).foregroundStyle(Color.utopiaInk)
                            Text("\(booking.nights) nights · \(booking.guests) guests · \(ExchangeRateService.format(booking.totalPrice, currencyCode: booking.currencyCode, decimals: 0))")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: 0xEAF4EC), in: RoundedRectangle(cornerRadius: 17))
                    }

                    VStack(alignment: .leading, spacing: 13) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Places to stay").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                            Text("Choose a hotel to preview a mock reservation.").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        ForEach(DemoHotel.bangkok) { hotel in
                            HotelCard(hotel: hotel, isCurrent: travelStore.currentTripBooking?.hotelID == hotel.id) {
                                selectedHotel = hotel
                            }
                        }
                    }
                } else {
                    VStack(spacing: 13) {
                        Image(systemName: "bed.double.fill").font(.system(size: 30)).foregroundStyle(Color.utopiaCoral)
                        Text("A stay starts with a trip").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                        Text("Create a Bangkok trip first, then save a demo hotel booking to it.").font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Create New Trip", action: onCreateTrip).buttonStyle(CoralButtonStyle())
                    }.frame(maxWidth: .infinity).padding(28).background(.white, in: RoundedRectangle(cornerRadius: 22))
                }
                Text("Demo only · No payment or real reservation will be made.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 4)
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 28)
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .sheet(item: $selectedHotel) { hotel in
            HotelBookingSheet(hotel: hotel, trip: travelStore.currentTrip) { guests in
                if travelStore.confirmDemoBooking(hotel: hotel, guests: guests) != nil {
                    selectedHotel = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showConfirmation = true }
                }
            }
            .presentationDetents([.medium, .large]).presentationDragIndicator(.visible).presentationCornerRadius(28)
        }
        .alert("Demo booking saved", isPresented: $showConfirmation) {
            Button("Done", role: .cancel) { }
        } message: {
            Text("This hotel has been added to your current Bangkok trip. No real reservation was made.")
        }
    }
}

private struct HotelCard: View {
    let hotel: DemoHotel
    let isCurrent: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                TravelImage(url: hotel.imageURL, symbol: "bed.double.fill").frame(width: 102, height: 104).clipShape(RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) { Image(systemName: "star.fill").foregroundStyle(Color(hex: 0xE6B14C)); Text(hotel.rating).foregroundStyle(.secondary) }.font(.system(size: 11, weight: .semibold))
                    Text(hotel.name).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk).multilineTextAlignment(.leading).lineLimit(2)
                    Text(hotel.area).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(ExchangeRateService.format(hotel.pricePerNight, currencyCode: "THB", decimals: 0)).font(.system(size: 14, weight: .bold)).foregroundStyle(Color.utopiaInk)
                        Text("/ night").font(.system(size: 10)).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        if isCurrent { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: 0x568F6B)) }
                        else { Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.utopiaCoral) }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(11).background(.white, in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(Color.utopiaSoftGray.opacity(0.8), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

private struct HotelBookingSheet: View {
    let hotel: DemoHotel
    let trip: TravelTrip?
    let onConfirm: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var guests = 2
    private var nights: Int { trip?.days ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TravelImage(url: hotel.imageURL, symbol: "bed.double.fill").frame(height: 170).clipShape(RoundedRectangle(cornerRadius: 20))
            VStack(alignment: .leading, spacing: 5) {
                Text(hotel.name).font(.system(size: 21, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                Text(hotel.area).font(.system(size: 13)).foregroundStyle(.secondary)
                Text(hotel.description).font(.system(size: 13)).foregroundStyle(.secondary).padding(.top, 2)
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(nights) nights").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                    Text("\(ExchangeRateService.format(hotel.pricePerNight * Double(nights), currencyCode: "THB", decimals: 0)) total · demo")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 14) {
                    Button { guests = max(1, guests - 1) } label: { Image(systemName: "minus.circle.fill").foregroundStyle(Color.utopiaCoral).font(.system(size: 23)) }
                    Text("\(guests)").font(.system(size: 15, weight: .semibold)).monospacedDigit()
                    Button { guests = min(8, guests + 1) } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Color.utopiaCoral).font(.system(size: 23)) }
                }.buttonStyle(.plain)
            }.padding(14).background(Color.utopiaCanvas, in: RoundedRectangle(cornerRadius: 15))
            Button { onConfirm(guests); dismiss() } label: {
                Text("Save demo booking").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15).background(Color.utopiaCoral, in: Capsule())
            }.buttonStyle(.plain)
            Text("This is a local demo only. No hotel is contacted and no payment is taken.")
                .font(.system(size: 11)).foregroundStyle(.secondary).frame(maxWidth: .infinity).multilineTextAlignment(.center)
        }
        .padding(20).background(Color.utopiaCanvas.ignoresSafeArea())
    }
}

struct RecommendationsView: View {
    @ObservedObject var viewModel: ScannerViewModel
    let onSettings: () -> Void
    @State private var selectedFilter: String = "All"
    @State private var selectedPlace: TravelPlace?
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018),
                          span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09))
    )

    private let filters = ["All", "Hotels", "Food", "Things to do"]
    private var places: [TravelPlace] {
        guard selectedFilter != "All" else { return TravelPlace.bangkokHighlights }
        return TravelPlace.bangkokHighlights.filter { $0.category.title == selectedFilter }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                TravelHeader(eyebrow: "Explore around you", title: "Recommend", scale: viewModel.fontScale,
                             isBoldText: viewModel.isBoldText, onSettings: onSettings)
                HStack(spacing: 7) {
                    Image(systemName: "location.fill").font(.system(size: 10)).foregroundStyle(Color.utopiaCoral)
                    Text("Bangkok, TH · Demo area").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            Button { selectedFilter = filter } label: {
                                Text(filter).font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(selectedFilter == filter ? .white : Color.utopiaInk)
                                    .padding(.horizontal, 15).padding(.vertical, 9)
                                    .background(selectedFilter == filter ? Color.utopiaInk : .white, in: Capsule())
                                    .overlay(Capsule().stroke(selectedFilter == filter ? Color.clear : Color.utopiaSoftGray, lineWidth: 1))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                Map(position: $cameraPosition) {
                    ForEach(places) { place in
                        Annotation(place.name, coordinate: place.coordinate, anchor: .center) {
                            Button { selectedPlace = place } label: {
                                Image(systemName: place.category.symbol).font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.utopiaInk).frame(width: 32, height: 32)
                                    .background(place.category.tint, in: Circle()).overlay(Circle().stroke(.white, lineWidth: 2))
                                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 235).clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(alignment: .bottomTrailing) {
                    Label("MapKit", systemImage: "map.fill").font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.utopiaInk).padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule()).padding(10)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Around Bangkok").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                        Text("Route times are demo estimates").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(places.count) places").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }.padding(.top, 2)
                ForEach(places) { place in
                    Button { selectedPlace = place } label: { NearbyPlaceRow(place: place) }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18).padding(.top, 15).padding(.bottom, 28)
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .sheet(item: $selectedPlace) { PlaceDetailSheet(place: $0) }
    }
}

private struct NearbyPlaceRow: View {
    let place: TravelPlace
    var body: some View {
        HStack(spacing: 12) {
            TravelImage(url: place.imageURL, symbol: place.category.symbol).frame(width: 88, height: 88).clipShape(RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text(place.category.title.uppercased()).font(.system(size: 9, weight: .bold)).tracking(0.6).foregroundStyle(place.category.tint)
                    Spacer()
                    Label(place.rating, systemImage: "star.fill").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color(hex: 0xD9A63F))
                }
                Text(place.name).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk).lineLimit(1)
                Text(place.subtitle).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 8) {
                    Label("\(place.walkingMinutes)m", systemImage: "figure.walk")
                    Label("\(place.trainMinutes)m", systemImage: "tram.fill")
                    Label("\(place.drivingMinutes)m", systemImage: "car.fill")
                }.font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }.padding(10).background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct PlaceDetailSheet: View {
    let place: TravelPlace
    @State private var cameraPosition: MapCameraPosition

    init(place: TravelPlace) {
        self.place = place
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018))))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TravelImage(url: place.imageURL, symbol: place.category.symbol).frame(height: 235).clipShape(RoundedRectangle(cornerRadius: 22))
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.category.title.uppercased()).font(.system(size: 10, weight: .bold)).tracking(0.8).foregroundStyle(place.category.tint)
                        Text(place.name).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                        Text(place.subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label(place.rating, systemImage: "star.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(Color(hex: 0xD9A63F)).padding(9).background(.white, in: Capsule())
                }
                Text(place.description).font(.system(size: 14)).foregroundStyle(Color.utopiaInk.opacity(0.8)).lineSpacing(3)
                HStack(spacing: 8) {
                    transportPill("Walk", minutes: place.walkingMinutes, symbol: "figure.walk")
                    transportPill("Bus", minutes: place.busMinutes, symbol: "bus.fill")
                    transportPill("Train", minutes: place.trainMinutes, symbol: "tram.fill")
                    transportPill("Drive", minutes: place.drivingMinutes, symbol: "car.fill")
                }
                Map(position: $cameraPosition) {
                    Marker(place.name, coordinate: place.coordinate).tint(Color.utopiaCoral)
                }
                .frame(height: 175).clipShape(RoundedRectangle(cornerRadius: 18))
                Text("Map and travel times are for the Bangkok demo area.").font(.system(size: 11)).foregroundStyle(.secondary)
            }.padding(20)
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .presentationDetents([.medium, .large]).presentationDragIndicator(.visible).presentationCornerRadius(28)
    }

    private func transportPill(_ title: String, minutes: Int, symbol: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 14)).foregroundStyle(Color.utopiaCoral)
            Text("\(minutes) min").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.utopiaInk)
            Text(title).font(.system(size: 9)).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 10).background(.white, in: RoundedRectangle(cornerRadius: 13))
    }
}

private struct TripDetailSheet: View {
    let trip: TravelTrip
    private var itinerary: [TravelPlace] {
        let prefs = Set(trip.preferences)
        let matching = TravelPlace.bangkokHighlights.filter { place in
            if prefs.contains(.foodie) && place.category == .food { return true }
            if prefs.contains(.popular) && place.category == .attraction { return true }
            if prefs.contains(.shopping) && place.name.localizedCaseInsensitiveContains("market") { return true }
            return false
        }
        return matching.isEmpty ? TravelPlace.bangkokHighlights : matching
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    ZStack(alignment: .bottomLeading) {
                        TravelImage(url: TravelPlace.bangkokHighlights[0].imageURL, symbol: "sparkles").frame(height: 215)
                        LinearGradient(colors: [.clear, .black.opacity(0.68)], startPoint: .center, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("YOUR BANGKOK PLAN").font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.8))
                            Text("\(trip.days) days, your way").font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        }.padding(17)
                    }.clipShape(RoundedRectangle(cornerRadius: 22))
                    HStack(spacing: 8) {
                        detailTag(trip.budget.title, symbol: "bahtsign.circle")
                        ForEach(trip.preferences.prefix(2)) { preference in detailTag(preference.title, symbol: preference.symbol) }
                    }
                    Text("A demo itinerary").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                    ForEach(1...trip.days, id: \.self) { day in
                        VStack(alignment: .leading, spacing: 11) {
                            Text("DAY \(day)").font(.system(size: 10, weight: .bold)).tracking(0.9).foregroundStyle(Color.utopiaCoral)
                                    ForEach(Array(itinerary.enumerated()), id: \.offset) { index, place in
                                if index == (day - 1) % itinerary.count {
                                    HStack(spacing: 11) {
                                        TravelImage(url: place.imageURL, symbol: place.category.symbol).frame(width: 62, height: 62).clipShape(RoundedRectangle(cornerRadius: 12))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(["Morning", "Afternoon", "Evening"][index % 3]).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                                            Text(place.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                                            Text(place.subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                                        }
                                    }.padding(9).background(.white, in: RoundedRectangle(cornerRadius: 15))
                                }
                            }
                        }.padding(14).background(Color.utopiaCanvas, in: RoundedRectangle(cornerRadius: 18))
                    }
                    Text("Generated from local demo recommendations; no AI service is connected yet.").font(.system(size: 11)).foregroundStyle(.secondary)
                }.padding(18)
            }
            .background(Color.utopiaCanvas.ignoresSafeArea())
            .navigationTitle("Trip itinerary").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { ShareLink(item: "\(trip.days)-day Bangkok trip · \(trip.budget.title)") } }
        }
    }
    private func detailTag(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol).font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.utopiaInk)
            .padding(.horizontal, 10).padding(.vertical, 8).background(.white, in: Capsule())
    }
}

struct MoneyDashboardView: View {
    @ObservedObject var travelStore: TravelStore
    @ObservedObject var viewModel: ScannerViewModel
    let onStartScan: () -> Void
    let onCreateTrip: () -> Void
    let onSettings: () -> Void
    @State private var isHistoryPresented = false

    private var tripHistory: [ScanHistoryItem] {
        guard let tripID = travelStore.currentTrip?.id else { return [] }
        return viewModel.historyItems.filter { $0.tripID == tripID }
    }
    private var spent: Double { travelStore.spentAmount(for: travelStore.currentTrip, history: viewModel.historyItems) }
    private var tripBudgetEstimate: Double {
        guard let trip = travelStore.currentTrip else { return 0 }
        let perDay: [Double] = [900, 1500, 3000, 5500, 10000]
        return perDay[TripBudget.allCases.firstIndex(of: trip.budget) ?? 2] * Double(trip.days)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                TravelHeader(eyebrow: "Your travel wallet", title: "Money", scale: viewModel.fontScale,
                             isBoldText: viewModel.isBoldText, onSettings: onSettings)
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Label("SPENT THIS TRIP", systemImage: "chart.pie.fill").font(.system(size: 10, weight: .bold)).tracking(0.8).foregroundStyle(.white.opacity(0.75))
                        Spacer()
                        if let trip = travelStore.currentTrip {
                            Text("\(trip.city) · \(trip.days)d").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.88))
                                .padding(.horizontal, 9).padding(.vertical, 6).background(.white.opacity(0.14), in: Capsule())
                        }
                    }
                    Text(ExchangeRateService.format(spent, currencyCode: travelStore.currentTrip?.currencyCode ?? "THB", decimals: 0))
                        .font(.system(size: 34 * viewModel.fontScale, weight: viewModel.isBoldText ? .black : .bold, design: .rounded)).foregroundStyle(.white).minimumScaleFactor(0.75).lineLimit(1)
                    if travelStore.currentTrip != nil {
                        VStack(alignment: .leading, spacing: 7) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.white.opacity(0.22))
                                    Capsule().fill(.white).frame(width: geometry.size.width * min(spent / max(tripBudgetEstimate, 1), 1))
                                }
                            }.frame(height: 6)
                            HStack {
                                Text("Trip estimate \(ExchangeRateService.format(tripBudgetEstimate, currencyCode: "THB", decimals: 0))")
                                Spacer()
                                Text("\(tripHistory.count) scans")
                            }.font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.78))
                        }
                    } else {
                        Text("Create a trip to start tracking its spending.").font(.system(size: 12)).foregroundStyle(.white.opacity(0.82))
                    }
                }
                .padding(19).background(LinearGradient(colors: [Color.utopiaInk, Color(hex: 0x414852)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))

                Button(action: onStartScan) {
                    HStack(spacing: 13) {
                        Image(systemName: "viewfinder").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 48, height: 48).background(Color.utopiaCoral, in: RoundedRectangle(cornerRadius: 15))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Start scanning").font(.system(size: 16, weight: .bold)).foregroundStyle(Color.utopiaInk)
                            Text("Check change and convert currency").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.utopiaCoral)
                    }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 19))
                        .overlay(RoundedRectangle(cornerRadius: 19).stroke(Color.utopiaSoftGray.opacity(0.7), lineWidth: 1))
                }.buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("History").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                            Text(travelStore.currentTrip == nil ? "Saved scan checks" : "Latest scans for this trip").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !tripHistory.isEmpty {
                            Button("More") { isHistoryPresented = true }.font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.utopiaCoral)
                        }
                    }
                    if let latest = tripHistory.first {
                        LatestHistoryCard(item: latest, viewModel: viewModel) { isHistoryPresented = true }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No scans saved to this trip yet").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            Text("Your latest price and change checks will appear here.").font(.system(size: 12)).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 17))
                    }
                }
                if travelStore.currentTrip == nil {
                    Button("Create New Trip", action: onCreateTrip)
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.utopiaCoral)
                }
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 28)
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .sheet(isPresented: $isHistoryPresented) {
            TripHistorySheet(items: tripHistory, viewModel: viewModel)
                .presentationDetents([.large]).presentationDragIndicator(.visible).presentationCornerRadius(28)
        }
    }
}

private struct LatestHistoryCard: View {
    let item: ScanHistoryItem
    @ObservedObject var viewModel: ScannerViewModel
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Label(item.isVerified ? "Change matched" : "Review change", systemImage: item.isVerified ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(item.isVerified ? Color(hex: 0x568F6B) : Color.orange)
                    Spacer()
                    Text(item.formattedDate).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                HStack(spacing: 11) {
                    if let product = item.products.first {
                        HistoryImageThumbnail(data: viewModel.historyImageData(for: product)).frame(width: 47, height: 47).clipShape(RoundedRectangle(cornerRadius: 11))
                    } else {
                        Image(systemName: "bag").foregroundStyle(Color.utopiaCoral).frame(width: 47, height: 47).background(Color.utopiaCoral.opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.products.first?.name ?? "Scanned purchase").font(.system(size: 14 * viewModel.fontScale, weight: .semibold)).foregroundStyle(Color.utopiaInk).lineLimit(1)
                        Text("\(item.formattedTime) · \(item.products.count) item\(item.products.count == 1 ? "" : "s")").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(ExchangeRateService.format(item.priceAmount, currencyCode: item.priceCurrencyCode, decimals: 0))
                            .font(.system(size: 13 * viewModel.fontScale, weight: .bold)).foregroundStyle(Color.utopiaInk)
                        if let converted = item.convertedPrice {
                            Text("≈ \(ExchangeRateService.format(converted, currencyCode: item.convertedCurrencyCode, decimals: 0))")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }
                }
            }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain)
    }
}

private struct TripHistorySheet: View {
    let items: [ScanHistoryItem]
    @ObservedObject var viewModel: ScannerViewModel
    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView("No trip history yet", systemImage: "clock.arrow.circlepath", description: Text("Scans saved during this trip will appear here."))
                } else {
                    List(items) { item in
                        VStack(alignment: .leading, spacing: 11) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.products.first?.name ?? "Scanned purchase").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                                    Text("\(item.formattedDate) · \(item.formattedTime)").font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(ExchangeRateService.format(item.priceAmount, currencyCode: item.priceCurrencyCode, decimals: 0))
                                    .font(.system(size: 14, weight: .bold)).foregroundStyle(Color.utopiaInk)
                            }
                            if let converted = item.convertedPrice {
                                Text("Converted · \(ExchangeRateService.format(converted, currencyCode: item.convertedCurrencyCode, decimals: 2))")
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                            ForEach(item.products) { product in
                                HStack(spacing: 9) {
                                    HistoryImageThumbnail(data: viewModel.historyImageData(for: product)).frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 9))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.name).font(.system(size: 13, weight: .medium)).foregroundStyle(Color.utopiaInk)
                                        Text("\(product.quantity) × \(ExchangeRateService.format(product.price, currencyCode: product.currencyCode, decimals: 0))")
                                            .font(.system(size: 11)).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }.padding(.vertical, 7).listRowBackground(Color.utopiaCanvas).listRowSeparator(.hidden)
                    }.listStyle(.plain).scrollContentBackground(.hidden)
                }
            }
            .background(Color.utopiaCanvas.ignoresSafeArea())
            .navigationTitle("Trip history").navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct TravelImage: View {
    let url: String
    let symbol: String
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image { image.resizable().scaledToFill() }
            else {
                ZStack {
                    LinearGradient(colors: [Color(hex: 0xF4E6D9), Color(hex: 0xD9E8E0)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: symbol).font(.system(size: 26, weight: .light)).foregroundStyle(Color.utopiaCoral.opacity(0.8))
                }
            }
        }.clipped()
    }
}

private struct HistoryImageThumbnail: View {
    let data: Data?
    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    Color.utopiaCoral.opacity(0.11)
                    Image(systemName: "bag").font(.system(size: 15)).foregroundStyle(Color.utopiaCoral)
                }
            }
        }.clipped()
    }
}

private struct CoralButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 13).background(Color.utopiaCoral.opacity(configuration.isPressed ? 0.82 : 1), in: Capsule())
    }
}
