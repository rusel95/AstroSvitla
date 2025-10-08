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
            Section("Demo Mode") {
                Text("Currently using pre-filled birth details while the vector store integration is prepared.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Person") {
                TextField("Name (optional)", text: $viewModel.name)
                    .disabled(true)
            }

            Section("Birth Details") {
                DatePicker("Date", selection: $viewModel.birthDate, in: viewModel.dateRange, displayedComponents: .date)
                    .disabled(true)
                DatePicker("Time", selection: $viewModel.birthTime, displayedComponents: .hourAndMinute)
                    .disabled(true)
                HStack {
                    Text("Location")
                    Spacer()
                    Text(viewModel.locationDisplay)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
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
