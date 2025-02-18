import Foundation
import NIOCore

public struct DataToFile: Sendable {
    public static let shared = DataToFile()
    
    private init() {}
    
    public enum Errors: Error {
        case fileComponenteTooSmall
    }
    
    public func generateFile(
        data: Data,
        fileName: String = UUID().uuidString,
        appendingPathComponent: String = "",
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
        fileType: String
    ) throws -> String {
        try data.writeDataToFile(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath
        )
    }
    
    public func generateFile(
        binary: [UInt8],
        fileName: String = UUID().uuidString,
        appendingPathComponent: String = "",
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
        fileType: String
    ) throws -> String {
        try Data(binary).writeDataToFile(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath
        )
    }
    
    public func generateFile(
        byteBuffer: ByteBuffer,
        fileName: String = UUID().uuidString,
        appendingPathComponent: String = "",
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
        fileType: String
    ) throws -> String {
        var byteBuffer = byteBuffer
        guard let bytes = byteBuffer.readBytes(length: byteBuffer.readableBytes) else { return "" }
        return try Data(bytes).writeDataToFile(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath
        )
    }
    
    public func generateData(from filePath: String) throws -> Data? {
#if os(macOS) || os(iOS)
        let fm = FileManager.default
        let paths = fm.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let saveDirectory = documentsDirectory.appendingPathComponent("Media")
        
        let fileName = filePath.components(separatedBy: "/").last
        guard let seperatedFileName =  fileName?.components(separatedBy: ".") else { return nil }

        if seperatedFileName.count == 1 {
            throw Errors.fileComponenteTooSmall
        } else {
            guard let name = seperatedFileName.first else { fatalError("File Name Does Not Exist") }
            guard let type = seperatedFileName.last else { fatalError("File Type Does Not Exist") }
            let fileURL = saveDirectory.appendingPathComponent(name).appendingPathExtension(type)
            let fileData = try Data(contentsOf: fileURL, options: .alwaysMapped)
            guard let outputStream = OutputStream(url: URL(filePath: NSTemporaryDirectory()), append: true) else { return nil }
            
            defer { outputStream.close() }
            
            _ = fileData.withUnsafeBytes { bytes in
                outputStream.write(bytes.bindMemory(to: UInt8.self).baseAddress!, maxLength: bytes.count)
            }
            return fileData
        }
#else
        return Data()
#endif
        
    }
    
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
        guard let documentsDirectory = paths.first else { fatalError("Path Not Found") }
        let saveDirectory = documentsDirectory.appendingPathComponent(filePath)
        let file = saveDirectory.appendingPathComponent(fileName).appendingPathExtension(fileType)
        if fm.fileExists(atPath: saveDirectory.path) {
            try fm.removeItem(at: file)
        }
#endif
    }
    
    public func removeAllItems(
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask
    ) throws {
    #if os(macOS) || os(iOS)
        let fm = FileManager.default
        let paths = fm.urls(for: directory, in: domainMask)
        guard let documentsDirectory = paths.first else { fatalError("Path Not Found") }
        let saveDirectory = documentsDirectory.appendingPathComponent(filePath)

        // Check if the directory exists
        if fm.fileExists(atPath: saveDirectory.path) {
            // Get the contents of the directory
            let items = try fm.contentsOfDirectory(atPath: saveDirectory.path)

            // Iterate through each item and delete it
            for item in items {
                let itemPath = saveDirectory.appendingPathComponent(item)
                try fm.removeItem(at: itemPath)
                print("Deleted: \(itemPath)")
            }
            
            print("All items deleted successfully from \(saveDirectory.path).")
        } else {
            print("Directory does not exist: \(saveDirectory.path)")
        }
    #endif
    }
}

extension Data {
    func writeDataToFile(
        fileName: String = UUID().uuidString,
        fileType: String,
        filePath: String,
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask
    ) throws -> String {
#if os(macOS) || os(iOS)
        let fm = FileManager.default
        let paths = fm.urls(for: directory, in: domainMask)
        guard let documentsDirectory = paths.first else { fatalError("Path Not Found") }
        let saveDirectory = documentsDirectory.appendingPathComponent(filePath)
        
        if !fm.fileExists(atPath: saveDirectory.path) {
            try fm.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
        }
        
        let fileURL = saveDirectory.appendingPathComponent(fileName).appendingPathExtension(fileType)
        
        try write(to: fileURL, options: .atomic)
        if fm.fileExists(atPath: fileURL.path) {
            print("Wrote data to file path: \(fileURL.path)")
        } else {
            print("File not writen when returned")
        }
        return fileURL.path
#else
        return ""
#endif
    }
}
