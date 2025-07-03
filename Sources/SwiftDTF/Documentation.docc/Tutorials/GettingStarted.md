# Getting Started with SwiftDTF

Learn how to use SwiftDTF to write, read, and manage files in your Swift projects.

## Introduction

SwiftDTF makes it easy to work with files and data on Apple platforms. This tutorial will guide you through the basics of writing and reading files, as well as managing file storage.

## Step 1: Add SwiftDTF to Your Project

Add SwiftDTF to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/needletails/swift-data-to-file.git", from: "1.0.0")
```

## Step 2: Import SwiftDTF

```swift
import SwiftDTF
```

## Step 3: Write Data to a File

```swift
let data = "Hello, DocC!".data(using: .utf8)!
let filePath = try DataToFile.shared.generateFile(
    data: data,
    fileName: "docc-example",
    fileType: "txt"
)
print("File saved at: \(filePath)")
```

## Step 4: Read Data from a File

```swift
let (readData, tempURL) = try DataToFile.shared.generateData(from: "docc-example.txt")
if let data = readData {
    print(String(data: data, encoding: .utf8) ?? "Unable to decode")
}
```

## Step 5: Remove a File

```swift
try DataToFile.shared.removeItem(fileName: "docc-example", fileType: "txt")
```

## Next Steps

- Explore all file operations in ``DataToFile``
- Learn about supported content types in ``AllowedContentTypes``
- See how to save media to the photo album (iOS) or via a save panel (macOS)

For more, see the <doc:SwiftDTF> documentation. 
