import SwiftUI
import CoreLocation

struct ChartDetailsView: View {
    let chart: NatalChart
    let birthDetails: BirthDetails

    var body: some View {
        List {
            // Chart Wheel Visualization
            Section {
                NatalChartWheelView(chart: chart)
                    .listRowInsets(EdgeInsets())
            }

            // Birth Info Section
            Section("chart.section.birth_data") {
                LabeledContent("chart.name", value: birthDetails.displayName)
                LabeledContent("chart.date", value: birthDetails.formattedBirthDate)
                LabeledContent("chart.time", value: birthDetails.formattedBirthTime)
                LabeledContent("chart.location", value: birthDetails.location)
                LabeledContent("chart.coordinates") {
                    if let coord = birthDetails.coordinate {
                        Text("\(coord.latitude, specifier: "%.4f")°, \(coord.longitude, specifier: "%.4f")°")
                            .font(.caption.monospaced())
                    }
                }
                LabeledContent("chart.timezone", value: birthDetails.timeZone.identifier)
            }

            // Ascendant & Midheaven
            Section("chart.section.angles") {
                LabeledContent("chart.ascendant") {
                    VStack(alignment: .trailing) {
                        Text(formatDegree(chart.ascendant))
                            .font(.caption.monospaced())
                        Text(ZodiacSign.from(degree: chart.ascendant).rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("chart.midheaven") {
                    VStack(alignment: .trailing) {
                        Text(formatDegree(chart.midheaven))
                            .font(.caption.monospaced())
                        Text(ZodiacSign.from(degree: chart.midheaven).rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Planets
            Section {
                ForEach(chart.planets) { planet in
                    LabeledContent {
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(formatDegree(planet.longitude))
                                    .font(.caption.monospaced())
                                if planet.isRetrograde {
                                    Text("℞")
                                        .foregroundStyle(.orange)
                                }
                            }
                            Text(String(localized: "chart.planet.position \(planet.sign.rawValue) \(planet.house)"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(localized: "chart.planet.speed \(String(format: "%.4f", planet.speed))"))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    } label: {
                        HStack {
                            Text(planet.name.rawValue)
                                .fontWeight(.medium)
                            if planet.isRetrograde {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            } header: {
                Text("chart.section.planets \(chart.planets.count)")
            }

            // Houses
            Section {
                ForEach(chart.houses.sorted(by: { $0.number < $1.number })) { house in
                    LabeledContent(String(localized: "chart.house \(house.number)")) {
                        VStack(alignment: .trailing) {
                            Text(formatDegree(house.cusp))
                                .font(.caption.monospaced())
                            Text(house.sign.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("chart.section.houses \(chart.houses.count)")
            }

            // Aspects
            Section {
                ForEach(chart.aspects) { aspect in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(aspect.planet1.rawValue)")
                                .fontWeight(.medium)
                            Text(aspectSymbol(aspect.type))
                                .foregroundStyle(aspectColor(aspect.type))
                                .font(.title3)
                            Text("\(aspect.planet2.rawValue)")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text(aspect.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(localized: "chart.aspect.orb \(String(format: "%.2f", aspect.orb))"))
                                .font(.caption.monospaced())
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("chart.section.aspects \(chart.aspects.count)")
            }

            // Calculation Metadata
            Section("chart.section.metadata") {
                LabeledContent("chart.calculation_date", value: chart.calculatedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle("chart.details.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func formatDegree(_ degree: Double) -> String {
        let normalized = degree.truncatingRemainder(dividingBy: 360)
        let degrees = Int(normalized)
        let minutes = Int((normalized - Double(degrees)) * 60)
        let seconds = Int(((normalized - Double(degrees)) * 60 - Double(minutes)) * 60)
        return "\(degrees)°\(minutes)'\(seconds)\""
    }

    private func aspectSymbol(_ type: AspectType) -> String {
        switch type {
        case .conjunction: return "☌"
        case .opposition: return "☍"
        case .trine: return "△"
        case .square: return "□"
        case .sextile: return "⚹"
        case .quincunx: return "⚻"
        case .semisextile: return "⚺"
        case .semisquare: return "∠"
        case .sesquisquare: return "⚼"
        case .quintile: return "Q"
        case .biquintile: return "bQ"
        }
    }

    private func aspectColor(_ type: AspectType) -> Color {
        switch type {
        case .conjunction: return .blue
        case .opposition: return .red
        case .trine: return .green
        case .square: return .orange
        case .sextile: return .purple
        case .quincunx: return .brown
        case .semisextile: return .cyan
        case .semisquare: return .pink
        case .sesquisquare: return .indigo
        case .quintile: return .mint
        case .biquintile: return .teal
        }
    }
}

#Preview {
    NavigationStack {
        ChartDetailsView(
            chart: NatalChart(
                birthDate: Date(),
                birthTime: Date(),
                latitude: 50.4501,
                longitude: 30.5234,
                locationName: "Kyiv",
                planets: [],
                houses: [],
                aspects: [],
                houseRulers: [],
                ascendant: 127.5,
                midheaven: 215.3,
                calculatedAt: Date()
            ),
            birthDetails: BirthDetails(
                name: "Test User",
                birthDate: Date(),
                birthTime: Date(),
                location: "Kyiv, Ukraine"
            )
        )
    }
}
