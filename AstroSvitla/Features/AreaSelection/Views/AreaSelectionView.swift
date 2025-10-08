import SwiftUI

struct AreaSelectionView: View {
    let birthDetails: BirthDetails
    let natalChart: NatalChart
    var onAreaSelected: (ReportArea) -> Void
    var onEditDetails: (() -> Void)?

    @State private var showChartDetails = false

    var body: some View {
        List {
            Section("Дані про народження") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(birthDetails.displayName)
                        .font(.headline)

                    Text("\(birthDetails.formattedBirthDate) • \(birthDetails.formattedBirthTime)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(birthDetails.formattedLocation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showChartDetails = true
                } label: {
                    Label("Переглянути деталі карти", systemImage: "chart.bar.doc.horizontal")
                }
            }

            Section("Оберіть сферу життя") {
                ForEach(ReportArea.allCases, id: \.self) { area in
                    Button {
                        onAreaSelected(area)
                    } label: {
                        AreaCard(area: area)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Оберіть сферу")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let onEditDetails {
                    Button("Змінити дані", action: onEditDetails)
                }
            }
        }
        .sheet(isPresented: $showChartDetails) {
            NavigationStack {
                ChartDetailsView(chart: natalChart, birthDetails: birthDetails)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Готово") {
                                showChartDetails = false
                            }
                        }
                    }
            }
        }
    }

}

#Preview {
    NavigationStack {
        AreaSelectionView(
            birthDetails: BirthDetails(
                name: "Alex",
                birthDate: .now,
                birthTime: .now,
                location: "Kyiv, Ukraine"
            ),
            natalChart: NatalChart(
                birthDate: .now,
                birthTime: .now,
                latitude: 50.4501,
                longitude: 30.5234,
                locationName: "Kyiv",
                planets: [],
                houses: [],
                aspects: [],
                ascendant: 127.5,
                midheaven: 215.3,
                calculatedAt: .now
            ),
            onAreaSelected: { _ in },
            onEditDetails: {}
        )
    }
}
