import Testing
import Foundation
import NIOCore
@testable import SwiftDTF

#if os(macOS)
import AppKit
#endif

@Suite(.serialized) struct SwiftDTFTests {
    let dataToFile = DataToFile.shared
    let testData = "Hello, World!".data(using: .utf8)!
    let testBinary: [UInt8] = [72, 101, 108, 108, 111]

    @Test("Generate file from Data")
    func testGenerateFileFromData() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        let filePath = try dataToFile.generateFile(
            data: testData,
            fileName: "test_data",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "txt"
        )

        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))
        #expect(try Data(contentsOf: URL(fileURLWithPath: filePath)) == testData)
    }

    @Test("Generate file from binary data")
    func testGenerateFileFromBinary() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        let filePath = try dataToFile.generateFile(
            binary: testBinary,
            fileName: "test_binary",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "bin"
        )

        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))
        #expect(try Data(contentsOf: URL(fileURLWithPath: filePath)) == Data(testBinary))
    }

    @Test("Generate file from ByteBuffer")
    func testGenerateFileFromByteBuffer() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        var byteBuffer = ByteBuffer()
        byteBuffer.writeBytes(testBinary)

        let filePath = try dataToFile.generateFile(
            byteBuffer: byteBuffer,
            fileName: "test_bytebuffer",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "dat"
        )

        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))
        #expect(try Data(contentsOf: URL(fileURLWithPath: filePath)) == Data(testBinary))
    }

    @Test("Generate file with custom path")
    func testGenerateFileWithCustomPath() throws {
        let subdirectory = uniqueSubdirectory().appending("/Nested")
        defer { cleanup(rootTestDirectory(from: subdirectory)) }

        let filePath = try dataToFile.generateFile(
            data: testData,
            fileName: "custom_path_test",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "txt"
        )

        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))
        #expect(filePath.contains("Nested"))
    }

    @Test("Generate file with UUID")
    func testGenerateFileWithUUID() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        let filePath = try dataToFile.generateFile(
            data: testData,
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "txt"
        )

        #expect(!filePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: filePath))

        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        let nameWithoutExtension = fileName.replacingOccurrences(of: ".txt", with: "")
        #expect(!nameWithoutExtension.isEmpty)
    }

    @Test("Generate data from file")
    func testGenerateDataFromFile() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        _ = try dataToFile.generateFile(
            data: testData,
            fileName: "read_test",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "txt"
        )

        let (readData, tempURL) = try dataToFile.generateData(
            from: "read_test.txt",
            inSubdirectory: subdirectory,
            directory: .cachesDirectory
        )

        #expect(readData == testData)
        #expect(tempURL != nil)
        #expect(FileManager.default.fileExists(atPath: tempURL!.path))
    }

    @Test("Generate data handles multi-dot file names")
    func testGenerateDataHandlesMultiDotFileNames() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        _ = try dataToFile.generateFile(
            data: testData,
            fileName: "archive.tar",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "gz"
        )

        let (readData, tempURL) = try dataToFile.generateData(
            from: "archive.tar.gz",
            inSubdirectory: subdirectory,
            directory: .cachesDirectory
        )

        #expect(readData == testData)
        #expect(tempURL?.lastPathComponent == "archive.tar_temp.gz")
    }

    @Test("Read data and stage temp supports custom subdirectories")
    func testReadDataAndStageTempSupportsCustomSubdirectories() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        _ = try dataToFile.generateFile(
            data: testData,
            fileName: "custom_read",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "txt"
        )

        let result = try dataToFile.readDataAndStageTemp(
            from: "custom_read.txt",
            inSubdirectory: subdirectory,
            directory: .cachesDirectory
        )

        #expect(result.data == testData)
        #expect(FileManager.default.fileExists(atPath: result.tempFileURL.path))
    }

    @Test("Generate data from non-existent file throws error")
    func testGenerateDataFromNonExistentFile() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        #expect(throws: DataToFile.Errors.fileNotFound) {
            try dataToFile.generateData(
                from: "nonexistent.txt",
                inSubdirectory: subdirectory,
                directory: .cachesDirectory
            )
        }
    }

    @Test("Generate data with invalid filename throws error")
    func testGenerateDataWithInvalidFileName() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        #expect(throws: DataToFile.Errors.fileComponentTooSmall) {
            try dataToFile.generateData(
                from: "invalid",
                inSubdirectory: subdirectory,
                directory: .cachesDirectory
            )
        }
    }

    @Test("Relative directory traversal is rejected")
    func testRelativeDirectoryTraversalIsRejected() throws {
        #expect(throws: DataToFile.Errors.invalidFilePath) {
            try dataToFile.generateFile(
                data: testData,
                fileName: "escape",
                filePath: "../escape",
                directory: .cachesDirectory,
                fileType: "txt"
            )
        }

        #expect(throws: DataToFile.Errors.invalidFilePath) {
            try dataToFile.generateData(
                from: "escape.txt",
                inSubdirectory: "../escape",
                directory: .cachesDirectory
            )
        }
    }

    @Test("File component traversal is rejected")
    func testFileComponentTraversalIsRejected() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        #expect(throws: DataToFile.Errors.invalidFilePath) {
            try dataToFile.generateFile(
                data: testData,
                fileName: "../escape",
                filePath: subdirectory,
                directory: .cachesDirectory,
                fileType: "txt"
            )
        }

        #expect(throws: DataToFile.Errors.invalidFilePath) {
            try dataToFile.removeItemFromTempDirectory(fileName: "../escape_temp.txt")
        }
    }

    @Test("Generate data from local file URL")
    func testGenerateDataFromLocalFileURL() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        let filePath = try dataToFile.generateFile(
            data: testData,
            fileName: "url_test",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "txt"
        )

        let readData = try dataToFile.generateDataFromURL(URL(fileURLWithPath: filePath).absoluteString)

        #expect(!readData.isEmpty)
        #expect(readData == testData)
    }

    @Test("Read data and stage temp from local file URL")
    func testReadDataAndStageTempFromLocalFileURL() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        let filePath = try dataToFile.generateFile(
            data: testData,
            fileName: "stage_url_test",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "txt"
        )

        let result = try dataToFile.readDataAndStageTemp(fromFileURL: URL(fileURLWithPath: filePath))

        #expect(result.data == testData)
        #expect(result.tempFileURL.lastPathComponent == "stage_url_test_temp.txt")
        #expect(FileManager.default.fileExists(atPath: result.tempFileURL.path))
    }

    @Test("Read data and stage temp from extensionless local file URL")
    func testReadDataAndStageTempFromExtensionlessLocalFileURL() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }
        let directory = try cachesDirectory().appendingPathComponent(subdirectory, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("extensionless")
        try testData.write(to: fileURL, options: .atomic)

        let result = try dataToFile.readDataAndStageTemp(fromFileURL: fileURL)
        defer { try? FileManager.default.removeItem(at: result.tempFileURL) }

        #expect(result.data == testData)
        #expect(result.tempFileURL.lastPathComponent == "extensionless_temp.")
        #expect(FileManager.default.fileExists(atPath: result.tempFileURL.path))
    }

    @Test("Generate data from non-existent file URL throws error")
    func testGenerateDataFromNonExistentFileURL() throws {
        #expect(throws: DataToFile.Errors.fileNotFound) {
            try dataToFile.generateDataFromURL("file:///path/to/nonexistent/file.txt")
        }
    }

    @Test("Generate data from invalid URL throws error")
    func testGenerateDataFromInvalidURL() throws {
        #expect(throws: DataToFile.Errors.invalidFilePath) {
            try dataToFile.generateDataFromURL("not-a-valid-url")
        }
    }

    @Test("Generate data from HTTP URL throws error")
    func testGenerateDataFromHTTPURL() throws {
        #expect(throws: DataToFile.Errors.invalidFilePath) {
            try dataToFile.generateDataFromURL("https://example.com/file.txt")
        }
    }

    @Test("Remove item")
    func testRemoveItem() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        let filePath = try dataToFile.generateFile(
            data: testData,
            fileName: "remove_test",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "txt"
        )

        #expect(FileManager.default.fileExists(atPath: filePath))

        try dataToFile.removeItem(
            fileName: "remove_test",
            fileType: "txt",
            filePath: subdirectory,
            directory: .cachesDirectory
        )

        #expect(!FileManager.default.fileExists(atPath: filePath))
    }

    @Test("Remove non-existent item throws error")
    func testRemoveNonExistentItem() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        #expect(throws: DataToFile.Errors.fileNotFound) {
            try dataToFile.removeItem(
                fileName: "nonexistent",
                fileType: "txt",
                filePath: subdirectory,
                directory: .cachesDirectory
            )
        }
    }

    @Test("Remove all items")
    func testRemoveAllItems() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }

        for fileName in ["test1", "test2", "test3"] {
            _ = try dataToFile.generateFile(
                data: testData,
                fileName: fileName,
                filePath: subdirectory,
                directory: .cachesDirectory,
                fileType: "txt"
            )
        }

        try dataToFile.removeAllItems(filePath: subdirectory, directory: .cachesDirectory)

        for fileName in ["test1", "test2", "test3"] {
            let fileURL = try cachedFileURL(subdirectory: subdirectory, fileName: fileName, fileType: "txt")
            #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        }
    }

    @Test("Write data to temp file")
    func testWriteDataToTempFile() throws {
        let tempFilePath = try testData.writeDataToTempFile(name: "temp_test_\(UUID().uuidString)", type: "txt")
        defer { try? FileManager.default.removeItem(atPath: tempFilePath) }

        #expect(!tempFilePath.isEmpty)
        #expect(FileManager.default.fileExists(atPath: tempFilePath))
        #expect(try Data(contentsOf: URL(fileURLWithPath: tempFilePath)) == testData)
    }

    @Test("Write data to temp file URL verifies existence")
    func testWriteDataToTempFileURL() throws {
        let tempFileURL = try testData.writeDataToTempFileURL(name: "temp_url_test_\(UUID().uuidString)", type: "txt")
        defer { try? FileManager.default.removeItem(at: tempFileURL) }

        #expect(FileManager.default.fileExists(atPath: tempFileURL.path))
        #expect(try Data(contentsOf: tempFileURL) == testData)
    }

    @Test("Remove item from temp directory")
    func testRemoveItemFromTempDirectory() throws {
        let tempFilePath = try testData.writeDataToTempFile(name: "temp_remove_test_\(UUID().uuidString)", type: "txt")
        #expect(FileManager.default.fileExists(atPath: tempFilePath))

        try dataToFile.removeItemFromTempDirectory(fileName: URL(fileURLWithPath: tempFilePath).lastPathComponent)

        #expect(!FileManager.default.fileExists(atPath: tempFilePath))
    }

    @Test("Remove all SwiftDTF items from temp directory only removes staged files")
    func testRemoveAllSwiftDTFItemsFromTempDirectoryOnlyRemovesSwiftDTFFiles() throws {
        let tempFileURL1 = try testData.writeDataToTempFileURL(name: "temp_scope_\(UUID().uuidString)", type: "txt")
        let tempFileURL2 = try testData.writeDataToTempFileURL(name: "temp_scope_\(UUID().uuidString)", type: "txt")
        let unrelatedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftDTF_unrelated_\(UUID().uuidString).txt")
        try testData.write(to: unrelatedURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: unrelatedURL) }

        try dataToFile.removeAllSwiftDTFItemsFromTempDirectory()

        #expect(!FileManager.default.fileExists(atPath: tempFileURL1.path))
        #expect(!FileManager.default.fileExists(atPath: tempFileURL2.path))
        #expect(FileManager.default.fileExists(atPath: unrelatedURL.path))
    }

    @Test("ByteBuffer read failure throws error")
    func testByteBufferReadFailure() throws {
        let emptyBuffer = ByteBuffer()

        #expect(throws: DataToFile.Errors.readFailed) {
            try dataToFile.generateFile(
                byteBuffer: emptyBuffer,
                fileName: "test",
                filePath: uniqueSubdirectory(),
                directory: .cachesDirectory,
                fileType: "txt"
            )
        }
    }

    @Test("Data write failure throws error")
    func testDataWriteFailure() throws {
        #expect(throws: DataToFile.Errors.fileTypeMissing) {
            try testData.writeDataToFile(
                fileName: "test",
                fileType: "",
                filePath: uniqueSubdirectory(),
                directory: .cachesDirectory
            )
        }
    }

    @Test("URL-first write validates and writes")
    func testURLFirstWriteValidatesAndWrites() throws {
        let directory = try cachesDirectory().appendingPathComponent(uniqueSubdirectory(), isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = try dataToFile.generateFile(
            data: testData,
            to: directory,
            name: "url_first",
            fileExtension: "txt"
        )

        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        #expect(try Data(contentsOf: fileURL) == testData)
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

    @Test("Performance test for file generation")
    func testPerformanceGenerateFile() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }
        let largeData = Data(repeating: 0, count: 1024 * 1024)

        let startTime = Date()
        for index in 0..<10 {
            _ = try dataToFile.generateFile(
                data: largeData,
                fileName: "performance_test_\(index)",
                filePath: subdirectory,
                directory: .cachesDirectory,
                fileType: "dat"
            )
        }
        let duration = Date().timeIntervalSince(startTime)

        #expect(duration < 5.0)
    }

    @Test("Performance test for data generation")
    func testPerformanceGenerateData() throws {
        let subdirectory = uniqueSubdirectory()
        defer { cleanup(subdirectory) }
        let largeData = Data(repeating: 0, count: 1024 * 1024)

        _ = try dataToFile.generateFile(
            data: largeData,
            fileName: "performance_read_test",
            filePath: subdirectory,
            directory: .cachesDirectory,
            fileType: "dat"
        )

        let startTime = Date()
        for _ in 0..<10 {
            _ = try dataToFile.generateData(
                from: "performance_read_test.dat",
                inSubdirectory: subdirectory,
                directory: .cachesDirectory
            )
        }
        let duration = Date().timeIntervalSince(startTime)

        #expect(duration < 5.0)
    }

    #if os(macOS)
    @Test("macOS: Encode PNG from NSImage")
    func testMacOSEncodePNGFromNSImage() throws {
        let image = makeTestImage1x1()
        let data = _swiftDTFEncodePNG(image: image)

        #expect(data != nil)
        #expect(!(data ?? Data()).isEmpty)
        #expect(NSImage(data: data!) != nil)
    }

    @Test("macOS: Encode JPEG from NSImage quality clamping")
    func testMacOSEncodeJPEGFromNSImageQualityClamping() throws {
        let image = makeTestImage1x1()

        let low = _swiftDTFEncodeJPEG(image: image, quality: -1)
        #expect(low != nil)
        #expect(!(low ?? Data()).isEmpty)
        #expect(NSImage(data: low!) != nil)

        let high = _swiftDTFEncodeJPEG(image: image, quality: 2)
        #expect(high != nil)
        #expect(!(high ?? Data()).isEmpty)
        #expect(NSImage(data: high!) != nil)
    }

    private func makeTestImage1x1() -> NSImage {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 1,
            pixelsHigh: 1,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        let image = NSImage(size: NSSize(width: 1, height: 1))
        if let rep {
            rep.size = NSSize(width: 1, height: 1)
            if let bytes = rep.bitmapData {
                bytes[0] = 255
                bytes[1] = 0
                bytes[2] = 0
                bytes[3] = 255
            }
            image.addRepresentation(rep)
        }
        return image
    }
    #endif

    private func uniqueSubdirectory() -> String {
        "SwiftDTFTests/\(UUID().uuidString)"
    }

    private func rootTestDirectory(from subdirectory: String) -> String {
        subdirectory.split(separator: "/").first.map(String.init) ?? subdirectory
    }

    private func cleanup(_ subdirectory: String) {
        guard let directory = try? cachesDirectory().appendingPathComponent(subdirectory, isDirectory: true) else {
            return
        }
        try? FileManager.default.removeItem(at: directory)
    }

    private func cachedFileURL(subdirectory: String, fileName: String, fileType: String) throws -> URL {
        try cachesDirectory()
            .appendingPathComponent(subdirectory, isDirectory: true)
            .appendingPathComponent(fileName)
            .appendingPathExtension(fileType)
    }

    private func cachesDirectory() throws -> URL {
        guard let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw DataToFile.Errors.invalidFilePath
        }
        return directory
    }
}
