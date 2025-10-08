import SwiftUI

struct AreaSelectionView: View {
    let birthDetails: BirthDetails
    var onAreaSelected: (ReportArea) -> Void
    var onEditDetails: (() -> Void)?

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
            onAreaSelected: { _ in },
            onEditDetails: {}
        )
    }
}
