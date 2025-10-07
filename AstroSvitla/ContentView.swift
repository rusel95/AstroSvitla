//
//  ContentView.swift
//  AstroSvitla
//
//  Created by Ruslan Popesku on 21.09.2025.
//

import SwiftUI
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)

                Text("AstroSvitla")
                    .font(.title.bold())

                Text("Personalized natal chart insights are coming soon.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Welcome")
        }
    }
}

#Preview {
    ContentView()
}
