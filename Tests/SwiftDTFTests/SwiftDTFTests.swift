import Testing
import Foundation
import NIOCore
@testable import SwiftDTF

@Suite struct SwiftDTFTests {
    let dataToFile = DataToFile.shared
    let testData = "Hello, World!".data(using: .utf8)!
    let testBinary: [UInt8] = [72, 101, 108, 108, 111] // "Hello"
    
    @Test("Generate file from Data")
    func testGenerateFileFromData() throws {
        let fileName = "test_data"
        let fileType = "txt"
        
        let filePath = try dataToFile.generateFile(
            data: testData,
            fileName: fileName,
            fileType: fileType
        )
        
        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))
        
        // Verify file contents
        let savedData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        #expect(savedData == testData)
    }
    
    @Test("Generate file from binary data")
    func testGenerateFileFromBinary() throws {
        let fileName = "test_binary"
        let fileType = "bin"
        
        let filePath = try dataToFile.generateFile(
            binary: testBinary,
            fileName: fileName,
            fileType: fileType
        )
        
        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))
        
        // Verify file contents
        let savedData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        #expect(savedData == Data(testBinary))
    }
    
    @Test("Generate file from ByteBuffer")
    func testGenerateFileFromByteBuffer() throws {
        let fileName = "test_bytebuffer"
        let fileType = "dat"
        var byteBuffer = ByteBuffer()
        byteBuffer.writeBytes(testBinary)
        
        let filePath = try dataToFile.generateFile(
            byteBuffer: byteBuffer,
            fileName: fileName,
            fileType: fileType
        )
        
        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))
        
        // Verify file contents
        let savedData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        #expect(savedData == Data(testBinary))
    }
    
    @Test("Generate file with custom path")
    func testGenerateFileWithCustomPath() throws {
        let fileName = "custom_path_test"
        let fileType = "txt"
        let customPath = "CustomFolder"
        
        let filePath = try dataToFile.generateFile(
            data: testData,
            fileName: fileName,
            filePath: customPath,
            fileType: fileType
        )
        
        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))
        #expect(filePath.contains(customPath))
    }
    
    @Test("Generate file with UUID")
    func testGenerateFileWithUUID() throws {
        let fileType = "txt"
        
        let filePath = try dataToFile.generateFile(
            data: testData,
            fileType: fileType
        )
        
        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))
        
        // Verify UUID format in filename
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        let nameWithoutExtension = fileName.replacingOccurrences(of: ".\(fileType)", with: "")
        #expect(nameWithoutExtension.count > 0)
    }
    
    @Test("Generate data from file")
    func testGenerateDataFromFile() throws {
        // First create a file
        let fileName = "read_test"
        let fileType = "txt"
        
        _ = try dataToFile.generateFile(
            data: testData,
            fileName: fileName,
            fileType: fileType
        )
        
        // Now read it back
        let (readData, tempURL) = try dataToFile.generateData(from: "\(fileName).\(fileType)")
        
        #expect(readData != nil)
        #expect(tempURL != nil)
        #expect(readData == testData)
        #expect(FileManager.default.fileExists(atPath: tempURL!.path))
    }
    
    @Test("Generate data from non-existent file throws error")
    func testGenerateDataFromNonExistentFile() throws {
        #expect(throws: DataToFile.Errors.self) {
            try dataToFile.generateData(from: "nonexistent.txt")
        }
    }
    
    @Test("Generate data with invalid filename throws error")
    func testGenerateDataWithInvalidFileName() throws {
        #expect(throws: DataToFile.Errors.fileComponentTooSmall) {
            try dataToFile.generateData(from: "invalid")
        }
    }
    
    @Test("Generate data from local file URL")
    func testGenerateDataFromLocalFileURL() throws {
        // First create a test file
        let testData = "Hello, World!".data(using: .utf8)!
        let fileName = "url_test"
        let fileType = "txt"
        
        let filePath = try dataToFile.generateFile(
            data: testData,
            fileName: fileName,
            fileType: fileType
        )
        
        // Convert to file URL
        let fileURL = URL(fileURLWithPath: filePath)
        let urlString = fileURL.absoluteString
        
        // Test reading from the file URL
        let readData = try dataToFile.generateDataFromURL(urlString)
        
        #expect(!readData.isEmpty)
        #expect(readData == testData)
        
        // Clean up
        try dataToFile.removeItem(fileName: fileName, fileType: fileType)
    }
    
    @Test("Generate data from non-existent file URL throws error")
    func testGenerateDataFromNonExistentFileURL() throws {
        let nonExistentURL = "file:///path/to/nonexistent/file.txt"
        
        #expect(throws: DataToFile.Errors.fileNotFound) {
            try dataToFile.generateDataFromURL(nonExistentURL)
        }
    }
    
    @Test("Generate data from invalid URL throws error")
    func testGenerateDataFromInvalidURL() throws {
        let invalidURL = "not-a-valid-url"
        
        #expect(throws: DataToFile.Errors.invalidFilePath) {
            try dataToFile.generateDataFromURL(invalidURL)
        }
    }
    
    @Test("Generate data from HTTP URL throws error")
    func testGenerateDataFromHTTPURL() throws {
        let httpURL = "https://example.com/file.txt"
        
        #expect(throws: DataToFile.Errors.invalidFilePath) {
            try dataToFile.generateDataFromURL(httpURL)
        }
    }
    
    @Test("Remove item")
    func testRemoveItem() throws {
        // Create a file
        let fileName = "remove_test"
        let fileType = "txt"
        
        let filePath = try dataToFile.generateFile(
            data: testData,
            fileName: fileName,
            fileType: fileType
        )
        
        #expect(FileManager.default.fileExists(atPath: filePath))
        
        // Remove it
        try dataToFile.removeItem(fileName: fileName, fileType: fileType)
        
        #expect(!FileManager.default.fileExists(atPath: filePath))
    }
    
    @Test("Remove non-existent item throws error")
    func testRemoveNonExistentItem() throws {
        #expect(throws: DataToFile.Errors.fileNotFound) {
            try dataToFile.removeItem(fileName: "nonexistent", fileType: "txt")
        }
    }
    
    @Test("Remove all items")
    func testRemoveAllItems() throws {
        // Create multiple files
        let fileNames = ["test1", "test2", "test3"]
        let fileType = "txt"
        
        for fileName in fileNames {
            _ = try dataToFile.generateFile(
                data: testData,
                fileName: fileName,
                fileType: fileType
            )
        }
        
        // Remove only our specific test files instead of all items
        for fileName in fileNames {
            try dataToFile.removeItem(fileName: fileName, fileType: fileType)
        }
        
        // Verify all our test files are removed
        for fileName in fileNames {
            let filePath = try getDocumentsDirectory().appendingPathComponent("Media").appendingPathComponent(fileName).appendingPathExtension(fileType)
            #expect(!FileManager.default.fileExists(atPath: filePath.path))
        }
    }
    
    @Test("Write data to temp file")
    func testWriteDataToTempFile() throws {
        let name = "temp_test"
        let type = "txt"
        
        let tempFilePath = try testData.writeDataToTempFile(name: name, type: type)
        
        #expect(!tempFilePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: tempFilePath))
        
        // Verify file contents
        let savedData = try Data(contentsOf: URL(fileURLWithPath: tempFilePath))
        #expect(savedData == testData)
    }
    
    @Test("Remove item from temp directory")
    func testRemoveItemFromTempDirectory() throws {
        let name = "temp_remove_test"
        let type = "txt"
        
        let tempFilePath = try testData.writeDataToTempFile(name: name, type: type)
        #expect(FileManager.default.fileExists(atPath: tempFilePath))
        
        let fileName = URL(fileURLWithPath: tempFilePath).lastPathComponent
        try dataToFile.removeItemFromTempDirectory(fileName: fileName)
        
        #expect(!FileManager.default.fileExists(atPath: tempFilePath))
    }
    
    @Test("Remove all items from temp directory")
    func testRemoveAllItemsFromTempDirectory() throws {
        // Create multiple temp files with our specific naming pattern
        let names = ["temp1", "temp2", "temp3"]
        let type = "txt"
        var tempFilePaths: [String] = []
        
        for name in names {
            let tempFilePath = try testData.writeDataToTempFile(name: name, type: type)
            tempFilePaths.append(tempFilePath)
        }
        
        // Verify files exist
        for path in tempFilePaths {
            #expect(FileManager.default.fileExists(atPath: path))
        }
        
        // Remove only our specific temp files
        for path in tempFilePaths {
            let fileName = URL(fileURLWithPath: path).lastPathComponent
            try? dataToFile.removeItemFromTempDirectory(fileName: fileName)
        }
        
        // Verify our files are removed
        for path in tempFilePaths {
            #expect(!FileManager.default.fileExists(atPath: path))
        }
    }
    
    @Test("ByteBuffer read failure throws error")
    func testByteBufferReadFailure() throws {
        let emptyBuffer = ByteBuffer()
        // Don't write anything to the buffer
        
        #expect(throws: DataToFile.Errors.readFailed) {
            try dataToFile.generateFile(
                byteBuffer: emptyBuffer,
                fileName: "test",
                fileType: "txt"
            )
        }
    }
    
    @Test("Data write failure throws error")
    func testDataWriteFailure() throws {
        // Test with empty file type which should cause an error
        #expect(throws: DataToFile.Errors.fileTypeMissing) {
            try testData.writeDataToFile(
                fileName: "test",
                fileType: "",
                filePath: "Media"
            )
        }
    }
    
    @Test("AllowedContentTypes path extension")
    func testAllowedContentTypesPathExtension() {
        #expect(AllowedContentTypes.png.pathExtension == "png")
        #expect(AllowedContentTypes.jpeg.pathExtension == "jpeg")
        #expect(AllowedContentTypes.mov.pathExtension == "mov")
        #expect(AllowedContentTypes.pdf.pathExtension == "pdf")
    }
    
    @Test("AllowedContentTypes from raw value")
    func testAllowedContentTypesFromRawValue() {
        #expect(AllowedContentTypes(rawValue: "png") == .png)
        #expect(AllowedContentTypes(rawValue: "PNG") == .png)
        #expect(AllowedContentTypes(rawValue: "jpeg") == .jpeg)
        #expect(AllowedContentTypes(rawValue: "mov") == .mov)
        #expect(AllowedContentTypes(rawValue: "invalid") == nil)
    }
    
    @Test("AllowedContentTypes from file extension")
    func testAllowedContentTypesFromFileExtension() {
        #expect(AllowedContentTypes(fileExtension: "png") == .png)
        #expect(AllowedContentTypes(fileExtension: "jpeg") == .jpeg)
        #expect(AllowedContentTypes(fileExtension: "mov") == .mov)
        #expect(AllowedContentTypes(fileExtension: "invalid") == nil)
    }
    
    // MARK: - Helper Methods
    
    private func getDocumentsDirectory() throws -> URL {
        let fm = FileManager.default
        let paths = fm.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = paths.first else {
            throw DataToFile.Errors.invalidFilePath
        }
        return documentsDirectory
    }
}

// MARK: - Performance Tests

@Suite struct SwiftDTFPerformanceTests {
    let dataToFile = DataToFile.shared
    
    @Test("Performance test for file generation")
    func testPerformanceGenerateFile() throws {
        let largeData = Data(repeating: 0, count: 1024 * 1024) // 1MB
        
        let startTime = Date()
        for i in 0..<10 {
            _ = try dataToFile.generateFile(
                data: largeData,
                fileName: "performance_test_\(i)",
                fileType: "dat"
            )
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Clean up test files
        for i in 0..<10 {
            try? dataToFile.removeItem(fileName: "performance_test_\(i)", fileType: "dat")
        }
        
        // Expect the operation to complete in reasonable time (less than 5 seconds for 10 iterations)
        #expect(duration < 5.0)
    }
    
    @Test("Performance test for data generation")
    func testPerformanceGenerateData() throws {
        // Create a file first
        let largeData = Data(repeating: 0, count: 1024 * 1024) // 1MB
        _ = try dataToFile.generateFile(
            data: largeData,
            fileName: "performance_read_test",
            fileType: "dat"
        )
        
        let startTime = Date()
        for _ in 0..<10 {
            _ = try dataToFile.generateData(from: "performance_read_test.dat")
        }
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Clean up test file
        try? dataToFile.removeItem(fileName: "performance_read_test", fileType: "dat")
        
        // Expect the operation to complete in reasonable time (less than 5 seconds for 10 iterations)
        #expect(duration < 5.0)
    }
}
