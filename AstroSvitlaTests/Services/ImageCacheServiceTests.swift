//
//  ImageCacheServiceTests.swift
//  AstroSvitlaTests
//
//  Unit tests for ImageCacheService
//  Tests file saving, loading, deletion, and storage management
//

import Testing
import Foundation
@testable import AstroSvitla

struct ImageCacheServiceTests {

    let tempDirectory: URL
    let cacheService: ImageCacheService

    init() throws {
        // Create temporary directory for tests
        let fileManager = FileManager.default
        tempDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("ImageCacheServiceTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Initialize cache service with test directory
        cacheService = ImageCacheService(cacheDirectory: tempDirectory)
    }

    // MARK: - Save Image Tests

    @Test("Save SVG image creates file with correct data")
    func testSaveImageSVG() throws {
        // Arrange
        let fileID = "test-chart-123"
        let testSVGData = "<svg>test content</svg>".data(using: .utf8)!

        // Act
        try cacheService.saveImage(data: testSVGData, fileID: fileID, format: "svg")

        // Assert - File should exist
        let expectedURL = tempDirectory.appendingPathComponent("test-chart-123.svg")
        #expect(FileManager.default.fileExists(atPath: expectedURL.path))

        // Assert - File content matches
        let savedData = try Data(contentsOf: expectedURL)
        #expect(savedData == testSVGData)
    }

    @Test("Save PNG image creates file with correct data")
    func testSaveImagePNG() throws {
        // Arrange
        let fileID = "test-chart-456"
        let testPNGData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header bytes

        // Act
        try cacheService.saveImage(data: testPNGData, fileID: fileID, format: "png")

        // Assert - File should exist
        let expectedURL = tempDirectory.appendingPathComponent("test-chart-456.png")
        #expect(FileManager.default.fileExists(atPath: expectedURL.path))

        // Assert - File content matches
        let savedData = try Data(contentsOf: expectedURL)
        #expect(savedData == testPNGData)
    }

    @Test("Save image overwrites existing file")
    func testSaveImageOverwrite() throws {
        // Arrange
        let fileID = "test-overwrite"
        let originalData = "original".data(using: .utf8)!
        let newData = "updated".data(using: .utf8)!

        // Act - Save original
        try cacheService.saveImage(data: originalData, fileID: fileID, format: "svg")

        // Act - Overwrite with new data
        try cacheService.saveImage(data: newData, fileID: fileID, format: "svg")

        // Assert - File contains new data
        let savedData = try cacheService.loadImage(fileID: fileID, format: "svg")
        #expect(savedData == newData)
    }

    // MARK: - Load Image Tests

    @Test("Load existing image returns correct data")
    func testLoadImageSuccess() throws {
        // Arrange
        let fileID = "test-load"
        let testData = "test image data".data(using: .utf8)!
        try cacheService.saveImage(data: testData, fileID: fileID, format: "svg")

        // Act
        let loadedData = try cacheService.loadImage(fileID: fileID, format: "svg")

        // Assert
        #expect(loadedData == testData)
    }

    @Test("Load non-existent image throws error")
    func testLoadImageNotFound() throws {
        // Act & Assert
        #expect(throws: Error.self) {
            try cacheService.loadImage(fileID: "non-existent", format: "svg")
        }
    }

    @Test("Load image with wrong format throws error")
    func testLoadImageWrongFormat() throws {
        // Arrange
        let fileID = "test-format"
        let testData = "test data".data(using: .utf8)!
        try cacheService.saveImage(data: testData, fileID: fileID, format: "svg")

        // Act & Assert - Try to load as PNG instead of SVG
        #expect(throws: Error.self) {
            try cacheService.loadImage(fileID: fileID, format: "png")
        }
    }

    // MARK: - Delete Image Tests

    @Test("Delete existing image removes file")
    func testDeleteImageSuccess() throws {
        // Arrange
        let fileID = "test-delete"
        let testData = "test".data(using: .utf8)!
        try cacheService.saveImage(data: testData, fileID: fileID, format: "svg")

        // Act
        try cacheService.deleteImage(fileID: fileID, format: "svg")

        // Assert - File should not exist
        let expectedURL = tempDirectory.appendingPathComponent("test-delete.svg")
        #expect(!FileManager.default.fileExists(atPath: expectedURL.path))
    }

    @Test("Delete non-existent image throws error")
    func testDeleteImageNotFound() throws {
        // Act & Assert
        #expect(throws: Error.self) {
            try cacheService.deleteImage(fileID: "non-existent", format: "svg")
        }
    }

    // MARK: - Cache Size Tests

    @Test("Cache size returns zero for empty directory")
    func testCacheSizeEmpty() throws {
        // Act
        let size = try cacheService.cacheSize()

        // Assert
        #expect(size == 0)
    }

    @Test("Cache size returns correct total for multiple files")
    func testCacheSizeMultipleFiles() throws {
        // Arrange
        let file1Data = Data(repeating: 0x01, count: 1000) // 1KB
        let file2Data = Data(repeating: 0x02, count: 2000) // 2KB
        let file3Data = Data(repeating: 0x03, count: 3000) // 3KB

        try cacheService.saveImage(data: file1Data, fileID: "file1", format: "svg")
        try cacheService.saveImage(data: file2Data, fileID: "file2", format: "png")
        try cacheService.saveImage(data: file3Data, fileID: "file3", format: "svg")

        // Act
        let size = try cacheService.cacheSize()

        // Assert - Total should be 6KB (6000 bytes)
        #expect(size == 6000)
    }

    @Test("Cache size updates after deletion")
    func testCacheSizeAfterDeletion() throws {
        // Arrange
        let file1Data = Data(repeating: 0x01, count: 1000)
        let file2Data = Data(repeating: 0x02, count: 2000)

        try cacheService.saveImage(data: file1Data, fileID: "file1", format: "svg")
        try cacheService.saveImage(data: file2Data, fileID: "file2", format: "svg")

        let initialSize = try cacheService.cacheSize()
        #expect(initialSize == 3000)

        // Act - Delete one file
        try cacheService.deleteImage(fileID: "file1", format: "svg")

        // Assert - Size should be reduced
        let newSize = try cacheService.cacheSize()
        #expect(newSize == 2000)
    }

    // MARK: - File Existence Tests

    @Test("Image exists returns true for saved image")
    func testImageExistsTrue() throws {
        // Arrange
        let fileID = "test-exists"
        let testData = "test".data(using: .utf8)!
        try cacheService.saveImage(data: testData, fileID: fileID, format: "svg")

        // Act
        let exists = cacheService.imageExists(fileID: fileID, format: "svg")

        // Assert
        #expect(exists)
    }

    @Test("Image exists returns false for non-existent image")
    func testImageExistsFalse() throws {
        // Act
        let exists = cacheService.imageExists(fileID: "non-existent", format: "svg")

        // Assert
        #expect(!exists)
    }

    // MARK: - Clear Cache Tests

    @Test("Clear cache removes all files")
    func testClearCache() throws {
        // Arrange - Save multiple images
        let testData = "test".data(using: .utf8)!
        try cacheService.saveImage(data: testData, fileID: "file1", format: "svg")
        try cacheService.saveImage(data: testData, fileID: "file2", format: "png")
        try cacheService.saveImage(data: testData, fileID: "file3", format: "svg")

        // Verify files exist
        #expect(cacheService.imageExists(fileID: "file1", format: "svg"))
        #expect(cacheService.imageExists(fileID: "file2", format: "png"))
        #expect(cacheService.imageExists(fileID: "file3", format: "svg"))

        // Act
        try cacheService.clearCache()

        // Assert - All files should be deleted
        #expect(!cacheService.imageExists(fileID: "file1", format: "svg"))
        #expect(!cacheService.imageExists(fileID: "file2", format: "png"))
        #expect(!cacheService.imageExists(fileID: "file3", format: "svg"))

        // Assert - Cache size should be zero
        let size = try cacheService.cacheSize()
        #expect(size == 0)
    }

    // MARK: - Edge Cases

    @Test("Save empty data creates file")
    func testSaveEmptyData() throws {
        // Arrange
        let fileID = "empty-file"
        let emptyData = Data()

        // Act
        try cacheService.saveImage(data: emptyData, fileID: fileID, format: "svg")

        // Assert - File should exist
        #expect(cacheService.imageExists(fileID: fileID, format: "svg"))

        // Assert - Can load empty data
        let loadedData = try cacheService.loadImage(fileID: fileID, format: "svg")
        #expect(loadedData.isEmpty)
    }

    @Test("Save large image data succeeds")
    func testSaveLargeImage() throws {
        // Arrange - Create 10MB file
        let fileID = "large-file"
        let largeData = Data(repeating: 0xFF, count: 10 * 1024 * 1024)

        // Act
        try cacheService.saveImage(data: largeData, fileID: fileID, format: "png")

        // Assert - File should exist
        #expect(cacheService.imageExists(fileID: fileID, format: "png"))

        // Assert - Data matches
        let loadedData = try cacheService.loadImage(fileID: fileID, format: "png")
        #expect(loadedData.count == largeData.count)
    }

    @Test("Special characters in file ID are handled safely")
    func testSpecialCharactersInFileID() throws {
        // Arrange - File ID with UUID format (common case)
        let fileID = "ABC123-DEF456-GHI789"
        let testData = "test".data(using: .utf8)!

        // Act
        try cacheService.saveImage(data: testData, fileID: fileID, format: "svg")

        // Assert
        #expect(cacheService.imageExists(fileID: fileID, format: "svg"))
        let loadedData = try cacheService.loadImage(fileID: fileID, format: "svg")
        #expect(loadedData == testData)
    }
}
