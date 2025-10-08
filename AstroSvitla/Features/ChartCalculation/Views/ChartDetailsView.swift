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
                    .frame(height: 350)
                    .listRowInsets(EdgeInsets())
            }

            // Birth Info Section
            Section("Дані народження") {
                LabeledContent("Ім'я", value: birthDetails.displayName)
                LabeledContent("Дата", value: birthDetails.formattedBirthDate)
                LabeledContent("Час", value: birthDetails.formattedBirthTime)
                LabeledContent("Місце", value: birthDetails.location)
                LabeledContent("Координати") {
                    if let coord = birthDetails.coordinate {
                        Text("\(coord.latitude, specifier: "%.4f")°, \(coord.longitude, specifier: "%.4f")°")
                            .font(.caption.monospaced())
                    }
                }
                LabeledContent("Часовий пояс", value: birthDetails.timeZone.identifier)
            }

            // Ascendant & Midheaven
            Section("Кути карти") {
                LabeledContent("Асцендент (ASC)") {
                    VStack(alignment: .trailing) {
                        Text(formatDegree(chart.ascendant))
                            .font(.caption.monospaced())
                        Text(ZodiacSign.from(degree: chart.ascendant).rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Середина неба (MC)") {
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
            Section("Планети (\(chart.planets.count))") {
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
                            Text("\(planet.sign.rawValue), дім \(planet.house)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Швидкість: \(planet.speed, specifier: "%.4f")°/день")
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
            }

            // Houses
            Section("Будинки (\(chart.houses.count))") {
                ForEach(chart.houses.sorted(by: { $0.number < $1.number })) { house in
                    LabeledContent("Дім \(house.number)") {
                        VStack(alignment: .trailing) {
                            Text(formatDegree(house.cusp))
                                .font(.caption.monospaced())
                            Text(house.sign.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Aspects
            Section("Аспекти (\(chart.aspects.count))") {
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
                            Text("Орб: \(aspect.orb, specifier: "%.2f")°")
                                .font(.caption.monospaced())
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Calculation Metadata
            Section("Метадані") {
                LabeledContent("Дата розрахунку", value: chart.calculatedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle("Деталі карти")
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
        }
    }

    private func aspectColor(_ type: AspectType) -> Color {
        switch type {
        case .conjunction: return .blue
        case .opposition: return .red
        case .trine: return .green
        case .square: return .orange
        case .sextile: return .purple
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
