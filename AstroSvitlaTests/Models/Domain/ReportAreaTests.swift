import Foundation
@testable import AstroSvitla
import Testing

struct ReportAreaTests {

    @Test
    func testIcons() {
        #expect(ReportArea.finances.icon == "dollarsign.circle.fill")
        #expect(ReportArea.career.icon == "briefcase.fill")
    }

    @Test
    func testDisplayNamesAreNotEmpty() {
        for area in ReportArea.allCases {
            #expect(!area.displayName.isEmpty)
        }
    }
}
