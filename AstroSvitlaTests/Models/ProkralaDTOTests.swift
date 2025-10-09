//
//  ProkralaDTOTests.swift
//  AstroSvitlaTests
//
//  Created for Prokerala API Integration
//  Test-First: These tests should FAIL before DTO implementation
//

import Testing
@testable import AstroSvitla

struct ProkralaDTOTests {

    // MARK: - PlanetDTO Tests

    @Test("PlanetDTO should parse valid JSON")
    func testPlanetDTOValidParsing() throws {
        let json = """
        {
            "name": "Sun",
            "sign": "Aries",
            "full_degree": 15.5,
            "is_retro": "false"
        }
        """

        let data = json.data(using: .utf8)!
        let planet = try JSONDecoder().decode(PlanetDTO.self, from: data)

        #expect(planet.name == "Sun")
        #expect(planet.sign == "Aries")
        #expect(planet.full_degree == 15.5)
        #expect(planet.is_retro == "false")
    }

    @Test("PlanetDTO should handle retrograde true")
    func testPlanetDTORetrogradeParsing() throws {
        let json = """
        {
            "name": "Mercury",
            "sign": "Virgo",
            "full_degree": 165.25,
            "is_retro": "true"
        }
        """

        let data = json.data(using: .utf8)!
        let planet = try JSONDecoder().decode(PlanetDTO.self, from: data)

        #expect(planet.name == "Mercury")
        #expect(planet.is_retro == "true")
    }

    @Test("PlanetDTO should validate degree range")
    func testPlanetDTODegreeRange() throws {
        // Valid: 0-360
        let validJSON = """
        {
            "name": "Mars",
            "sign": "Leo",
            "full_degree": 359.99,
            "is_retro": "false"
        }
        """

        let data = validJSON.data(using: .utf8)!
        let planet = try JSONDecoder().decode(PlanetDTO.self, from: data)

        #expect(planet.full_degree >= 0 && planet.full_degree < 360)
    }

    @Test("PlanetDTO should fail with missing fields")
    func testPlanetDTOMissingFields() throws {
        let json = """
        {
            "name": "Venus",
            "sign": "Taurus"
        }
        """

        let data = json.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(PlanetDTO.self, from: data)
        }
    }

    // MARK: - HouseDTO Tests

    @Test("HouseDTO should parse valid JSON")
    func testHouseDTOValidParsing() throws {
        let json = """
        {
            "house_id": 1,
            "sign": "Leo",
            "start_degree": 135.28,
            "end_degree": 165.58,
            "planets": ["Moon", "Jupiter"]
        }
        """

        let data = json.data(using: .utf8)!
        let house = try JSONDecoder().decode(HouseDTO.self, from: data)

        #expect(house.house_id == 1)
        #expect(house.sign == "Leo")
        #expect(house.start_degree == 135.28)
        #expect(house.end_degree == 165.58)
        #expect(house.planets?.count == 2)
        #expect(house.planets?.contains("Moon") == true)
    }

    @Test("HouseDTO should validate house_id range")
    func testHouseDTOHouseIDRange() throws {
        let validJSON = """
        {
            "house_id": 12,
            "sign": "Cancer",
            "start_degree": 108.58,
            "end_degree": 135.28,
            "planets": []
        }
        """

        let data = validJSON.data(using: .utf8)!
        let house = try JSONDecoder().decode(HouseDTO.self, from: data)

        #expect(house.house_id >= 1 && house.house_id <= 12)
    }

    @Test("HouseDTO should handle empty planets array")
    func testHouseDTOEmptyPlanets() throws {
        let json = """
        {
            "house_id": 2,
            "sign": "Virgo",
            "start_degree": 165.58,
            "end_degree": 195.88,
            "planets": []
        }
        """

        let data = json.data(using: .utf8)!
        let house = try JSONDecoder().decode(HouseDTO.self, from: data)

        #expect(house.planets?.isEmpty == true)
    }

    @Test("HouseDTO should handle null planets field")
    func testHouseDTONullPlanets() throws {
        let json = """
        {
            "house_id": 3,
            "sign": "Libra",
            "start_degree": 195.88,
            "end_degree": 226.18
        }
        """

        let data = json.data(using: .utf8)!
        let house = try JSONDecoder().decode(HouseDTO.self, from: data)

        #expect(house.planets == nil || house.planets?.isEmpty == true)
    }

    // MARK: - AspectDTO Tests

    @Test("AspectDTO should parse valid JSON")
    func testAspectDTOValidParsing() throws {
        let json = """
        {
            "aspecting_planet": "Sun",
            "aspected_planet": "Moon",
            "type": "Trine",
            "orb": 1.42,
            "diff": 118.58
        }
        """

        let data = json.data(using: .utf8)!
        let aspect = try JSONDecoder().decode(AspectDTO.self, from: data)

        #expect(aspect.aspecting_planet == "Sun")
        #expect(aspect.aspected_planet == "Moon")
        #expect(aspect.type == "Trine")
        #expect(aspect.orb == 1.42)
        #expect(aspect.diff == 118.58)
    }

    @Test("AspectDTO should handle all major aspect types")
    func testAspectDTOMajorAspectTypes() throws {
        let aspectTypes = ["Conjunction", "Sextile", "Square", "Trine", "Opposition", "Quincunx"]

        for aspectType in aspectTypes {
            let json = """
            {
                "aspecting_planet": "Mars",
                "aspected_planet": "Saturn",
                "type": "\(aspectType)",
                "orb": 5.22,
                "diff": 5.22
            }
            """

            let data = json.data(using: .utf8)!
            let aspect = try JSONDecoder().decode(AspectDTO.self, from: data)

            #expect(aspect.type == aspectType)
        }
    }

    @Test("AspectDTO should validate orb range")
    func testAspectDTOOrbRange() throws {
        let json = """
        {
            "aspecting_planet": "Venus",
            "aspected_planet": "Pluto",
            "type": "Quincunx",
            "orb": 0.24,
            "diff": 149.76
        }
        """

        let data = json.data(using: .utf8)!
        let aspect = try JSONDecoder().decode(AspectDTO.self, from: data)

        #expect(aspect.orb >= 0)
    }

    @Test("AspectDTO should validate diff range")
    func testAspectDTODiffRange() throws {
        let json = """
        {
            "aspecting_planet": "Uranus",
            "aspected_planet": "Neptune",
            "type": "Conjunction",
            "orb": 7.22,
            "diff": 7.22
        }
        """

        let data = json.data(using: .utf8)!
        let aspect = try JSONDecoder().decode(AspectDTO.self, from: data)

        #expect(aspect.diff >= 0 && aspect.diff <= 180)
    }
}
