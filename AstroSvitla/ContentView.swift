import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var repositoryContext: RepositoryContext
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
            MainFlowView(modelContext: modelContext, repositoryContext: repositoryContext)
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
    let container = try! ModelContainer.astroSvitlaShared(inMemory: true)
    ContentView()
        .environment(\.modelContext, container.mainContext)
        .environmentObject(AppPreferences())
        .environmentObject(RepositoryContext(context: container.mainContext))
}
