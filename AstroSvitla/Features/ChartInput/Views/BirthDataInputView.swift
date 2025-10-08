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
            Section("Особа") {
                TextField("Ім'я (необов'язково)", text: $viewModel.name)
                    .focused($focusedField, equals: .name)
            }

            Section("Дані народження") {
                DatePicker("Дата", selection: $viewModel.birthDate, in: viewModel.dateRange, displayedComponents: .date)
                DatePicker("Час", selection: $viewModel.birthTime, displayedComponents: .hourAndMinute)
                Button {
                    showLocationSearch = true
                } label: {
                    HStack {
                        Text("Місце")
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
            }

            Section {
                Text("Введіть точні дані народження для розрахунку натальної карти. Час має бути максимально точним для коректного визначення будинків.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if viewModel.hasSavedData {
                Section {
                    Button(role: .destructive) {
                        viewModel.clearData()
                    } label: {
                        Label("Очистити збережені дані", systemImage: "trash")
                    }
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
