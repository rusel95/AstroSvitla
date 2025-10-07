import Foundation
import SwiftData
@testable import AstroSvitla
import Testing

struct ReportPurchaseModelTests {

    @Test
    func testReportPurchaseInitializationSetsDefaults() throws {
        let report = ReportPurchase(
            area: ReportArea.finances.rawValue,
            reportText: "Sample content",
            language: "en",
            price: Decimal(string: "6.99")!,
            currency: "USD",
            transactionId: "txn_123"
        )

        #expect(report.area == ReportArea.finances.rawValue)
        #expect(report.reportText == "Sample content")
        #expect(report.language == "en")
        #expect(report.price == Decimal(string: "6.99")!)
        #expect(report.wordCount == 2)
        #expect(report.areaDisplayName == "Finances")
        #expect(report.estimatedReadingTime == 1)
    }

    @Test
    func testReportPurchaseIsForAreaHelper() throws {
        let report = ReportPurchase(
            area: ReportArea.health.rawValue,
            reportText: "Health insights",
            language: "en",
            price: Decimal(string: "5.99")!,
            transactionId: "txn_456"
        )

        #expect(report.isForArea(.health))
        #expect(report.isForArea(.career) == false)
    }
}
