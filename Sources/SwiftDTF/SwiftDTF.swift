import Foundation
import NIOCore

/// A utility for handling data-to-file operations with support for various data types and platforms.
///
/// `DataToFile` provides a simple interface for writing data to files, managing file operations,
/// and handling different data formats including `Data`, `[UInt8]`, and `ByteBuffer`.
///
/// ## Usage
/// ```swift
/// let dataToFile = DataToFile.shared
/// 
/// // Write Data to file
/// let data = "Hello, World!".data(using: .utf8)!
/// let filePath = try dataToFile.generateFile(
///     data: data,
///     fileName: "test",
///     fileType: "txt"
/// )
/// 
/// // Read data from file
/// let (readData, tempURL) = try dataToFile.generateData(from: "test.txt")
/// ```
public struct DataToFile: Sendable {
    /// Shared instance for convenient access
    public static let shared = DataToFile()
    
    private init() {}
    
    /// Errors that can occur during file operations
    public enum Errors: LocalizedError {
        case fileComponentTooSmall
        case fileNameMissing
        case fileTypeMissing
        case invalidFilePath
        case fileNotFound
        case writeFailed
        case readFailed
        
        public var errorDescription: String? {
            switch self {
            case .fileComponentTooSmall:
                return "File component is too small"
            case .fileNameMissing:
                return "File name is missing"
            case .fileTypeMissing:
                return "File type is missing"
            case .invalidFilePath:
                return "Invalid file path"
            case .fileNotFound:
                return "File not found"
            case .writeFailed:
                return "Failed to write file"
            case .readFailed:
                return "Failed to read file"
            }
        }
    }
    
    /// Generates a file from Data
    ///
    /// - Parameters:
    ///   - data: The data to write to the file
    ///   - fileName: The name of the file (defaults to a UUID)
    ///   - filePath: The directory path within the documents directory (defaults to "Media")
    ///   - directory: The search path directory (defaults to .documentDirectory)
    ///   - domainMask: The domain mask for the search path (defaults to .userDomainMask)
    ///   - fileType: The file extension/type
    /// - Returns: The full path to the created file
    /// - Throws: `Errors` if the operation fails
    public func generateFile(
        data: Data,
        fileName: String = UUID().uuidString,
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
        fileType: String
    ) throws -> String {
        try data.writeDataToFile(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath,
            directory: directory,
            domainMask: domainMask
        )
    }
    
    /// Generates a file from binary data
    ///
    /// - Parameters:
    ///   - binary: The binary data to write to the file
    ///   - fileName: The name of the file (defaults to a UUID)
    ///   - filePath: The directory path within the documents directory (defaults to "Media")
    ///   - directory: The search path directory (defaults to .documentDirectory)
    ///   - domainMask: The domain mask for the search path (defaults to .userDomainMask)
    ///   - fileType: The file extension/type
    /// - Returns: The full path to the created file
    /// - Throws: `Errors` if the operation fails
    public func generateFile(
        binary: [UInt8],
        fileName: String = UUID().uuidString,
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
        fileType: String
    ) throws -> String {
        try Data(binary).writeDataToFile(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath,
            directory: directory,
            domainMask: domainMask
        )
    }
    
    /// Generates a file from ByteBuffer
    ///
    /// - Parameters:
    ///   - byteBuffer: The ByteBuffer to write to the file
    ///   - fileName: The name of the file (defaults to a UUID)
    ///   - filePath: The directory path within the documents directory (defaults to "Media")
    ///   - directory: The search path directory (defaults to .documentDirectory)
    ///   - domainMask: The domain mask for the search path (defaults to .userDomainMask)
    ///   - fileType: The file extension/type
    /// - Returns: The full path to the created file
    /// - Throws: `Errors` if the operation fails
    public func generateFile(
        byteBuffer: ByteBuffer,
        fileName: String = UUID().uuidString,
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
        fileType: String
    ) throws -> String {
        var byteBuffer = byteBuffer
        guard byteBuffer.readableBytes > 0 else {
            throw Errors.readFailed
        }
        guard let bytes = byteBuffer.readBytes(length: byteBuffer.readableBytes) else {
            throw Errors.readFailed
        }
        return try Data(bytes).writeDataToFile(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath,
            directory: directory,
            domainMask: domainMask
        )
    }
    
    /// Reads data from a file and creates a temporary copy
    ///
    /// - Parameter filePath: The path to the file to read
    /// - Returns: A tuple containing the file data and temporary file URL
    /// - Throws: `Errors` if the operation fails
    public func generateData(from filePath: String) throws -> (data: Data?, tempFileURL: URL?) {
    #if os(macOS) || os(iOS)
        let fm = FileManager.default
        let paths = fm.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = paths.first else { throw Errors.invalidFilePath }
        let saveDirectory = documentsDirectory.appendingPathComponent("Media")
        
        let fileName = filePath.components(separatedBy: "/").last
        guard let separatedFileName = fileName?.components(separatedBy: ".") else { 
            throw Errors.fileComponentTooSmall 
        }

        guard separatedFileName.count >= 2 else {
            throw Errors.fileComponentTooSmall
        }
        
        guard let name = separatedFileName.first else { throw Errors.fileNameMissing }
        guard let type = separatedFileName.last else { throw Errors.fileTypeMissing }
        
        let fileURL = saveDirectory.appendingPathComponent(name).appendingPathExtension(type)
        
        guard fm.fileExists(atPath: fileURL.path) else {
            throw Errors.fileNotFound
        }
        
        // Read data from the file
        let fileData = try Data(contentsOf: fileURL, options: .alwaysMapped)
        
        // Create a unique file name for the output in the temp directory
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(name)_temp.\(type)")
        
        // Create an output stream to the temp file
        guard let outputStream = OutputStream(url: tempFileURL, append: false) else { 
            throw Errors.writeFailed 
        }
        
        outputStream.open()
        defer { outputStream.close() }
        
        // Write data to the output stream
        let bytesWritten = fileData.withUnsafeBytes { bytes in
            outputStream.write(bytes.bindMemory(to: UInt8.self).baseAddress!, maxLength: bytes.count)
        }
        
        guard bytesWritten == fileData.count else {
            throw Errors.writeFailed
        }
        
        return (fileData, tempFileURL)
    #else
        throw Errors.invalidFilePath
    #endif
    }

    /// Removes a specific file
    ///
    /// - Parameters:
    ///   - fileName: The name of the file to remove
    ///   - fileType: The file type/extension
    ///   - filePath: The directory path within the documents directory (defaults to "Media")
    ///   - directory: The search path directory (defaults to .documentDirectory)
    ///   - domainMask: The domain mask for the search path (defaults to .userDomainMask)
    /// - Throws: `Errors` if the operation fails
    public func removeItem(
        fileName: String,
        fileType: String,
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask
    ) throws {
    #if os(macOS) || os(iOS)
        let fm = FileManager.default
        let paths = fm.urls(for: directory, in: domainMask)
        guard let documentsDirectory = paths.first else { throw Errors.invalidFilePath }
        let saveDirectory = documentsDirectory.appendingPathComponent(filePath)
        let file = saveDirectory.appendingPathComponent(fileName).appendingPathExtension(fileType)
        
        guard fm.fileExists(atPath: file.path) else {
            throw Errors.fileNotFound
        }
        
        try fm.removeItem(at: file)
    #endif
    }
    
    /// Removes all files from a directory
    ///
    /// - Parameters:
    ///   - filePath: The directory path within the documents directory (defaults to "Media")
    ///   - directory: The search path directory (defaults to .documentDirectory)
    ///   - domainMask: The domain mask for the search path (defaults to .userDomainMask)
    /// - Throws: `Errors` if the operation fails
    public func removeAllItems(
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask
    ) throws {
    #if os(macOS) || os(iOS)
        let fm = FileManager.default
        let paths = fm.urls(for: directory, in: domainMask)
        guard let documentsDirectory = paths.first else { throw Errors.invalidFilePath }
        let saveDirectory = documentsDirectory.appendingPathComponent(filePath)

        guard fm.fileExists(atPath: saveDirectory.path) else {
            throw Errors.fileNotFound
        }
        
        // Get the contents of the directory
        let items = try fm.contentsOfDirectory(atPath: saveDirectory.path)

        // Iterate through each item and delete it
        for item in items {
            let itemPath = saveDirectory.appendingPathComponent(item)
            try fm.removeItem(at: itemPath)
        }
    #endif
    }
    
    /// Removes a specific file from the temporary directory
    ///
    /// - Parameter fileName: The name of the file to remove
    /// - Throws: `Errors` if the operation fails
    public func removeItemFromTempDirectory(fileName: String) throws {
        let fileManager = FileManager.default
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let itemURL = tempDirectory.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: itemURL.path) else {
            throw Errors.fileNotFound
        }
        
        try fileManager.removeItem(at: itemURL)
    }
    
    /// Removes all files from the temporary directory
    ///
    /// - Throws: `Errors` if the operation fails
    public func removeAllItemsFromTempDirectory() throws {
        let fileManager = FileManager.default
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())

        guard fileManager.fileExists(atPath: tempDirectory.path) else {
            throw Errors.fileNotFound
        }
        
        // Get the contents of the temporary directory
        let items = try fileManager.contentsOfDirectory(atPath: tempDirectory.path)

        // Iterate through each item and delete it
        for item in items {
            let itemPath = tempDirectory.appendingPathComponent(item)
            try fileManager.removeItem(at: itemPath)
        }
    }
}

// MARK: - Data Extensions

extension Data {
    /// Writes data to a file in the documents directory
    ///
    /// - Parameters:
    ///   - fileName: The name of the file (defaults to a UUID)
    ///   - fileType: The file extension/type
    ///   - filePath: The directory path within the documents directory
    ///   - directory: The search path directory (defaults to .documentDirectory)
    ///   - domainMask: The domain mask for the search path (defaults to .userDomainMask)
    /// - Returns: The full path to the created file
    /// - Throws: `DataToFile.Errors` if the operation fails
    public func writeDataToFile(
        fileName: String = UUID().uuidString,
        fileType: String,
        filePath: String,
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask
    ) throws -> String {
    #if os(macOS) || os(iOS)
        guard !fileType.isEmpty else {
            throw DataToFile.Errors.fileTypeMissing
        }
        
        let fm = FileManager.default
        let paths = fm.urls(for: directory, in: domainMask)
        guard let documentsDirectory = paths.first else { throw DataToFile.Errors.invalidFilePath }
        let saveDirectory = documentsDirectory.appendingPathComponent(filePath)
        
        if !fm.fileExists(atPath: saveDirectory.path) {
            try fm.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
        }
        
        let fileURL = saveDirectory.appendingPathComponent(fileName).appendingPathExtension(fileType)
        
        try write(to: fileURL, options: .atomic)
        
        guard fm.fileExists(atPath: fileURL.path) else {
            throw DataToFile.Errors.writeFailed
        }
        
        return fileURL.path
    #else
        throw DataToFile.Errors.invalidFilePath
    #endif
    }
    
    /// Writes data to a temporary file
    ///
    /// - Parameters:
    ///   - name: The base name for the temporary file
    ///   - type: The file extension/type
    /// - Returns: The full path to the created temporary file
    /// - Throws: `DataToFile.Errors` if the operation fails
    public func writeDataToTempFile(
        name: String,
        type: String
    ) throws -> String {
    #if os(macOS) || os(iOS)
        guard !type.isEmpty else {
            throw DataToFile.Errors.fileTypeMissing
        }
        
        let fm = FileManager.default
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        
        // Construct the file URL in the format: name_temp.type
        let fileURL = tempDirectory.appendingPathComponent("\(name)_temp.\(type)")
        
        // Write the data to the file
        try write(to: fileURL, options: .atomic)
        
        guard fm.fileExists(atPath: fileURL.path) else {
            throw DataToFile.Errors.writeFailed
        }
        
        return fileURL.path
    #else
        throw DataToFile.Errors.invalidFilePath
    #endif
    }
}
