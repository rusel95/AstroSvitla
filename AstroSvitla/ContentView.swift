import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @State private var showOnboarding = false

    enum Tab: Hashable {
        case main
        case reports
        case settings
    }

    @State private var selectedTab: Tab = .main

    var body: some View {
        TabView(selection: $selectedTab) {
            MainFlowView(modelContext: modelContext)
                .tabItem {
                    Label {
                        Text("tab.main")
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                }
                .tag(Tab.main)

            NavigationStack {
                ReportListView()
            }
            .tabItem {
                Label {
                    Text("tab.reports")
                } icon: {
                    Image(systemName: "doc.richtext")
                }
            }
            .tag(Tab.reports)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label {
                    Text("tab.settings")
                } icon: {
                    Image(systemName: "gearshape")
                }
            }
            .tag(Tab.settings)
        }
        .onAppear {
            // Show onboarding modally if not completed
            if !onboardingViewModel.isCompleted {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(
                viewModel: onboardingViewModel,
                onFinish: {
                    showOnboarding = false
                }
            )
        }
    }
}

#Preview {
    ContentView()
}
