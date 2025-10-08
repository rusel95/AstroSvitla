import Foundation
@testable import AstroSvitla
import Testing

struct ReportAreaTests {

    @Test
    func testDisplayNames() {
        let financesName = String(localized: "report.area.finances", table: "Localizable")
        let generalName = String(localized: "report.area.general", table: "Localizable")

        #expect(ReportArea.finances.displayName == financesName)
        #expect(ReportArea.general.displayName == generalName)
    }

    @Test
    func testPrices() {
        let generalPrice = Decimal(string: "9.99")!
        let healthPrice = Decimal(string: "5.99")!

        #expect(ReportArea.general.price == generalPrice)
        #expect(ReportArea.health.price == healthPrice)
    }

    @Test
    func testIcons() {
        #expect(ReportArea.finances.icon == "dollarsign.circle.fill")
        #expect(ReportArea.career.icon == "briefcase.fill")
    }

    @Test
    func testProductIdentifiers() {
        #expect(ReportArea.finances.productIdentifier == Config.ProductID.financesReport)
        #expect(ReportArea.general.productIdentifier == Config.ProductID.generalReport)
    }
}
