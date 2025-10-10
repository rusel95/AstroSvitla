//
//  ProkralaDTOTests.swift
//  AstroSvitlaTests
//
//  Updated tests for Prokerala compute DTOs.
//

import Testing
import Foundation
@testable import AstroSvitla

@Suite("Prokerala DTO Decoding")
struct ProkralaDTOTests {

    @Test("Status decodes from success string")
    func testStatusStringDecoding() throws {
        let data = "\"success\"".data(using: .utf8)!
        let status = try JSONDecoder().decode(ProkralaChartDataResponse.Status.self, from: data)

        #expect(status.isSuccess)
        #expect(status.description == "success")
    }

    @Test("Status decodes from boolean true")
    func testStatusBoolDecoding() throws {
        let data = "true".data(using: .utf8)!
        let status = try JSONDecoder().decode(ProkralaChartDataResponse.Status.self, from: data)

        #expect(status.isSuccess)
        #expect(status.description == "true")
    }

    @Test("Chart data response decodes snake_case payload")
    func testChartDataResponseDecoding() throws {
        let json = """
        {
          "status": "success",
          "message": "ok",
          "data": {
            "houses": [
              {
                "id": 1,
                "number": 1,
                "start_cusp": {
                  "longitude": 10.0,
                  "degree": 10.0,
                  "zodiac": { "id": 1, "name": "Aries" }
                },
                "end_cusp": {
                  "longitude": 40.0,
                  "degree": 10.0,
                  "zodiac": { "id": 2, "name": "Taurus" }
                }
              }
            ],
            "planet_positions": [
              {
                "id": 1,
                "name": "Sun",
                "longitude": 120.5,
                "degree": 0.5,
                "is_retrograde": false,
                "house_number": 5,
                "zodiac": { "id": 5, "name": "Leo" }
              },
              {
                "id": 2,
                "name": "Moon",
                "longitude": 60.25,
                "degree": 0.25,
                "is_retrograde": true,
                "house_number": 2,
                "zodiac": { "id": 2, "name": "Taurus" }
              }
            ],
            "angles": [
              {
                "id": 101,
                "name": "Ascendant",
                "longitude": 10.0,
                "degree": 10.0,
                "is_retrograde": false,
                "house_number": 1,
                "zodiac": { "id": 1, "name": "Aries" }
              },
              {
                "id": 102,
                "name": "Midheaven",
                "longitude": 190.0,
                "degree": 10.0,
                "is_retrograde": false,
                "house_number": 10,
                "zodiac": { "id": 10, "name": "Capricorn" }
              }
            ],
            "aspects": [
              {
                "planet_one": { "id": 1, "name": "Sun" },
                "planet_two": { "id": 2, "name": "Moon" },
                "aspect": { "id": 1, "name": "Trine" },
                "orb": 2.1
              }
            ],
            "declinations": []
          }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ProkralaChartDataResponse.self, from: data)

        #expect(response.status.isSuccess)
        #expect(response.message == "ok")
        #expect(response.data.houses.count == 1)
        #expect(response.data.planetPositions.count == 2)
        #expect(response.data.angles.count == 2)
        #expect(response.data.aspects.count == 1)
        #expect(response.data.declinations?.isEmpty == true)
    }
}
