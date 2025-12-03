import SwiftUI
import CoreLocation

struct ProfileCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (String, Date, Date, String, CLLocationCoordinate2D, String) -> Void

    @State private var name: String = ""
    @State private var birthDate: Date = Date()
    @State private var birthTime: Date = Date()
    @State private var location: String = ""
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var timezone: String = TimeZone.current.identifier
    @State private var showLocationSearch = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
    }

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 1900, month: 1, day: 1)
        let endComponents = DateComponents(year: 2100, month: 12, day: 31)
        return calendar.date(from: startComponents)!...calendar.date(from: endComponents)!
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.isEmpty &&
        coordinate != nil
    }

    private var locationDisplay: String {
        location.isEmpty ? String(localized: "profile.location.placeholder") : location
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("profile.new.title", bundle: .main)
                            .font(.system(size: 28, weight: .bold))

                        Text("profile.new.description", bundle: .main)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)

                    // Form fields
                    VStack(alignment: .leading, spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("profile.field.name", bundle: .main)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            TextField(String(localized: "profile.name.placeholder"), text: $name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .name)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Birth date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("profile.field.birthdate", bundle: .main)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            DatePicker(
                                "birth.field.date",
                                selection: $birthDate,
                                in: dateRange,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Birth time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("profile.field.birthtime", bundle: .main)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            DatePicker(
                                "birth.field.time",
                                selection: $birthTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("profile.field.location", bundle: .main)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Button {
                                focusedField = nil
                                showLocationSearch = true
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(locationDisplay)
                                            .foregroundStyle(location.isEmpty ? .secondary : .primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()

                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.accentColor)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }

                        // Help text
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.accentColor)

                            Text("profile.help.precision", bundle: .main)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save") {
                        guard isFormValid, let coord = coordinate else { return }
                        onSave(name, birthDate, birthTime, location, coord, timezone)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showLocationSearch) {
                NavigationStack {
                    LocationSearchView(initialQuery: location) { suggestion in
                        // Use displayName to include city, region, country, and ISO code
                        // This ensures the API can properly geocode the location
                        location = suggestion.displayName
                        coordinate = suggestion.coordinate
                        if let timeZone = suggestion.timeZone {
                            timezone = timeZone.identifier
                        }
                        showLocationSearch = false
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("action.close") {
                                showLocationSearch = false
                            }
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text("Main View")
        .sheet(isPresented: .constant(true)) {
            ProfileCreationSheet { name, date, time, location, coordinate, timezone in
                print("Created profile: \(name)")
            }
        }
}
