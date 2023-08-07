import Foundation
import NIOCore

public actor DataToFile: Sendable {
    public static let shared = DataToFile()
    
    public enum FileType: String, Sendable {
        case jpg, png, mov, m4v, mp4, mp3, pdf, txt, tiff, docC, pages
    }
    
    private init() {
        
    }
    
    public func generateFile(
        data: Data,
        fileName: String = UUID().uuidString,
        appendingPathComponent: String = "",
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask,
        fileType: FileType
    ) async throws -> String {
        try await data.writeDataToFile(
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
        fileType: FileType
    ) async throws -> String {
        try await Data(binary).writeDataToFile(
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
        fileType: FileType
    ) async throws -> String {
        var byteBuffer = byteBuffer
        guard let bytes = byteBuffer.readBytes(length: byteBuffer.readableBytes) else { return "" }
        return try await Data(bytes).writeDataToFile(
            fileName: fileName,
            fileType: fileType,
            filePath: filePath
        )
       }
    
    public func generateData(from filePath: String) async throws -> Data? {
        let fm = FileManager.default
        let paths = fm.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let saveDirectory = documentsDirectory.appendingPathComponent("Media")
        
        let fileName = filePath.components(separatedBy: "/").last
        guard let seperatedFileName =  fileName?.components(separatedBy: ".") else { return nil }
        let fileURL = saveDirectory.appendingPathComponent(seperatedFileName[0]).appendingPathExtension("\(seperatedFileName[1])")

        let fileData = try Data(contentsOf: fileURL, options: .alwaysMapped)
        guard let outputStream = OutputStream(url: URL(filePath: NSTemporaryDirectory()), append: true) else { return nil }
        defer { outputStream.close() }
        
        _ = fileData.withUnsafeBytes { bytes in
            outputStream.write(bytes.bindMemory(to: UInt8.self).baseAddress!, maxLength: bytes.count)
        }
        
        return fileData
    }
    
    public func removeItem(
        fileName: String,
        fileType: DataToFile.FileType,
        filePath: String = "Media",
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask
    ) async throws {
        let fm = FileManager.default
        let paths = fm.urls(for: directory, in: domainMask)
        let documentsDirectory = paths[0]
        let saveDirectory = documentsDirectory.appendingPathComponent(filePath)
        let file = saveDirectory.appendingPathComponent(fileName).appendingPathExtension(fileType.rawValue)
        if fm.fileExists(atPath: saveDirectory.path) {
            try fm.removeItem(at: file)
        }
    }
}

extension Data {
    func writeDataToFile(
        fileName: String = UUID().uuidString,
        fileType: DataToFile.FileType,
        filePath: String,
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        domainMask: FileManager.SearchPathDomainMask = .userDomainMask
    ) async throws -> String {
        let fm = FileManager.default
        let paths = fm.urls(for: directory, in: domainMask)
        let documentsDirectory = paths[0]
        let saveDirectory = documentsDirectory.appendingPathComponent(filePath)
        
        if !fm.fileExists(atPath: saveDirectory.path) {
            try? fm.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
        }
        
        let fileURL = saveDirectory.appendingPathComponent(fileName).appendingPathExtension(fileType.rawValue)

        print("Wrote data to file path: \(fileURL.path)")
        try write(to: fileURL, options: .atomic)
        return fileURL.path
    }
}
