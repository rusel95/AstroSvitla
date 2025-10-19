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
                TextField("birth.field.name_optional", text: $viewModel.name)
                    .focused($focusedField, equals: .name)
            } header: {
                Text("Персона")
            }

            Section {
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
            } header: {
                Text("Деталі")
            }

            Section {
                Text("Точніший час дає кращі результати")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if viewModel.hasSavedData {
                Section {
                    Button(role: .destructive) {
                        viewModel.clearData()
                    } label: {
                        Label("Видалити збережені дані", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(Text("Дані народження"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if let onCancel {
                    Button("Назад", action: onCancel)
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
                        Button("Закрити") {
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
                    Text("Продовжити")
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
