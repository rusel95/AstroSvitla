import Foundation
import SwiftData
@testable import AstroSvitla
import Testing

struct UserModelTests {

    @Test
    func testUserInitializationSetsDefaults() throws {
        let user = User()

        #expect(!user.id.uuidString.isEmpty)
        #expect(Calendar.current.compare(user.createdAt, to: Date(), toGranularity: .second) != .orderedDescending)
        #expect(user.lastActiveAt >= user.createdAt)
        #expect(user.charts.isEmpty)
        #expect(user.purchases.isEmpty)
    }

    @Test
    func testUpdateLastActiveAdvancesTimestamp() throws {
        let user = User()
        let original = user.lastActiveAt

        usleep(1_000) // ensure timestamp difference
        user.updateLastActive()

        #expect(user.lastActiveAt >= original)
    }
}
