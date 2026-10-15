import MapKit
import SwiftUI
import UIKit

private struct TravelHeader: View {
    let title: String
    var scale: CGFloat = 1
    var isBoldText = false
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 27 * scale, weight: isBoldText ? .black : .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
            }
            Spacer(minLength: 8)
            Button(action: onSettings) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular.interactive(), in: Circle())
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
                    Image(systemName: "plus").font(.system(size: 17, weight: .bold)).foregroundStyle(Color.utopiaBlue)
                        .frame(width: 42, height: 42).glassEffect(.regular.interactive(), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("New Trip").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                        Text("Build an itinerary for Bangkok").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
                }
                .padding(14).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).background(Color.utopiaCanvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct CreateTripView: View {
    @ObservedObject var travelStore: TravelStore
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var step: TripComposerStep = .where
    @State private var query = ""
    @State private var selectedDates: Set<DateComponents> = []
    @State private var budgetPosition = 2.0
    @State private var selectedPreferences: Set<TripPreference> = []
    @State private var destinationSelected = false

    private var selectedBudget: TripBudget {
        TripBudget.allCases[min(max(Int(budgetPosition.rounded()), 0), TripBudget.allCases.count - 1)]
    }
    private var selectedDateRange: (start: Date, end: Date)? {
        let dates = selectedDates.compactMap { Calendar.current.date(from: $0) }.sorted()
        guard let first = dates.first, let last = dates.last else { return nil }
        return (first, last)
    }
    private var chosenDays: Int {
        guard let dates = selectedDateRange else { return 1 }
        return max(1, (Calendar.current.dateComponents([.day], from: dates.start, to: dates.end).day ?? 0) + 1)
    }
    private var dateLimit: Range<Date> {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .year, value: 2, to: start) ?? start
        return start..<end
    }
    private let cityOptions: [(name: String, country: String, flag: String)] = [
        ("Tokyo", "Japan", "🇯🇵"), ("Paris", "France", "🇫🇷"), ("Rome", "Italy", "🇮🇹"),
        ("Bangkok", "Thailand", "🇹🇭"), ("Chiang Mai", "Thailand", "🇹🇭"),
        ("Phuket", "Thailand", "🇹🇭"), ("Seoul", "South Korea", "🇰🇷")
    ]
    private var matchingCities: [(name: String, country: String, flag: String)] {
        guard !query.isEmpty else { return cityOptions }
        return cityOptions.filter { "\($0.name) \($0.country)".localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Color.clear.frame(width: 44, height: 44)
                Spacer()
                Text("Create Trip").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.utopiaInk).frame(width: 42, height: 42)
                        .glassEffect(.regular.interactive(), in: Circle())
                }.buttonStyle(ScaleButtonStyle()).accessibilityLabel("Close")
            }.padding(.horizontal, 20).padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 11) {
                    ForEach(TripComposerStep.allCases, id: \.self) { section in
                        accordionSection(section)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 20)
            }

            if step == .preferences {
                Button(action: createTrip) {
                    Label("Create trip", systemImage: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity).frame(height: 52)
                }
                .buttonStyle(.glassProminent).tint(Color.utopiaBlue)
                .disabled(selectedPreferences.isEmpty)
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func accordionSection(_ section: TripComposerStep) -> some View {
        let isOpen = step == section
        VStack(alignment: .leading, spacing: isOpen ? 15 : 0) {
            Button {
                withAnimation(.snappy(duration: 0.28)) { step = section }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(section.title).font(.system(size: isOpen ? 20 : 15, weight: .bold, design: .rounded))
                            .foregroundStyle(isOpen ? Color.utopiaInk : Color.secondary)
                        if !isOpen {
                            Text(summary(for: section)).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.utopiaBlue)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    if !isOpen {
                        Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isOpen {
                stepContent.transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(isOpen ? 16 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.utopiaSoftGray.opacity(isOpen ? 0.55 : 0.35), lineWidth: 1))
        .animation(.snappy(duration: 0.25), value: step)
    }

    private func summary(for section: TripComposerStep) -> String {
        switch section {
        case .where: return destinationSelected ? "Bangkok, Thailand" : "Choose destination"
        case .when:
            if let range = selectedDateRange {
                return "\(range.start.formatted(date: .abbreviated, time: .omitted)) – \(range.end.formatted(date: .abbreviated, time: .omitted))"
            } else { return "Choose travel dates" }
        case .budget: return selectedBudget.title
        case .preferences:
            let names = TripPreference.allCases.filter { selectedPreferences.contains($0) }.map(\.title)
            return names.isEmpty ? "Choose interests" : names.joined(separator: " · ")
        }
    }

    private func advance(to next: TripComposerStep) {
        withAnimation(.snappy(duration: 0.28)) { step = next }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .where:
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search for a destination", text: $query).textInputAutocapitalization(.words)
                }
                .padding(16).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 4) {
                    Label("Trending", systemImage: "flame.fill").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    ForEach(matchingCities, id: \.name) { city in
                        Button {
                            guard city.name == "Bangkok" else { return }
                            destinationSelected = true
                            advance(to: .when)
                        } label: {
                        HStack(spacing: 13) {
                            Text(city.flag).font(.system(size: 28)).frame(width: 48, height: 48)
                                .background(Color.utopiaCanvas, in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(city.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                                Text(city.country).font(.system(size: 13)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if destinationSelected && city.name == "Bangkok" {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.utopiaBlue)
                            } else {
                                Text("Soon").font(.system(size: 11, weight: .medium)).foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                        .overlay(alignment: .bottom) { if city.name != matchingCities.last?.name { Divider().padding(.leading, 62) } }
                        }
                        .buttonStyle(.plain)
                        .disabled(city.name != "Bangkok")
                    }
                }.padding(16).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 22))
            }

        case .when:
            VStack(alignment: .leading, spacing: 12) {
                MultiDatePicker("Choose your trip dates", selection: $selectedDates, in: dateLimit)
                    .tint(Color.utopiaBlue)
                    .onChange(of: selectedDates) { _, newValue in
                        if newValue.count > 2 {
                            let dates = newValue.compactMap { Calendar.current.date(from: $0) }.sorted()
                            selectedDates = Set([dates.first, dates.last].compactMap { $0 }.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) })
                        }
                        if newValue.count == 2 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                if step == .when, selectedDateRange != nil { advance(to: .budget) }
                            }
                        }
                    }
                if let range = selectedDateRange {
                    Label("\(range.start.formatted(date: .abbreviated, time: .omitted)) – \(range.end.formatted(date: .abbreviated, time: .omitted)) · \(chosenDays) day\(chosenDays == 1 ? "" : "s")",
                          systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.utopiaBlue)
                } else {
                    Text("Select one date for a day trip, or two dates for an overnight stay.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                if selectedDateRange != nil {
                    Button { advance(to: .budget) } label: {
                        Label("Continue", systemImage: "arrow.right")
                            .font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }.buttonStyle(.glassProminent).tint(Color.utopiaBlue)
                }
            }

        case .budget:
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text(selectedBudget.title).font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                        Spacer()
                    }
                    Text(selectedBudget.detail).font(.system(size: 13)).foregroundStyle(.secondary)
                }
                Slider(value: $budgetPosition, in: 0...Double(TripBudget.allCases.count - 1), step: 1) { editing in
                    if !editing { advance(to: .preferences) }
                }
                    .tint(Color.utopiaBlue)
                    HStack(spacing: 0) {
                        ForEach(Array(TripBudget.allCases.enumerated()), id: \.element.id) { index, option in
                            VStack(spacing: 7) {
                                Circle()
                                    .fill(index == Int(budgetPosition) ? Color.utopiaBlue : Color.utopiaSoftGray)
                                    .frame(width: index == Int(budgetPosition) ? 11 : 7, height: index == Int(budgetPosition) ? 11 : 7)
                                Text(shortBudgetName(option))
                                    .font(.system(size: 9, weight: index == Int(budgetPosition) ? .bold : .medium))
                                    .foregroundStyle(index == Int(budgetPosition) ? Color.utopiaBlue : Color.secondary)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                .padding(19).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 22))
                .sensoryFeedback(.selection, trigger: selectedBudget)
                Button { advance(to: .preferences) } label: {
                    Label("Continue", systemImage: "arrow.right")
                        .font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                }.buttonStyle(.glassProminent).tint(Color.utopiaBlue)
            }

        case .preferences:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 11) {
                ForEach(TripPreference.allCases) { preference in
                    let isSelected = selectedPreferences.contains(preference)
                    Button {
                        if isSelected { selectedPreferences.remove(preference) }
                        else { selectedPreferences.insert(preference) }
                    } label: {
                        HStack(spacing: 12) {
                            Text(preferenceEmoji(preference)).font(.system(size: 29))
                                .frame(width: 48, height: 48)
                                .background(preferenceColor(preference).opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            Text(preference.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            Spacer(minLength: 0)
                        }
                        .padding(10).frame(maxWidth: .infinity, minHeight: 72)
                        .background(isSelected ? preferenceColor(preference).opacity(0.1) : Color.utopiaCard, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(isSelected ? preferenceColor(preference).opacity(0.55) : Color.utopiaSoftGray.opacity(0.6), lineWidth: 1))
                    }.buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    private func shortBudgetName(_ budget: TripBudget) -> String {
        switch budget {
        case .ultraBudget: "Shoestring"
        case .budget: "Budget"
        case .moderate: "Mid"
        case .upscale: "Upscale"
        case .luxury: "Luxury"
        }
    }

    private func preferenceEmoji(_ preference: TripPreference) -> String {
        switch preference {
        case .shopping: "🛍️"
        case .popular: "📍"
        case .foodie: "🍜"
        case .culture: "🏛️"
        case .nature: "🌿"
        case .nightlife: "🎉"
        }
    }

    private func preferenceColor(_ preference: TripPreference) -> Color {
        switch preference {
        case .shopping: Color(hex: 0xE98A63)
        case .popular: Color(hex: 0x63A4F2)
        case .foodie: Color(hex: 0xE7A84C)
        case .culture: Color(hex: 0x9C83D5)
        case .nature: Color(hex: 0x65A987)
        case .nightlife: Color(hex: 0xD77BAF)
        }
    }

    private func createTrip() {
        let dates = selectedDateRange
        travelStore.createBangkokTrip(days: chosenDays, budget: selectedBudget,
                                      preferences: TripPreference.allCases.filter { selectedPreferences.contains($0) },
                                      startDate: dates?.start, endDate: dates?.end)
        onCreated()
    }
}

private enum TripComposerStep: Int, CaseIterable {
    case `where`, when, budget, preferences

    var title: String {
        switch self {
        case .where: "Where"
        case .when: "When"
        case .budget: "What feels right?"
        case .preferences: "Preferences"
        }
    }
    var subtitle: String {
        switch self {
        case .where: "Choose a city to start your next adventure."
        case .when: "Choose your travel dates."
        case .budget: "Choose a pace that feels right for your trip."
        case .preferences: "Pick a few interests for your Bangkok plan."
        }
    }
}

struct TripHomeView: View {
    @ObservedObject var travelStore: TravelStore
    @ObservedObject var viewModel: ScannerViewModel
    let onOpenBooking: () -> Void
    let onSettings: () -> Void
    @State private var activeSheet: TripHomeSheet?

    private let highlights = Array(TravelPlace.bangkokHighlights.prefix(3))

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 25) {
                HStack(alignment: .center) {
                    Label("Bangkok, Thailand", systemImage: "location.fill")
                        .font(.system(size: 19 * viewModel.fontScale, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.utopiaInk)
                    Spacer()
                    Button(action: onSettings) {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            .frame(width: 44, height: 44).glassEffect(.regular.interactive(), in: Circle())
                    }.buttonStyle(ScaleButtonStyle()).accessibilityLabel("Text settings")
                }

                VStack(alignment: .leading, spacing: 13) {
                    Text("My Trips").font(.system(size: 22 * viewModel.fontScale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                    if travelStore.trips.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your next story starts here").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            Text("Create a trip and we’ll keep every day in one lovely plan.").font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(18)
                        .background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 22))
                    } else {
                        VStack(spacing: 11) {
                            ForEach(travelStore.trips) { trip in
                                HStack(spacing: 13) {
                                    Button {
                                        travelStore.selectTrip(trip)
                                        activeSheet = .trip(trip)
                                    } label: {
                                        TripHomeCard(trip: trip, scale: viewModel.fontScale)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    Menu {
                                        Button {
                                            withAnimation(.snappy(duration: 0.22)) { _ = travelStore.duplicateTrip(trip) }
                                        } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                                        Button(role: .destructive) { activeSheet = .delete(trip) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(.secondary)
                                            .frame(width: 36, height: 48).contentShape(Rectangle())
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .accessibilityLabel("Trip options")
                                }
                                .padding(9).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 23))
                                .overlay(RoundedRectangle(cornerRadius: 23).stroke(Color.utopiaSoftGray.opacity(0.55), lineWidth: 1))
                            }
                        }
                    }
                    Button { activeSheet = .createTrip } label: {
                        Label("Create New Trip", systemImage: "plus")
                            .font(.system(size: 16 * viewModel.fontScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.utopiaBlue).frame(maxWidth: .infinity).frame(height: 70)
                            .background(Color.utopiaCard.opacity(0.65), in: RoundedRectangle(cornerRadius: 21))
                            .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(Color.utopiaBlue.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [7, 7])) )
                    }.buttonStyle(ScaleButtonStyle())
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Guides").font(.system(size: 22 * viewModel.fontScale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 13) {
                            ForEach(highlights) { place in
                                Button { activeSheet = .place(place) } label: { PlaceFeatureCard(place: place) }
                                    .buttonStyle(ScaleButtonStyle())
                            }
                        }.padding(.vertical, 2)
                    }
                }
            }
            .padding(.horizontal, 19).padding(.top, 15).padding(.bottom, 32)
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .place(let place): PlaceDetailSheet(place: place)
            case .createTrip:
                NavigationStack {
                    CreateTripView(travelStore: travelStore) { activeSheet = nil }
                }
                .presentationDetents([.large]).presentationDragIndicator(.visible).presentationCornerRadius(30)
            case .trip(let trip): TripDetailSheet(trip: trip,
                                                  booking: travelStore.bookings.first { $0.tripID == trip.id },
                                                  fontScale: viewModel.fontScale,
                                                  onBookHotel: {
                                                      activeSheet = nil
                                                      onOpenBooking()
                                                  })
                    .presentationDetents([.large]).presentationDragIndicator(.visible)
            case .delete(let trip): DeleteTripConfirmationSheet(trip: trip) {
                    withAnimation(.snappy(duration: 0.25)) { travelStore.deleteTrip(trip) }
                    activeSheet = nil
                }
                .presentationDetents([.height(405)]).presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
            }
        }
        .animation(.snappy(duration: 0.22), value: travelStore.trips)
    }
}

private enum TripHomeSheet: Identifiable {
    case place(TravelPlace)
    case createTrip
    case trip(TravelTrip)
    case delete(TravelTrip)
    var id: String {
        switch self {
        case .place(let place): "place-\(place.id)"
        case .createTrip: "create-trip"
        case .trip(let trip): "trip-\(trip.id.uuidString)"
        case .delete(let trip): "delete-\(trip.id.uuidString)"
        }
    }
}

private struct TripHomeCard: View {
    let trip: TravelTrip
    var scale: CGFloat = 1
    var body: some View {
        HStack(spacing: 13) {
            TravelImage(url: TravelPlace.bangkokHighlights[0].imageURL, symbol: "building.columns.fill")
                .frame(width: 91, height: 105).clipShape(RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 9) {
                Text("\(trip.days) Day\(trip.days == 1 ? "" : "s") in \(trip.city)")
                    .font(.system(size: 18 * scale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                    .lineLimit(1).minimumScaleFactor(0.8)
                HStack(spacing: 6) {
                    Label("\(trip.days)d", systemImage: "calendar")
                        .padding(.horizontal, 9).padding(.vertical, 6).background(Color.utopiaSoftGray.opacity(0.55), in: Capsule())
                    Label("\(trip.days * 3) Spots", systemImage: "mappin.and.ellipse")
                        .foregroundStyle(Color.utopiaBlue).padding(.horizontal, 9).padding(.vertical, 6)
                        .background(Color.utopiaBlue.opacity(0.08), in: Capsule())
                }
                .font(.system(size: 11 * scale, weight: .semibold)).foregroundStyle(.secondary)
                Text(trip.startDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "\(trip.budget.title) · Bangkok, Thailand")
                    .font(.system(size: 11 * scale)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
    }
}

private struct DeleteTripConfirmationSheet: View {
    let trip: TravelTrip
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(Color.utopiaSoftGray).frame(width: 38, height: 5).padding(.top, 11)
            Text("Remove this trip?").font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
            HStack(spacing: 12) {
                TravelImage(url: TravelPlace.bangkokHighlights[0].imageURL, symbol: "building.columns.fill")
                    .frame(width: 82, height: 88).clipShape(RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 7) {
                    Text("\(trip.days) Days in \(trip.city)").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                    Text("\(trip.days) days · \(trip.days * 3) spots").font(.system(size: 12)).foregroundStyle(.secondary)
                    Text("Your saved scan history will remain.").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(10).background(Color.utopiaCanvas, in: RoundedRectangle(cornerRadius: 19))
            HStack(spacing: 10) {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                    .frame(maxWidth: .infinity).frame(height: 52).background(Color.utopiaCard, in: Capsule())
                    .overlay(Capsule().stroke(Color.utopiaSoftGray, lineWidth: 1)).buttonStyle(ScaleButtonStyle())
                Button(role: .destructive) {
                    onDelete()
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52).background(Color.red, in: Capsule())
                }.buttonStyle(ScaleButtonStyle())
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).background(Color.utopiaCard.ignoresSafeArea())
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
                .frame(width: 30, height: 30).background(Color.utopiaCard.opacity(0.93), in: Circle()).padding(11)
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
                TravelHeader(title: "Booking", scale: viewModel.fontScale,
                             isBoldText: viewModel.isBoldText, onSettings: onSettings)
                if let trip = travelStore.currentTrip {
                    HStack(spacing: 10) {
                        Image(systemName: "suitcase.rolling.fill").foregroundStyle(Color.utopiaBlue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("For your Bangkok trip").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            Text("\(trip.maximumHotelNights) night\(trip.maximumHotelNights == 1 ? "" : "s") · \(tripDateDescription(trip))")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }.padding(14).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 16))

                    if let booking = travelStore.currentTripBooking {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("BOOKING SAVED", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundStyle(Color.utopiaSuccess)
                            Text(booking.hotelName).font(.system(size: 16, weight: .bold)).foregroundStyle(Color.utopiaInk)
                            Text("\(min(booking.nights, trip.maximumHotelNights)) night\(min(booking.nights, trip.maximumHotelNights) == 1 ? "" : "s") · \(ExchangeRateService.format(booking.pricePerNight * Double(min(booking.nights, trip.maximumHotelNights)), currencyCode: booking.currencyCode, decimals: 0)) total")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.utopiaSuccessBackground, in: RoundedRectangle(cornerRadius: 17))
                    }

                    VStack(alignment: .leading, spacing: 13) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Places to stay").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                            Text(trip.days > 1 ? "Choose where you’d like to stay." : "Overnight stays need a trip of at least two days.")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        ForEach(DemoHotel.bangkok) { hotel in
                            HotelCard(hotel: hotel, isCurrent: travelStore.currentTripBooking?.hotelID == hotel.id,
                                      isEnabled: trip.days > 1) {
                                selectedHotel = hotel
                            }
                        }
                    }
                } else {
                    VStack(spacing: 13) {
                        Image(systemName: "bed.double.fill").font(.system(size: 30)).foregroundStyle(Color.utopiaBlue)
                        Text("A stay starts with a trip").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                        Text("Create a Bangkok trip before choosing a place to stay.").font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button(action: onCreateTrip) {
                            Text("Create New Trip").font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                        .buttonStyle(.glassProminent).tint(Color.utopiaBlue)
                    }.frame(maxWidth: .infinity).padding(28).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 22))
                }
            }
            .padding(.horizontal, 20).padding(.top, 15).padding(.bottom, 28)
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .sheet(item: $selectedHotel) { hotel in
            HotelBookingSheet(hotel: hotel, trip: travelStore.currentTrip) { nights in
                if travelStore.confirmHotelBooking(hotel: hotel, nights: nights) != nil {
                    selectedHotel = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showConfirmation = true }
                }
            }
            .presentationDetents([.medium, .large]).presentationDragIndicator(.visible).presentationCornerRadius(28)
        }
        .alert("Booking saved", isPresented: $showConfirmation) {
            Button("Done", role: .cancel) { }
        } message: {
            Text("This hotel has been added to your current trip plan.")
        }
    }

    private func tripDateDescription(_ trip: TravelTrip) -> String {
        guard let start = trip.startDate else { return "Bangkok" }
        if let end = trip.endDate { return "\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))" }
        return start.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct HotelCard: View {
    let hotel: DemoHotel
    let isCurrent: Bool
    var isEnabled = true
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
                        if isCurrent { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.utopiaSuccess) }
                        else { Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.utopiaBlue) }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(11).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(Color.utopiaSoftGray.opacity(0.8), lineWidth: 1))
        }.buttonStyle(.plain).disabled(!isEnabled).opacity(isEnabled ? 1 : 0.48)
    }
}

private struct HotelBookingSheet: View {
    let hotel: DemoHotel
    let trip: TravelTrip?
    let onConfirm: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var nights = 1
    private var maximumNights: Int { trip?.maximumHotelNights ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TravelImage(url: hotel.imageURL, symbol: "bed.double.fill").frame(height: 170).clipShape(RoundedRectangle(cornerRadius: 20))
            VStack(alignment: .leading, spacing: 5) {
                Text(hotel.name).font(.system(size: 21, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                Text(hotel.area).font(.system(size: 13)).foregroundStyle(.secondary)
                Text(hotel.description).font(.system(size: 13)).foregroundStyle(.secondary).padding(.top, 2)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Choose nights · up to \(maximumNights)")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                HStack(spacing: 14) {
                    Button { nights = max(1, nights - 1) } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(Color.utopiaBlue).font(.system(size: 25))
                    }.disabled(nights <= 1)
                    Text("\(nights) night\(nights == 1 ? "" : "s")")
                        .font(.system(size: 15, weight: .semibold)).monospacedDigit()
                        .contentTransition(.numericText())
                    Button { nights = min(maximumNights, nights + 1) } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.utopiaBlue).font(.system(size: 25))
                    }.disabled(nights >= maximumNights)
                    Spacer()
                }.buttonStyle(.plain)
                Divider()
                HStack {
                    Text("Total").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                    Spacer()
                    Text(ExchangeRateService.format(hotel.pricePerNight * Double(nights), currencyCode: "THB", decimals: 0))
                        .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                }
            }.padding(14).background(Color.utopiaCanvas, in: RoundedRectangle(cornerRadius: 15))
            Button { onConfirm(nights); dismiss() } label: {
                Text("Confirm booking").font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
            }.buttonStyle(.glassProminent).tint(Color.utopiaBlue).disabled(maximumNights == 0)
        }
        .padding(20).background(Color.utopiaCanvas.ignoresSafeArea())
        .onAppear { nights = max(1, maximumNights) }
    }
}

struct RecommendationsView: View {
    @ObservedObject var viewModel: ScannerViewModel
    let onSettings: () -> Void
    @State private var selectedFilter: String = "All"
    @State private var selectedPlace: TravelPlace?
    @State private var isAroundPresented = true
    @State private var aroundDetent: PresentationDetent = .medium
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018),
                          span: MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045))
    )

    private let filters = ["All", "Hotels", "Food", "Things to do"]
    private var places: [TravelPlace] {
        guard selectedFilter != "All" else { return TravelPlace.bangkokHighlights }
        return TravelPlace.bangkokHighlights.filter { $0.category.title == selectedFilter }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                ForEach(places) { place in
                    Annotation(place.name, coordinate: place.coordinate, anchor: .center) {
                        Button { selectedPlace = place } label: {
                            Image(systemName: place.category.symbol).font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.utopiaInk).frame(width: 34, height: 34)
                                .background(place.category.tint, in: Circle()).overlay(Circle().stroke(.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
                        }.buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls { MapCompass(); MapScaleView() }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Label("Bangkok, Thailand", systemImage: "location.fill")
                            .font(.system(size: 18 * viewModel.fontScale, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.utopiaInk)
                        Text("Explore nearby places").font(.system(size: 11 * viewModel.fontScale)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: onSettings) {
                        Image(systemName: "textformat.size").font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.utopiaInk).frame(width: 42, height: 42)
                            .glassEffect(.regular.interactive(), in: Circle())
                    }.buttonStyle(ScaleButtonStyle()).accessibilityLabel("Text settings")
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            Button { selectedFilter = filter } label: {
                                Text(filter).font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(selectedFilter == filter ? .white : Color.utopiaInk)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(selectedFilter == filter ? Color.utopiaInk : Color.utopiaCard.opacity(0.94), in: Capsule())
                            }.buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                Spacer()
                if !isAroundPresented {
                    Button { isAroundPresented = true } label: {
                        Label("Around Bangkok · \(places.count) places", systemImage: "line.3.horizontal.decrease")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            .padding(.horizontal, 17).padding(.vertical, 12).background(.regularMaterial, in: Capsule())
                    }.buttonStyle(ScaleButtonStyle()).padding(.bottom, 96)
                }
            }
            .padding(.horizontal, 18).padding(.top, 12)
        }
        .sheet(isPresented: $isAroundPresented) {
            AroundBangkokSheet(places: places, selectedFilter: $selectedFilter, selectedPlace: $selectedPlace,
                               fontScale: viewModel.fontScale)
                .presentationDetents([.medium, .large], selection: $aroundDetent)
                .presentationDragIndicator(.visible).presentationCornerRadius(28)
        }
    }
}

private struct AroundBangkokSheet: View {
    let places: [TravelPlace]
    @Binding var selectedFilter: String
    @Binding var selectedPlace: TravelPlace?
    var fontScale: CGFloat = 1
    private let filters = ["All", "Hotels", "Food", "Things to do"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Around Bangkok").font(.system(size: 21 * fontScale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                    Text("\(places.count) nearby places").font(.system(size: 12 * fontScale)).foregroundStyle(.secondary)
                }
                Spacer()
            }.padding(.top, 8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        Button { selectedFilter = filter } label: {
                            Text(filter).font(.system(size: 12 * fontScale, weight: .semibold))
                                .foregroundStyle(selectedFilter == filter ? .white : Color.utopiaInk)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selectedFilter == filter ? Color.utopiaInk : Color.utopiaSoftGray.opacity(0.5), in: Capsule())
                        }.buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 9) {
                    ForEach(places) { place in
                        Button { selectedPlace = place } label: { NearbyPlaceRow(place: place) }
                            .buttonStyle(ScaleButtonStyle())
                    }
                }.padding(.bottom, 22)
            }
        }
        .padding(.horizontal, 18).background(Color.utopiaCanvas.ignoresSafeArea())
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
        }.padding(10).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 18))
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
            Label(place.rating, systemImage: "star.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(Color(hex: 0xD9A63F)).padding(9).background(Color.utopiaCard, in: Capsule())
                }
                Text(place.description).font(.system(size: 14)).foregroundStyle(Color.utopiaInk.opacity(0.8)).lineSpacing(3)
                HStack(spacing: 8) {
                    transportPill("Walk", minutes: place.walkingMinutes, symbol: "figure.walk")
                    transportPill("Bus", minutes: place.busMinutes, symbol: "bus.fill")
                    transportPill("Train", minutes: place.trainMinutes, symbol: "tram.fill")
                    transportPill("Drive", minutes: place.drivingMinutes, symbol: "car.fill")
                }
                Button(action: startNavigation) {
                    Label("Start navigation", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                }
                .buttonStyle(.glassProminent).tint(Color.utopiaBlue)
                Map(position: $cameraPosition) {
                    Marker(place.name, coordinate: place.coordinate).tint(Color.utopiaBlue)
                }
                .frame(height: 175).clipShape(RoundedRectangle(cornerRadius: 18))
                Text("Travel times are approximate.").font(.system(size: 11)).foregroundStyle(.secondary)
            }.padding(20)
        }
        .background(Color.utopiaCanvas.ignoresSafeArea())
        .presentationDetents([.medium, .large]).presentationDragIndicator(.visible).presentationCornerRadius(28)
    }

    private func transportPill(_ title: String, minutes: Int, symbol: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 14)).foregroundStyle(Color.utopiaBlue)
            Text("\(minutes) min").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.utopiaInk)
            Text(title).font(.system(size: 9)).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 10).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 13))
    }

    private func startNavigation() {
        let destination = MKMapItem(location: CLLocation(latitude: place.latitude, longitude: place.longitude), address: nil)
        destination.name = place.name
        MKMapItem.openMaps(with: [.forCurrentLocation(), destination],
                           launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

private struct TripDetailSheet: View {
    let trip: TravelTrip
    let booking: DemoHotelBooking?
    var fontScale: CGFloat = 1
    let onBookHotel: () -> Void
    @State private var selectedDay: Int?

    private var itinerary: [TravelPlace] {
        let prefs = Set(trip.preferences)
        let matching = TravelPlace.bangkokHighlights.filter { place in
            if prefs.contains(.foodie) && place.category == .food { return true }
            if prefs.contains(.popular) && place.category == .attraction { return true }
            if prefs.contains(.shopping) && place.name.localizedCaseInsensitiveContains("market") { return true }
            return false
        }
        let rest = TravelPlace.bangkokHighlights.filter { place in !matching.contains(where: { $0.id == place.id }) }
        return matching + rest
    }
    private var bangkokCenter: TravelPlace { TravelDemoRoute.start }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(spacing: 13) {
                        TravelImage(url: TravelPlace.bangkokHighlights[0].imageURL, symbol: "building.columns.fill")
                            .frame(width: 92, height: 112).clipShape(RoundedRectangle(cornerRadius: 19))
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(trip.days == 2 ? "Two" : "\(trip.days)") Days in \(trip.city)")
                                .font(.system(size: 21 * fontScale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                                .lineLimit(2)
                            Text("\(trip.days) days · \(trip.days * 3) spots")
                                .font(.system(size: 13 * fontScale, weight: .medium)).foregroundStyle(.secondary)
                            Text(tripDateSummary).font(.system(size: 11 * fontScale)).foregroundStyle(Color.utopiaBlue)
                        }
                        Spacer(minLength: 0)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            planTab(title: "Overview", day: nil)
                            ForEach(1...trip.days, id: \.self) { day in planTab(title: "Day \(day)", day: day) }
                        }.padding(.vertical, 2)
                    }

                    if let day = selectedDay {
                        dayPlan(day)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            hotelOverview
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Your days").font(.system(size: 19 * fontScale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                                    Text("Tap a day to see stops and how to get there.").font(.system(size: 12 * fontScale)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "map.fill").foregroundStyle(Color.utopiaBlue)
                                    .frame(width: 42, height: 42).background(Color.utopiaBlue.opacity(0.09), in: Circle())
                            }
                            ForEach(1...trip.days, id: \.self) { day in
                                Button { selectedDay = day } label: {
                                    DayOverviewCard(day: day, places: places(for: day), date: date(for: day), scale: fontScale)
                                }.buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    Text("Times and distances are approximate.")
                        .font(.system(size: 11 * fontScale)).foregroundStyle(.tertiary)
                }.padding(18)
            }
            .background(Color.utopiaCanvas.ignoresSafeArea())
            .navigationTitle("My Trip").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: "\(trip.days)-day Bangkok trip · \(trip.budget.title)")
                        .tint(Color.utopiaBlue)
                }
            }
            .animation(.snappy(duration: 0.24), value: selectedDay)
        }
    }

    private var hotelOverview: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label("Hotel", systemImage: "bed.double.fill")
                .font(.system(size: 16 * fontScale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
            if let booking {
                HStack(spacing: 11) {
                    TravelImage(url: DemoHotel.bangkok.first(where: { $0.id == booking.hotelID })?.imageURL ?? "",
                                symbol: "bed.double.fill")
                        .frame(width: 68, height: 62).clipShape(RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(booking.hotelName).font(.system(size: 14 * fontScale, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                    Text("\(min(booking.nights, trip.maximumHotelNights)) night\(min(booking.nights, trip.maximumHotelNights) == 1 ? "" : "s")")
                            .font(.system(size: 11 * fontScale)).foregroundStyle(.secondary)
                        Text(ExchangeRateService.format(booking.totalPrice, currencyCode: booking.currencyCode, decimals: 0))
                            .font(.system(size: 11 * fontScale, weight: .semibold)).foregroundStyle(Color.utopiaBlue)
                    }
                    Spacer(minLength: 0)
                }
            } else if trip.days == 1 {
                Text("No overnight stay for a one-day trip.")
                    .font(.system(size: 12 * fontScale)).foregroundStyle(.secondary)
            } else {
                Text("No hotel added yet.").font(.system(size: 12 * fontScale)).foregroundStyle(.secondary)
            }
            Button(action: onBookHotel) {
                Label(booking == nil ? "Book hotel" : "Change hotel", systemImage: "bed.double")
                    .font(.system(size: 13 * fontScale, weight: .semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 11)
            }
            .buttonStyle(.glassProminent).tint(Color.utopiaBlue)
            .disabled(trip.maximumHotelNights == 0)
            .opacity(trip.maximumHotelNights == 0 ? 0.5 : 1)
        }
        .padding(14).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 18))
    }

    private var tripDateSummary: String {
        guard let start = trip.startDate else { return "Bangkok, Thailand" }
        if let end = trip.endDate, end != start {
            return "\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))"
        }
        return start.formatted(date: .abbreviated, time: .omitted)
    }

    private func date(for day: Int) -> Date? {
        guard let start = trip.startDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: day - 1, to: start)
    }

    private func places(for day: Int) -> [TravelPlace] {
        guard !itinerary.isEmpty else { return [] }
        return (0..<3).map { offset in itinerary[((day - 1) * 3 + offset) % itinerary.count] }
    }

    @ViewBuilder
    private func planTab(title: String, day: Int?) -> some View {
        let isSelected = selectedDay == day
        Button { selectedDay = day } label: {
            HStack(spacing: 7) {
                if day == nil { Image(systemName: "map").font(.system(size: 13, weight: .semibold)) }
                Text(title).font(.system(size: 13 * fontScale, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Color.white : Color.secondary)
            .padding(.horizontal, 16).frame(height: 43)
            .background(isSelected ? Color.utopiaInk : Color.utopiaSoftGray.opacity(0.55), in: Capsule())
        }.buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func dayPlan(_ day: Int) -> some View {
        let stops = places(for: day)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(day) in Bangkok").font(.system(size: 19 * fontScale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk)
                    Text(date(for: day)?.formatted(date: .complete, time: .omitted) ?? "A day made for exploring")
                        .font(.system(size: 12 * fontScale)).foregroundStyle(.secondary)
                }
                Spacer()
                Label("3 spots", systemImage: "mappin.and.ellipse").font(.system(size: 11 * fontScale, weight: .semibold))
                    .foregroundStyle(Color.utopiaBlue).padding(.horizontal, 10).padding(.vertical, 8)
                    .background(Color.utopiaBlue.opacity(0.09), in: Capsule())
            }
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, place in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        Text(["9:00 AM", "12:30 PM", "4:00 PM"][index])
                            .font(.system(size: 11 * fontScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.utopiaBlue).padding(.top, 4).frame(width: 63, alignment: .leading)
                        HStack(spacing: 11) {
                            TravelImage(url: place.imageURL, symbol: place.category.symbol)
                                .frame(width: 69, height: 72).clipShape(RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name).font(.system(size: 15 * fontScale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk).lineLimit(1)
                                Text(place.subtitle).font(.system(size: 11 * fontScale)).foregroundStyle(.secondary).lineLimit(1)
                                Label(place.category.title, systemImage: place.category.symbol)
                                    .font(.system(size: 10 * fontScale, weight: .medium)).foregroundStyle(Color.utopiaBlue)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(9).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 19))
                        .overlay(RoundedRectangle(cornerRadius: 19).stroke(Color.utopiaSoftGray.opacity(0.55), lineWidth: 1))
                    }
                    if index > 0 {
                        TripRouteLegView(origin: stops[index - 1], destination: place, fontScale: fontScale)
                            .padding(.leading, 63)
                    } else {
                        TripRouteLegView(origin: bangkokCenter, destination: place, fontScale: fontScale)
                            .padding(.leading, 63)
                    }
                }
            }
        }
    }

}

private struct DayOverviewCard: View {
    let day: Int
    let places: [TravelPlace]
    let date: Date?
    var scale: CGFloat = 1

    var body: some View {
        HStack(spacing: 12) {
            Text("Day \(day)").font(.system(size: 13 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(.white).padding(.horizontal, 12).padding(.vertical, 9)
                .background(dayTint, in: Capsule())
            VStack(alignment: .leading, spacing: 4) {
                Text(dayName).font(.system(size: 15 * scale, weight: .bold, design: .rounded)).foregroundStyle(Color.utopiaInk).lineLimit(1)
                Text(date?.formatted(date: .abbreviated, time: .omitted) ?? "\(places.count) places to explore")
                    .font(.system(size: 11 * scale)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text("~\(totalDistance, specifier: "%.1f") km · \(places.count) spots")
                .font(.system(size: 11 * scale, weight: .medium)).foregroundStyle(.secondary)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(Color.utopiaSoftGray.opacity(0.6), lineWidth: 1))
    }

    private var dayName: String {
        switch day % 3 {
        case 1: "Temples, river & old town"
        case 2: "Markets, cafés & local life"
        default: "A Bangkok day out"
        }
    }

    private var dayTint: Color {
        [Color(hex: 0xD99A32), Color.utopiaBlue, Color(hex: 0xD96D9D), Color(hex: 0x5E9A78), Color(hex: 0x8877C7)][(day - 1) % 5]
    }

    private var totalDistance: Double {
        guard let first = places.first else { return 0 }
        let startDistance = TripTravelMode.walk.distanceKm(from: TravelDemoRoute.start, to: first)
        return startDistance + zip(places, places.dropFirst()).reduce(0) { $0 + TripTravelMode.walk.distanceKm(from: $1.0, to: $1.1) }
    }
}

private enum TravelDemoRoute {
    static let start = TravelPlace(id: "bangkok-start", name: "Central Bangkok", subtitle: "Trip starting point",
                                   category: .attraction, latitude: 13.7563, longitude: 100.5018,
                                   imageURL: "", description: "", rating: "", walkingMinutes: 0,
                                   drivingMinutes: 0, busMinutes: 0, trainMinutes: 0)
}

private enum TripTravelMode: String, CaseIterable, Identifiable {
    case walk, transit, drive
    var id: String { rawValue }
    var title: String {
        switch self {
        case .walk: "Walk"
        case .transit: "Bus"
        case .drive: "Car"
        }
    }
    var symbol: String {
        switch self {
        case .walk: "figure.walk"
        case .transit: "bus.fill"
        case .drive: "car.fill"
        }
    }
    private var routeFactor: Double {
        switch self {
        case .walk: 1.28
        case .transit: 1.42
        case .drive: 1.36
        }
    }
    private var speedKPH: Double {
        switch self {
        case .walk: 4.5
        case .transit: 17
        case .drive: 24
        }
    }
    private var fixedMinutes: Int {
        switch self {
        case .walk: 0
        case .transit: 8
        case .drive: 5
        }
    }
    var tint: Color {
        switch self {
        case .walk: Color(hex: 0xE5A52E)
        case .transit: Color(hex: 0xE875A9)
        case .drive: Color.utopiaBlue
        }
    }
    var transportType: MKDirectionsTransportType {
        switch self {
        case .walk: .walking
        case .transit: .transit
        case .drive: .automobile
        }
    }
    func distanceKm(from: TravelPlace, to: TravelPlace) -> Double {
        let first = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let second = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return max(first.distance(from: second) / 1_000 * routeFactor, 0.2)
    }
    func minutes(from: TravelPlace, to: TravelPlace) -> Int {
        max(Int(ceil(distanceKm(from: from, to: to) / speedKPH * 60)) + fixedMinutes, 2)
    }
}

private struct TripRouteLegView: View {
    let origin: TravelPlace
    let destination: TravelPlace
    var fontScale: CGFloat = 1
    @State private var selectedMode: TripTravelMode = .walk
    @State private var isExpanded = false
    @State private var isMapPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.snappy(duration: 0.22)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: selectedMode.symbol).font(.system(size: 12, weight: .bold))
                        Text("\(selectedMode.title) \(selectedMode.minutes(from: origin, to: destination))m")
                            .font(.system(size: 12 * fontScale, weight: .bold, design: .rounded)).monospacedDigit()
                        Text("· \(selectedMode.distanceKm(from: origin, to: destination), specifier: "%.1f")km")
                            .font(.system(size: 11 * fontScale, weight: .medium, design: .rounded)).monospacedDigit()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down").font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(selectedMode.tint)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(selectedMode.tint.opacity(0.11), in: Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Show travel options")
                Button { isMapPresented = true } label: {
                    Image(systemName: "map.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 36, height: 36).background(Color.utopiaBlue, in: Circle())
                }.buttonStyle(ScaleButtonStyle()).accessibilityLabel("Show route on the in-app map")
            }
            if isExpanded {
                HStack(spacing: 7) {
                    ForEach(TripTravelMode.allCases) { mode in
                        let selected = selectedMode == mode
                        Button {
                            withAnimation(.snappy(duration: 0.2)) { selectedMode = mode }
                        } label: {
                            VStack(spacing: 4) {
                                Label(mode.title, systemImage: mode.symbol).font(.system(size: 10 * fontScale, weight: .bold))
                                Text("\(mode.minutes(from: origin, to: destination))m · \(mode.distanceKm(from: origin, to: destination), specifier: "%.1f")km")
                                    .font(.system(size: 9 * fontScale, weight: .medium, design: .rounded)).monospacedDigit()
                            }
                            .foregroundStyle(mode.tint)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(mode.tint.opacity(selected ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(mode.tint.opacity(selected ? 0.45 : 0.15), lineWidth: 1))
                        }.buttonStyle(ScaleButtonStyle())
                    }
                }.transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $isMapPresented) {
            TripRouteMapSheet(origin: origin, destination: destination, mode: selectedMode)
                .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        }
    }
}

private struct TripRouteMapSheet: View {
    let origin: TravelPlace
    let destination: TravelPlace
    let mode: TripTravelMode
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    @State private var route: MKRoute?
    @State private var liveMinutes: Int?
    @State private var liveDistanceKm: Double?
    @State private var isLoading = true
    @State private var routeUnavailable = false

    init(origin: TravelPlace, destination: TravelPlace, mode: TripTravelMode) {
        self.origin = origin
        self.destination = destination
        self.mode = mode
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (origin.latitude + destination.latitude) / 2,
                                          longitude: (origin.longitude + destination.longitude) / 2),
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04))))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition) {
                Marker(origin.name, coordinate: origin.coordinate).tint(.orange)
                Marker(destination.name, coordinate: destination.coordinate).tint(.blue)
                if let route {
                    MapPolyline(route.polyline).stroke(mode.tint, lineWidth: 6)
                } else {
                    MapPolyline(coordinates: [origin.coordinate, destination.coordinate], contourStyle: .geodesic)
                        .stroke(mode.tint.opacity(0.75), style: StrokeStyle(lineWidth: 4, dash: [8, 6]))
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls { MapCompass(); MapScaleView() }
            .ignoresSafeArea(edges: .top)

            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.utopiaInk).padding(11).background(.regularMaterial, in: Circle())
            }
            .buttonStyle(ScaleButtonStyle()).padding(.top, 16).padding(.trailing, 18)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 8) {
                    Image(systemName: mode.symbol).foregroundStyle(mode.tint)
                    Text("\(origin.name) → \(destination.name)").font(.system(size: 16, weight: .bold, design: .rounded)).lineLimit(1)
                }
                HStack(spacing: 12) {
                    Label("\(liveMinutes ?? mode.minutes(from: origin, to: destination)) min", systemImage: "clock")
                    Label("\(liveDistanceKm ?? mode.distanceKm(from: origin, to: destination), specifier: "%.1f") km", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    if isLoading { ProgressView().controlSize(.small) }
                }.font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
                if routeUnavailable {
                    Text("Showing an approximate route. MapKit could not load directions right now.")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
        }
        .task { await loadRoute() }
    }

    @MainActor private func loadRoute() async {
        let request = MKDirections.Request()
        request.source = mapItem(for: origin)
        request.destination = mapItem(for: destination)
        request.transportType = mode.transportType
        request.departureDate = Date()
        do {
            let directions = MKDirections(request: request)
            if mode == .transit {
                let eta = try await directions.calculateETA()
                liveMinutes = max(Int((eta.expectedTravelTime / 60).rounded()), 1)
                liveDistanceKm = eta.distance / 1_000
            } else {
                let response = try await directions.calculate()
                if let best = response.routes.first {
                    route = best
                    liveMinutes = max(Int((best.expectedTravelTime / 60).rounded()), 1)
                    liveDistanceKm = best.distance / 1_000
                } else { routeUnavailable = true }
            }
        } catch {
            routeUnavailable = true
        }
        isLoading = false
    }

    private func mapItem(for place: TravelPlace) -> MKMapItem {
        let item = MKMapItem(location: CLLocation(latitude: place.latitude, longitude: place.longitude), address: nil)
        item.name = place.name
        return item
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
        guard let tripID = travelStore.currentTrip?.id else { return viewModel.historyItems }
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
                TravelHeader(title: "Money", scale: viewModel.fontScale,
                             isBoldText: viewModel.isBoldText, onSettings: onSettings)
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Label("SPENT THIS TRIP", systemImage: "chart.pie.fill").font(.system(size: 10, weight: .bold)).tracking(0.8).foregroundStyle(.white.opacity(0.75))
                        Spacer()
                        if let trip = travelStore.currentTrip {
                            Text("\(trip.city) · \(trip.days)d").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.88))
                                .padding(.horizontal, 9).padding(.vertical, 6).background(Color.utopiaCard.opacity(0.14), in: Capsule())
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
                            .frame(width: 48, height: 48).background(Color.utopiaBlue, in: RoundedRectangle(cornerRadius: 15))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Start scanning").font(.system(size: 16, weight: .bold)).foregroundStyle(Color.utopiaInk)
                            Text("Check change and convert currency").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.utopiaBlue)
                    }.padding(14).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 19))
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
                            Button("More") { isHistoryPresented = true }.font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.utopiaBlue)
                        }
                    }
                    if let latest = tripHistory.first {
                        LatestHistoryCard(item: latest, viewModel: viewModel) { isHistoryPresented = true }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No scans saved to this trip yet").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.utopiaInk)
                            Text("Your latest price and change checks will appear here.").font(.system(size: 12)).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 17))
                    }
                }
                if travelStore.currentTrip == nil {
                    Button("Create New Trip", action: onCreateTrip)
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.utopiaBlue)
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
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(item.isVerified ? Color.utopiaSuccess : Color.orange)
                    Spacer()
                    Text(item.formattedDate).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                HStack(spacing: 11) {
                    if let product = item.products.first {
                        HistoryImageThumbnail(data: viewModel.historyImageData(for: product)).frame(width: 47, height: 47).clipShape(RoundedRectangle(cornerRadius: 11))
                    } else {
                        Image(systemName: "bag").foregroundStyle(Color.utopiaBlue).frame(width: 47, height: 47).background(Color.utopiaBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
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
            }.padding(14).background(Color.utopiaCard, in: RoundedRectangle(cornerRadius: 18))
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
                    LinearGradient(colors: [Color(hex: 0xEAF3FF), Color(hex: 0xD7E9FA)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: symbol).font(.system(size: 26, weight: .light)).foregroundStyle(Color.utopiaBlue.opacity(0.8))
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
                    Color.utopiaBlue.opacity(0.11)
                    Image(systemName: "bag").font(.system(size: 15)).foregroundStyle(Color.utopiaBlue)
                }
            }
        }.clipped()
    }
}
