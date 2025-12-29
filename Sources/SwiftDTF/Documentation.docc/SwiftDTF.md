# ``SwiftDTF``

SwiftDTF is a Swift package for robust, type-safe data-to-file operations on Apple platforms. It supports writing and reading files from `Data`, `[UInt8]`, and `ByteBuffer`, and provides utilities for file management and media saving.

## Overview

SwiftDTF makes it easy to:
- Write data to files in a safe, cross-platform way
- Read files and create temporary copies
- Work with file URLs and directory URLs directly
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

Note (iOS): Saving to the Photos library may require adding the appropriate usage description to your app's `Info.plist` (for example, `NSPhotoLibraryAddUsageDescription`). The save is initiated via system APIs and does not provide a completion callback for when the write has fully finished.
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
- ``DataToFile/generateDataFromURL(_:)``
- ``DataToFile/generateData(fromFileURL:)``
- ``DataToFile/readDataAndStageTemp(fromFileURL:)``
- ``DataToFile/readDataAndStageTemp(from:)``
- ``DataToFile/generateFile(data:to:name:fileExtension:)``
- ``DataToFile/removeItem(fileName:fileType:filePath:directory:domainMask:)``
- ``DataToFile/removeAllItems(filePath:directory:domainMask:)``
- ``DataToFile/removeItemFromTempDirectory(fileName:)``
- ``DataToFile/removeAllItemsFromTempDirectory()``

### Data Helpers
- ``Data/writeDataToTempFile(name:type:)``
- ``Data/writeDataToTempFileURL(name:type:)``

### Media Operations
- ``DataToFile/writeToPhotoAlbum(data:videoPath:contentType:)``

### Errors
- ``DataToFile/Errors`` 