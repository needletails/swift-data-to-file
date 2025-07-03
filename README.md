# SwiftDTF (Swift Data To File)

A Swift library for handling data-to-file operations with support for various data types and platforms. SwiftDTF provides a simple, type-safe interface for writing data to files, managing file operations, and handling different data formats including `Data`, `[UInt8]`, and `ByteBuffer`.

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2018%2B%20%7C%20macOS%2015%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Multiple Data Types**: Support for `Data`, `[UInt8]`, and `ByteBuffer`
- **Cross-Platform**: Works on macOS and iOS
- **File Management**: Create, read, and delete files with ease
- **Temporary Files**: Built-in support for temporary file operations
- **Media Support**: Save media files to photo album (iOS) or show save panel (macOS)
- **Error Handling**: Comprehensive error handling with descriptive messages
- **Type Safety**: Fully type-safe API with proper error handling

## Requirements

- Swift 6.0+
- macOS 15.0+ / iOS 18.0+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add SwiftDTF to your project using Swift Package Manager:

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/needletails/swift-data-to-file.git`
3. Select the version you want to use
4. Click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/needletails/swift-data-to-file.git", from: "1.0.0")
]
```

## Quick Start

```swift
import SwiftDTF

let dataToFile = DataToFile.shared

// Write text data to a file
let textData = "Hello, World!".data(using: .utf8)!
let filePath = try dataToFile.generateFile(
    data: textData,
    fileName: "greeting",
    fileType: "txt"
)
print("File saved to: \(filePath)")

// Read data from a file
let (readData, tempURL) = try dataToFile.generateData(from: "greeting.txt")
if let data = readData {
    let text = String(data: data, encoding: .utf8)
    print("Read text: \(text ?? "Unable to decode")")
}
```

## Usage

### Basic File Operations

#### Writing Data to Files

```swift
let dataToFile = DataToFile.shared

// Write Data
let data = "Hello, World!".data(using: .utf8)!
let path1 = try dataToFile.generateFile(
    data: data,
    fileName: "example",
    fileType: "txt"
)

// Write binary data
let binary: [UInt8] = [72, 101, 108, 108, 111] // "Hello"
let path2 = try dataToFile.generateFile(
    binary: binary,
    fileName: "binary_example",
    fileType: "bin"
)

// Write ByteBuffer
var byteBuffer = ByteBuffer()
byteBuffer.writeString("Hello from ByteBuffer")
let path3 = try dataToFile.generateFile(
    byteBuffer: byteBuffer,
    fileName: "buffer_example",
    fileType: "dat"
)
```

#### Reading Data from Files

```swift
// Read data and create temporary copy
let (data, tempURL) = try dataToFile.generateData(from: "example.txt")

if let fileData = data {
    let text = String(data: fileData, encoding: .utf8)
    print("File content: \(text ?? "Unable to decode")")
}

if let tempFileURL = tempURL {
    print("Temporary file created at: \(tempFileURL.path)")
}
```

#### File Management

```swift
// Remove a specific file
try dataToFile.removeItem(fileName: "example", fileType: "txt")

// Remove all files from the Media directory
try dataToFile.removeAllItems()

// Remove a specific temporary file
try dataToFile.removeItemFromTempDirectory(fileName: "example_temp.txt")

// Remove all temporary files
try dataToFile.removeAllItemsFromTempDirectory()
```

### Advanced Usage

#### Custom File Paths

```swift
// Use custom directory structure
let customPath = try dataToFile.generateFile(
    data: data,
    fileName: "custom",
    filePath: "MyApp/Documents",
    fileType: "txt"
)
```

#### Temporary Files

```swift
// Write data to temporary file
let tempPath = try data.writeDataToTempFile(name: "temp_example", type: "txt")
print("Temporary file: \(tempPath)")
```

### Media Operations (iOS/macOS)

#### Saving to Photo Album (iOS)

```swift
#if os(iOS)
// Save image to photo album
let imageData = UIImage(named: "example")?.pngData()
if let data = imageData {
    try await dataToFile.writeToPhotoAlbum(
        data: data,
        contentType: .png
    )
}

// Save video to photo album
try await dataToFile.writeToPhotoAlbum(
    data: videoData,
    videoPath: "/path/to/video.mov",
    contentType: .mov
)
#endif
```

#### Save Panel (macOS)

```swift
#if os(macOS)
// Show save panel for media files
try await dataToFile.writeToPhotoAlbum(
    data: imageData,
    contentType: .png
)
#endif
```

### Content Types

SwiftDTF supports various content types:

```swift
// Supported content types
let types: [AllowedContentTypes] = [
    .png, .jpeg, .jpg, .mov, .mp3, .pdf, .epub,
    .appleProtectedMPEG4Audio, .appleProtectedMPEG4Video
]

// Get file extension
let extension = AllowedContentTypes.png.pathExtension // "png"

// Create from file extension
let contentType = AllowedContentTypes(fileExtension: "png") // .png

// Create from raw value
let contentType2 = AllowedContentTypes(rawValue: "jpeg") // .jpeg
```

## Error Handling

SwiftDTF provides comprehensive error handling:

```swift
do {
    let path = try dataToFile.generateFile(
        data: data,
        fileName: "test",
        fileType: "txt"
    )
    print("Success: \(path)")
} catch DataToFile.Errors.fileNotFound {
    print("File not found")
} catch DataToFile.Errors.writeFailed {
    print("Failed to write file")
} catch DataToFile.Errors.invalidFilePath {
    print("Invalid file path")
} catch {
    print("Unexpected error: \(error)")
}
```

### Available Errors

- `fileComponentTooSmall`: File component is too small
- `fileNameMissing`: File name is missing
- `fileTypeMissing`: File type is missing
- `invalidFilePath`: Invalid file path
- `fileNotFound`: File not found
- `writeFailed`: Failed to write file
- `readFailed`: Failed to read file

## API Reference

### DataToFile

The main struct providing file operations.

#### Methods

- `generateFile(data:fileName:filePath:directory:domainMask:fileType:)` - Write Data to file
- `generateFile(binary:fileName:filePath:directory:domainMask:fileType:)` - Write binary data to file
- `generateFile(byteBuffer:fileName:filePath:directory:domainMask:fileType:)` - Write ByteBuffer to file
- `generateData(from:)` - Read data from file
- `removeItem(fileName:fileType:filePath:directory:domainMask:)` - Remove specific file
- `removeAllItems(filePath:directory:domainMask:)` - Remove all files from directory
- `removeItemFromTempDirectory(fileName:)` - Remove specific temporary file
- `removeAllItemsFromTempDirectory()` - Remove all temporary files

### Data Extensions

- `writeDataToFile(fileName:fileType:filePath:directory:domainMask:)` - Write Data to file
- `writeDataToTempFile(name:type:)` - Write Data to temporary file

### AllowedContentTypes

Enumeration of supported content types with file extension mapping.

## Documentation

SwiftDTF includes comprehensive DocC documentation that provides detailed API reference, tutorials, and examples.

### Viewing Documentation

#### In Xcode
1. Open the SwiftDTF package in Xcode
2. Go to **Product** → **Build Documentation**
3. The documentation will open in Xcode's documentation viewer

### Documentation Contents
- **API Reference**: Complete documentation for all public APIs
- **Tutorials**: Step-by-step guides for common use cases
- **Examples**: Code samples and best practices
- **Error Handling**: Detailed information about error types and handling

## Testing

Run the test suite:

```bash
swift test
```

The test suite includes:
- Unit tests for all public APIs
- Error handling tests
- Performance tests
- Cross-platform compatibility tests

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please:

1. Check the [DocC documentation](#documentation) for detailed API reference and tutorials
2. Search [existing issues](https://github.com/needletails/swift-data-to-file/issues)
3. Create a new issue with a detailed description

## Changelog

### Version 1.0.0
- Initial release
- Support for Data, [UInt8], and ByteBuffer
- File creation, reading, and deletion
- Temporary file operations
- Media saving for iOS and macOS
- Comprehensive error handling
- Full test coverage
