import SwiftUI

struct ContentView: View {
    enum Tab: Hashable {
        case main
        case reports
        case settings
    }

    @State private var selectedTab: Tab = .main

    var body: some View {
        TabView(selection: $selectedTab) {
            MainFlowView()
                .tabItem {
                    Label {
                        Text("tab.main", tableName: "Localizable")
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
                    Text("tab.reports", tableName: "Localizable")
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
                    Text("tab.settings", tableName: "Localizable")
                } icon: {
                    Image(systemName: "gearshape")
                }
            }
            .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
}
