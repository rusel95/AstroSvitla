import SwiftUI

struct AreaSelectionView: View {
    let birthDetails: BirthDetails
    let natalChart: NatalChart
    var onAreaSelected: (ReportArea) -> Void
    var onEditDetails: (() -> Void)?

    @State private var showChartDetails = false

    var body: some View {
        List {
            Section {
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
                    Label(String(localized: "area.action.view_details", table: "Localizable"), systemImage: "chart.bar.doc.horizontal")
                }
            } header: {
                Text("area.section.birth_details", tableName: "Localizable")
            }

            Section {
                ForEach(ReportArea.allCases, id: \.self) { area in
                    Button {
                        onAreaSelected(area)
                    } label: {
                        AreaCard(area: area)
                    }
                }
            } header: {
                Text("area.section.choose", tableName: "Localizable")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Text("area.navigation.title", tableName: "Localizable"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let onEditDetails {
                    Button(String(localized: "area.action.edit_details", table: "Localizable"), action: onEditDetails)
                }
            }
        }
        .sheet(isPresented: $showChartDetails) {
            NavigationStack {
                ChartDetailsView(chart: natalChart, birthDetails: birthDetails)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "action.done", table: "Localizable")) {
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
