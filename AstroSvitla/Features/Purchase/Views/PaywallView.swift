//  PaywallView.swift
//  AstroSvitla
//
//  Created on 2025-12-23
//  Feature: 008-implement-in-app

import SwiftUI
import SwiftData
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PaywallViewModel
    
    init(purchaseService: PurchaseService, reportArea: String, onPurchaseComplete: ((String) -> Void)? = nil) {
        self._viewModel = State(initialValue: PaywallViewModel(
            purchaseService: purchaseService,
            reportArea: reportArea
        ))
        self.viewModel.onPurchaseComplete = onPurchaseComplete
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium background
                CosmicBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.yellow.opacity(0.1))
                                )
                            
                            Text("Unlock Report")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            Text("Get detailed AI-powered insights for this area of your life")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Product Card
                        if let product = viewModel.product {
                            productCard(for: product)
                        } else {
                            ProgressView()
                                .controlSize(.large)
                                .padding()
                        }
                        
                        // Features list
                        featuresSection
                        
                        Spacer(minLength: 20)
                        
                        // Actions
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadProduct()
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.error != nil },
                    set: { if !$0 { viewModel.error = nil } }
                )
            ) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.errorDescription ?? "An error occurred")
                }
            }
            .onChange(of: viewModel.purchaseCompleted) { _, completed in
                if completed {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Product Card
    
    private func productCard(for product: Product) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(product.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack {
                    Text(product.displayPrice)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach([
                ("sparkles", "AI-Powered Analysis", "Deep insights powered by advanced AI"),
                ("star", "Personalized Content", "Tailored specifically to your birth chart"),
                ("clock", "Instant Generation", "Get your report in seconds"),
                ("infinity", "Unlimited Access", "Read your report as many times as you want")
            ], id: \.0) { icon, title, description in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(description)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Purchase button
            Button {
                Task {
                    await viewModel.purchase()
                }
            } label: {
                HStack {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        if let product = viewModel.product {
                            Text(String(format: String(localized: "purchase.paywall.buy_button"), product.displayPrice))
                                .font(.system(size: 17, weight: .semibold))
                        } else {
                            Text("Purchase")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor)
                )
                .foregroundColor(.white)
            }
            .disabled(viewModel.isPurchasing || viewModel.product == nil)
            
            // Restore button
            Button {
                Task {
                    await viewModel.restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(viewModel.isPurchasing)
        }
    }
}

#Preview {
    PaywallView(
        purchaseService: PurchaseService(context: ModelContext(
            try! ModelContainer(for: PurchaseCredit.self, PurchaseRecord.self)
        )),
        reportArea: "personality"
    )
}
