//
//  ImageCacheService.swift
//  AstroSvitla
//
//  Service for caching chart wheel images to local file system
//  Stores SVG and PNG files in Documents/ChartImages directory
//

import Foundation

/// Service for managing chart image file caching
final class ImageCacheService {

    // MARK: - Properties

    private let fileManager: FileManager
    private let cacheDirectory: URL

    // MARK: - Errors

    enum CacheError: LocalizedError {
        case directoryCreationFailed
        case fileNotFound(String)
        case saveFailed(Error)
        case loadFailed(Error)
        case deleteFailed(Error)

        var errorDescription: String? {
            switch self {
            case .directoryCreationFailed:
                return "Failed to create cache directory"
            case .fileNotFound(let fileID):
                return "Image file not found: \(fileID)"
            case .saveFailed(let error):
                return "Failed to save image: \(error.localizedDescription)"
            case .loadFailed(let error):
                return "Failed to load image: \(error.localizedDescription)"
            case .deleteFailed(let error):
                return "Failed to delete image: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Initialization

    /// Initialize with default Documents/ChartImages directory
    init() {
        self.fileManager = FileManager.default

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = documentsURL.appendingPathComponent("ChartImages", isDirectory: true)

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Initialize with custom cache directory (for testing)
    init(cacheDirectory: URL) {
        self.fileManager = FileManager.default
        self.cacheDirectory = cacheDirectory

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public Methods

    /// Save image data to cache
    /// - Parameters:
    ///   - data: Image file data (SVG or PNG)
    ///   - fileID: Unique identifier for the file (typically UUID string)
    ///   - format: File format extension ("svg" or "png")
    /// - Throws: CacheError if save fails
    func saveImage(data: Data, fileID: String, format: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileID).\(format)")

        do {
            try data.write(to: fileURL, options: .atomic)
            print("[ImageCacheService] Saved \(format.uppercased()) image \(fileID) (\(data.count) bytes)")
        } catch {
            throw CacheError.saveFailed(error)
        }
    }

    /// Load image data from cache
    /// - Parameters:
    ///   - fileID: Unique identifier for the file
    ///   - format: File format extension ("svg" or "png")
    /// - Returns: Image file data
    /// - Throws: CacheError if file not found or load fails
    func loadImage(fileID: String, format: String) throws -> Data {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileID).\(format)")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw CacheError.fileNotFound("\(fileID).\(format)")
        }

        do {
            let data = try Data(contentsOf: fileURL)
            print("[ImageCacheService] Loaded \(format.uppercased()) image \(fileID) (\(data.count) bytes)")
            return data
        } catch {
            throw CacheError.loadFailed(error)
        }
    }

    /// Delete image file from cache
    /// - Parameters:
    ///   - fileID: Unique identifier for the file
    ///   - format: File format extension ("svg" or "png")
    /// - Throws: CacheError if file not found or deletion fails
    func deleteImage(fileID: String, format: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileID).\(format)")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw CacheError.fileNotFound("\(fileID).\(format)")
        }

        do {
            try fileManager.removeItem(at: fileURL)
            print("[ImageCacheService] Deleted \(format.uppercased()) image \(fileID)")
        } catch {
            throw CacheError.deleteFailed(error)
        }
    }

    /// Check if image file exists in cache
    /// - Parameters:
    ///   - fileID: Unique identifier for the file
    ///   - format: File format extension ("svg" or "png")
    /// - Returns: True if file exists, false otherwise
    func imageExists(fileID: String, format: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileID).\(format)")
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Calculate total size of all cached images in bytes
    /// - Returns: Total cache size in bytes
    /// - Throws: Error if directory enumeration fails
    func cacheSize() throws -> Int {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var totalSize = 0

        for case let fileURL as URL in enumerator {
            guard fileURL.isFileURL else { continue }

            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += resourceValues.fileSize ?? 0
        }

        return totalSize
    }

    /// Clear all cached images
    /// - Throws: Error if deletion fails
    func clearCache() throws {
        guard fileManager.fileExists(atPath: cacheDirectory.path) else {
            return // Nothing to clear
        }

        // Remove all contents of cache directory
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )

        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// Get list of all cached file IDs with their formats
    /// - Returns: Array of tuples containing (fileID, format)
    func listCachedImages() -> [(fileID: String, format: String)] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return contents.compactMap { fileURL in
            let fileName = fileURL.lastPathComponent
            let components = fileName.components(separatedBy: ".")

            guard components.count == 2 else { return nil }

            return (fileID: components[0], format: components[1])
        }
    }

    /// Delete old cached images to enforce storage limits
    /// - Parameter maxSizeBytes: Maximum cache size in bytes (default: 100MB)
    /// - Throws: Error if deletion fails
    func enforceStorageLimit(maxSizeBytes: Int = 100 * 1024 * 1024) throws {
        let currentSize = try cacheSize()

        guard currentSize > maxSizeBytes else {
            return // Under limit, nothing to do
        }

        // Get all files with their creation dates
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        var files: [(url: URL, creationDate: Date, size: Int)] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.isFileURL else { continue }

            let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
            let creationDate = resourceValues.creationDate ?? Date.distantPast
            let size = resourceValues.fileSize ?? 0

            files.append((url: fileURL, creationDate: creationDate, size: size))
        }

        // Sort by creation date (oldest first) - LRU eviction
        files.sort { $0.creationDate < $1.creationDate }

        // Delete oldest files until under limit
        var deletedSize = 0
        for file in files {
            try fileManager.removeItem(at: file.url)
            deletedSize += file.size

            if currentSize - deletedSize <= maxSizeBytes {
                break
            }
        }
    }
}
