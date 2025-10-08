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
            Section("Демо-режим") {
                Text("Наразі використовуються попередньо заповнені дані народження, поки ми готуємо інтеграцію з векторною базою знань.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Особа") {
                TextField("Ім'я (необов'язково)", text: $viewModel.name)
                    .disabled(true)
            }

            Section("Дані народження") {
                DatePicker("Дата", selection: $viewModel.birthDate, in: viewModel.dateRange, displayedComponents: .date)
                    .disabled(true)
                DatePicker("Час", selection: $viewModel.birthTime, displayedComponents: .hourAndMinute)
                    .disabled(true)
                HStack {
                    Text("Місце")
                    Spacer()
                    Text(viewModel.locationDisplay)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
            }
        }
        .navigationTitle("Дані народження")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if let onCancel {
                    Button("Назад", action: onCancel)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Продовжити") {
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
                        Button("Закрити") {
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
