import SwiftUI

struct AreaSelectionView: View {
    let birthDetails: BirthDetails
    let natalChart: NatalChart
    let purchasedAreas: Set<ReportArea>
    var onAreaSelected: (ReportArea) -> Void
    var onViewExistingReport: ((ReportArea) -> Void)? = nil

    @State private var showChartDetails = false

    init(
        birthDetails: BirthDetails,
        natalChart: NatalChart,
        purchasedAreas: Set<ReportArea> = [],
        onAreaSelected: @escaping (ReportArea) -> Void,
        onViewExistingReport: ((ReportArea) -> Void)? = nil
    ) {
        self.birthDetails = birthDetails
        self.natalChart = natalChart
        self.purchasedAreas = purchasedAreas
        self.onAreaSelected = onAreaSelected
        self.onViewExistingReport = onViewExistingReport
    }

    var body: some View {
        ZStack {
            // Premium background
            CosmicBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Birth details glass card
                    VStack(alignment: .leading, spacing: 16) {
                        // Header with icon
                        HStack(spacing: 12) {
                            AstroIconContainer(systemName: "person.circle", size: .medium, style: .glass)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(birthDetails.displayName)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)

                                Text("\(birthDetails.formattedBirthDate) • \(birthDetails.formattedBirthTime)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Location row
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.accentColor.opacity(0.8))

                            Text(birthDetails.formattedLocation)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                        }

                        // View chart button
                        Button {
                            showChartDetails = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.pie.fill")
                                    .font(.system(size: 14, weight: .medium))

                                Text("Переглянути натальну карту")
                                    .font(.system(size: 14, weight: .semibold))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .glassCard(cornerRadius: 20, padding: 18, intensity: .regular)

                    // Section header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Оберіть сферу аналізу")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Виберіть область життя для детального астрологічного звіту")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Area cards
                    VStack(spacing: 12) {
                        ForEach(ReportArea.allCases, id: \.self) { area in
                            let isPurchased = purchasedAreas.contains(area)
                            
                            Button {
                                if isPurchased {
                                    // View existing report
                                    onViewExistingReport?(area)
                                } else {
                                    // Go to purchase flow
                                    onAreaSelected(area)
                                }
                            } label: {
                                AreaCard(area: area, isPurchased: isPurchased)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle(Text("Вибір сфери"))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showChartDetails) {
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
                houseRulers: [],
                ascendant: 127.5,
                midheaven: 215.3,
                calculatedAt: .now
            ),
            purchasedAreas: [.relationships, .health],
            onAreaSelected: { _ in },
            onViewExistingReport: { _ in }
        )
    }
}
