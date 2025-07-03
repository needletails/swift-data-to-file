# ``SwiftDTF``

SwiftDTF is a Swift package for robust, type-safe data-to-file operations on Apple platforms. It supports writing and reading files from `Data`, `[UInt8]`, and `ByteBuffer`, and provides utilities for file management and media saving.

## Overview

SwiftDTF makes it easy to:
- Write data to files in a safe, cross-platform way
- Read files and create temporary copies
- Remove files and clean up directories
- Work with a variety of data types, including SwiftNIO's `ByteBuffer`
- Save images and videos to the photo album (iOS) or via a save panel (macOS)

## Features
- Write files from `Data`, `[UInt8]`, or `ByteBuffer`
- Read files and create temporary copies
- Remove individual files or all files in a directory
- Remove temporary files
- Save media to the photo album (iOS) or via a save panel (macOS)
- Comprehensive error handling
- Cross-platform: macOS and iOS

## Usage

### Writing Data to a File

```swift
let data = "Hello, World!".data(using: .utf8)!
let filePath = try DataToFile.shared.generateFile(
    data: data,
    fileName: "greeting",
    fileType: "txt"
)
```

### Reading Data from a File

```swift
let (readData, tempURL) = try DataToFile.shared.generateData(from: "greeting.txt")
```

### Removing a File

```swift
try DataToFile.shared.removeItem(fileName: "greeting", fileType: "txt")
```

### Saving Media (iOS/macOS)

```swift
#if os(iOS)
try await DataToFile.shared.writeToPhotoAlbum(data: imageData, contentType: .png)
#endif
```

## Tutorials

- <doc:GettingStarted>

## Topics

### Essentials
- ``DataToFile``
- ``AllowedContentTypes``

### File Operations
- ``DataToFile/generateFile(data:fileName:filePath:directory:domainMask:fileType:)``
- ``DataToFile/generateFile(binary:fileName:filePath:directory:domainMask:fileType:)``
- ``DataToFile/generateFile(byteBuffer:fileName:filePath:directory:domainMask:fileType:)``
- ``DataToFile/generateData(from:)``
- ``DataToFile/removeItem(fileName:fileType:filePath:directory:domainMask:)``
- ``DataToFile/removeAllItems(filePath:directory:domainMask:)``
- ``DataToFile/removeItemFromTempDirectory(fileName:)``
- ``DataToFile/removeAllItemsFromTempDirectory()``

### Media Operations
- ``DataToFile/writeToPhotoAlbum(data:videoPath:contentType:)``

### Errors
- ``DataToFile/Errors`` 