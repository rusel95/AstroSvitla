import SwiftUI

struct BirthDataInputView: View {
    @ObservedObject var viewModel: BirthDataInputViewModel
    var onContinue: (BirthDetails) -> Void
    var onCancel: (() -> Void)?

    @FocusState private var focusedField: Field?
    @State private var showLocationSearch = false

    private enum Field {
        case name
    }

    var body: some View {
        Form {
            Section {
                TextField(String(localized: "birth.field.name_optional", table: "Localizable"), text: $viewModel.name)
                    .focused($focusedField, equals: .name)
            } header: {
                Text("birth.section.person", tableName: "Localizable")
            }

            Section {
                DatePicker(String(localized: "birth.field.date", table: "Localizable"), selection: $viewModel.birthDate, in: viewModel.dateRange, displayedComponents: .date)
                DatePicker(String(localized: "birth.field.time", table: "Localizable"), selection: $viewModel.birthTime, displayedComponents: .hourAndMinute)
                Button {
                    showLocationSearch = true
                } label: {
                    HStack {
                        Text("birth.field.location", tableName: "Localizable")
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
            } header: {
                Text("birth.section.details", tableName: "Localizable")
            }

            Section {
                Text("birth.help.precision", tableName: "Localizable")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if viewModel.hasSavedData {
                Section {
                    Button(role: .destructive) {
                        viewModel.clearData()
                    } label: {
                        Label(String(localized: "birth.action.clear_saved", table: "Localizable"), systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(Text("birth.navigation.title", tableName: "Localizable"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if let onCancel {
                    Button(String(localized: "action.back", table: "Localizable"), action: onCancel)
                }
            }
        }
        .sheet(isPresented: $showLocationSearch) {
            NavigationStack {
                LocationSearchView(initialQuery: viewModel.location) { suggestion in
                    viewModel.updateLocation(with: suggestion)
                    showLocationSearch = false
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "action.close", table: "Localizable")) {
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
                    Text("action.continue", tableName: "Localizable")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isValid == false)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
            .background(.ultraThinMaterial)
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
