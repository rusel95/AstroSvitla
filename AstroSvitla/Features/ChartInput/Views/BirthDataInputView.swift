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
            Section("Person") {
                TextField("Name (optional)", text: $viewModel.name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { showLocationSearch = true }
            }

            Section("Birth Details") {
                DatePicker(
                    "Date",
                    selection: $viewModel.birthDate,
                    in: viewModel.dateRange,
                    displayedComponents: .date
                )

                DatePicker(
                    "Time",
                    selection: $viewModel.birthTime,
                    displayedComponents: .hourAndMinute
                )

                Button {
                    showLocationSearch = true
                } label: {
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(viewModel.locationDisplay)
                            .foregroundStyle(viewModel.location.isEmpty ? .secondary : .primary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                    }
                }
            }

            if viewModel.isValid == false {
                Section {
                    Label("Enter birth location to continue.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Birth Details")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if let onCancel {
                    Button("Back", action: onCancel)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    onContinue(viewModel.makeDetails())
                }
                .disabled(viewModel.isValid == false)
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
                        Button("Close") {
                            showLocationSearch = false
                        }
                    }
                }
            }
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
