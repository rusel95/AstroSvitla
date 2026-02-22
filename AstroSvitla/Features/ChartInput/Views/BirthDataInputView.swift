import SwiftUI

struct BirthDataInputView: View {
    @ObservedObject var viewModel: BirthDataInputViewModel
    var onContinue: (BirthDetails) -> Void
    var onCancel: (() -> Void)?

    @FocusState private var focusedField: Field?
    @State private var showLocationSearch = false
    @State private var showDatePicker = false
    @State private var showTimePicker = false

    private enum Field {
        case name
    }

    var body: some View {
        Form {
            Section {
                TextField("birth.field.name_optional", text: $viewModel.name)
                    .focused($focusedField, equals: .name)
            } header: {
                Text("birth.section.person")
            }

            Section {
                // Date row — opens sheet instead of inline expansion
                Button {
                    focusedField = nil
                    showDatePicker = true
                } label: {
                    HStack {
                        Text("birth.field.date")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(viewModel.birthDate, style: .date)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("datePickerRow")

                // Time row — opens sheet instead of inline expansion
                Button {
                    focusedField = nil
                    showTimePicker = true
                } label: {
                    HStack {
                        Text("birth.field.time")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(viewModel.birthTime, style: .time)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("timePickerRow")

                Button {
                    showLocationSearch = true
                } label: {
                    HStack {
                        Text("birth.field.location")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(viewModel.locationDisplay)
                            .foregroundStyle(viewModel.location.isEmpty ? .secondary : .primary)
                            .lineLimit(2)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("locationPickerRow")
            } header: {
                Text("birth.section.details")
            }

            Section {
                Text("birth.help.precision")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if viewModel.hasSavedData {
                Section {
                    Button(role: .destructive) {
                        viewModel.clearData()
                    } label: {
                        Label("birth.action.clear_saved", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(Text("birth.navigation.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if let onCancel {
                    Button("action.back", action: onCancel)
                }
            }
        }
        // Date picker sheet
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                title: String(localized: "birth.field.date"),
                selection: $viewModel.birthDate,
                in: viewModel.dateRange,
                displayedComponents: .date
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        // Time picker sheet
        .sheet(isPresented: $showTimePicker) {
            DatePickerSheet(
                title: String(localized: "birth.field.time"),
                selection: $viewModel.birthTime,
                displayedComponents: .hourAndMinute
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLocationSearch) {
            NavigationStack {
                LocationSearchView(initialQuery: viewModel.location) { suggestion in
                    viewModel.updateLocation(with: suggestion)
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                Button(action: {
                    onContinue(viewModel.makeDetails())
                }) {
                    Text("action.continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isValid == false)
                .accessibilityIdentifier("continueButton")
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - DatePickerSheet

private struct DatePickerSheet: View {
    let title: String
    @Binding var selection: Date
    var range: ClosedRange<Date>? = nil
    let displayedComponents: DatePickerComponents

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        selection: Binding<Date>,
        in range: ClosedRange<Date>? = nil,
        displayedComponents: DatePickerComponents
    ) {
        self.title = title
        self._selection = selection
        self.range = range
        self.displayedComponents = displayedComponents
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("action.done") { dismiss() }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("datePickerDoneButton")
            }
            .padding(.horizontal)
            .padding(.vertical, 16)

            Divider()

            if let range {
                DatePicker(
                    "",
                    selection: $selection,
                    in: range,
                    displayedComponents: displayedComponents
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.horizontal)
            } else {
                DatePicker(
                    "",
                    selection: $selection,
                    displayedComponents: displayedComponents
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.horizontal)
            }

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        BirthDataInputView(
            viewModel: BirthDataInputViewModel(),
            onContinue: { _ in },
            onCancel: {}
        )
    }
}
