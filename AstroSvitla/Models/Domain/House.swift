import Foundation

struct House: Codable, Identifiable, Sendable {
    let id: UUID
    let number: Int
    let cusp: Double
    let sign: ZodiacSign

    init(
        id: UUID = UUID(),
        number: Int,
        cusp: Double,
        sign: ZodiacSign
    ) {
        self.id = id
        self.number = number
        self.cusp = cusp
        self.sign = sign
    }
}
