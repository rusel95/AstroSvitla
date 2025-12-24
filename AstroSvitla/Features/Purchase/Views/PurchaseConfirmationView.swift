import SwiftUI
import SwiftData

struct PurchaseConfirmationView: View {
    let birthDetails: BirthDetails
    let area: ReportArea
    var purchaseService: PurchaseService?
    var hasCredit: Bool
    var onBack: (() -> Void)?
    var onGenerateReport: () -> Void
    var onPurchase: () -> Void

    var body: some View {
        ZStack {
            // Premium background
            CosmicBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Summary card with glass effect
                    summaryCard

                    // Features list
                    featuresSection

                    // Action button
                    if hasCredit {
                        // User has credit - show generate button
                        Button(action: onGenerateReport) {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                Text(String(format: String(localized: "purchase.action.create %@"), area.displayName))
                            }
                        }
                        .buttonStyle(.astroPrimary)
                        .padding(.top, 8)
                    } else {
                        // No credit - show purchase button
                        Button(action: onPurchase) {
                            HStack(spacing: 10) {
                                if let service = purchaseService, service.isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(String(format: String(localized: "purchase.paywall.buy_button", defaultValue: "Buy for %@"), priceString))
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                        }
                        .buttonStyle(.astroPrimary)
                        .padding(.top, 8)
                        .disabled(purchaseService?.isPurchasing ?? false)
                        
                        // Restore button
                        Button {
                            Task {
                                do {
                                    try await purchaseService?.restorePurchases()
                                } catch {
                                    // Error handling is done by PurchaseService breadcrumbs
                                    // User will see success/failure through credit balance update
                                }
                            }
                        } label: {
                            Text(String(localized: "purchase.action.restore", defaultValue: "Restore Purchases"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.accentColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, -10)
                    }

                    // Guarantee text
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.astroSuccess)

                        Text("purchase.guarantee", bundle: .main)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle(Text("purchase.title", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if let onBack {
                    Button {
                        onBack()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("action.back", bundle: .main)
                        }
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Area header with icon
            HStack(spacing: 16) {
                // Premium icon container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Circle()
                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 64, height: 64)

                    Image(systemName: area.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(area.displayName)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    // Only show price if user doesn't have credit
                    if !hasCredit {
                        HStack(spacing: 4) {
                            Text(priceString)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.accentColor)

                            Text("purchase.price.once", bundle: .main)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()
            }

            // Divider with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.15), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Birth details
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                        .frame(width: 20)

                    Text(birthDetails.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    Text(String(localized: "purchase.datetime") + " \(birthDetails.formattedBirthDate) \(birthDetails.formattedBirthTime)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    Text(birthDetails.formattedLocation)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .glassCard(cornerRadius: 22, padding: 22, intensity: .regular)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("purchase.features.title", bundle: .main)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            VStack(spacing: 14) {
                FeatureRow(
                    icon: "books.vertical.fill",
                    title: String(localized: "purchase.feature.literature.title"),
                    subtitle: String(localized: "purchase.feature.literature.subtitle")
                )

                FeatureRow(
                    icon: "doc.text.fill",
                    title: String(localized: "purchase.feature.report.title"),
                    subtitle: String(localized: "purchase.feature.report.subtitle")
                )

                FeatureRow(
                    icon: "arrow.down.doc.fill",
                    title: String(localized: "purchase.feature.pdf.title"),
                    subtitle: String(localized: "purchase.feature.pdf.subtitle")
                )

                FeatureRow(
                    icon: "infinity",
                    title: String(localized: "purchase.feature.access.title"),
                    subtitle: String(localized: "purchase.feature.access.subtitle")
                )
            }
        }
        .glassCard(cornerRadius: 18, padding: 18, intensity: .subtle)
    }

    private var priceString: String {
        if let service = purchaseService {
            return service.getProductPrice()
        }
        // Fallback if service not provided
        return String(localized: "purchase.price.unavailable", defaultValue: "Payment Unavailable")
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    // Create a mock service with test context for preview
    let mockContext = try! ModelContainer(
        for: PurchaseCredit.self, PurchaseRecord.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ).mainContext
    let mockService = PurchaseService(context: mockContext)
    
    NavigationStack {
        PurchaseConfirmationView(
            birthDetails: BirthDetails(
                name: "Alex",
                birthDate: .now,
                birthTime: .now,
                location: "Kyiv, Ukraine"
            ),
            area: .career,
            purchaseService: mockService,
            hasCredit: true,
            onBack: {},
            onGenerateReport: {},
            onPurchase: {}
        )
    }
}
