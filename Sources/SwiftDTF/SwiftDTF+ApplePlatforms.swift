//
//  SwiftDTF+ApplePlatforms.swift
//  SwiftDTF
//
//  Created by Cole M on 8/7/23.
//

#if os(iOS)
import UIKit
import Photos
#elseif os(macOS)
import AppKit
#endif
#if os(iOS) || os(macOS)
import UniformTypeIdentifiers
#endif
import Foundation

extension DataToFile {
    #if os(iOS) || os(macOS)
    /// Saves media data to the photo album (iOS) or shows a save panel (macOS)
    ///
    /// - Parameters:
    ///   - data: The media data to save
    ///   - videoPath: The path to the video file (used for iOS video saving)
    ///   - contentType: The type of content being saved
    /// - Throws: `MediaSaverErrors` if the operation fails
    public func writeToPhotoAlbum(
        data: Data, 
        videoPath: String = "", 
        contentType: AllowedContentTypes = .png
    ) async throws {
        #if os(iOS)
        switch contentType {
        case .png, .jpeg, .jpg, .webp, .gif, .heic:
            try await saveImageToPhotoLibrary(data, contentType: contentType)
        case .mp4, .m4v, .mov, .quicktimeMovie, .appleProtectedMPEG4Video:
            let videoURL = try videoFileURL(videoPath: videoPath, data: data, contentType: contentType)
            let shouldRemoveTemp = videoURL.path.contains("_temp.")
            defer {
                if shouldRemoveTemp {
                    try? FileManager.default.removeItem(at: videoURL)
                }
            }
            try await saveVideoToPhotoLibrary(videoURL)
        default:
            throw MediaSaverErrors.unsupportedContentType
        }
        #elseif os(macOS)
        if let mediaURL = await showSavePanel() {
            try await saveMedia(data: data, path: mediaURL, contentTypes: contentType)
        } else {
            throw MediaSaverErrors.cancelled
        }
        #endif
    }
    #endif
    
    /// Errors that can occur during media saving operations
    private enum MediaSaverErrors: LocalizedError {
        case notSaved
        case unsupportedContentType
        case cancelled
        case unauthorized
        case invalidVideoFile
        
        public var errorDescription: String? {
            switch self {
            case .notSaved:
                return "Failed to save media"
            case .unsupportedContentType:
                return "Unsupported content type"
            case .cancelled:
                return "Operation was cancelled"
            case .unauthorized:
                return "Photo library access was not granted"
            case .invalidVideoFile:
                return "Video file is not available"
            }
        }
    }
    
    #if os(iOS)
    private func ensurePhotoAddAccess() async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            return
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard newStatus == .authorized || newStatus == .limited else {
                throw MediaSaverErrors.unauthorized
            }
        default:
            throw MediaSaverErrors.unauthorized
        }
    }

    private func saveImageToPhotoLibrary(_ data: Data, contentType: AllowedContentTypes) async throws {
        try await ensurePhotoAddAccess()
        guard UIImage(data: data) != nil else {
            throw MediaSaverErrors.notSaved
        }
        try await performPhotoLibraryChanges {
            let options = PHAssetResourceCreationOptions()
            options.uniformTypeIdentifier = contentType.uniformTypeIdentifier
            options.originalFilename = "SwiftDTF_\(UUID().uuidString).\(contentType.pathExtension)"
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: options)
        }
    }

    private func saveVideoToPhotoLibrary(_ fileURL: URL) async throws {
        try await ensurePhotoAddAccess()
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw MediaSaverErrors.invalidVideoFile
        }
        try await performPhotoLibraryChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }

    private func videoFileURL(videoPath: String, data: Data, contentType: AllowedContentTypes) throws -> URL {
        if let fileURL = normalizedFileURL(from: videoPath),
           FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return try data.writeDataToTempFileURL(
            name: "SwiftDTF_\(UUID().uuidString)",
            type: contentType.pathExtension
        )
    }

    private func normalizedFileURL(from pathOrURLString: String) -> URL? {
        let trimmed = pathOrURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.isFileURL {
            return url
        }
        if trimmed.hasPrefix("/file:/") {
            return URL(fileURLWithPath: "/" + trimmed.dropFirst("/file:/".count))
        }
        return URL(fileURLWithPath: trimmed)
    }

    private func performPhotoLibraryChanges(_ changes: @escaping () -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            PHPhotoLibrary.shared().performChanges(changes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MediaSaverErrors.notSaved)
                }
            }
        }
    }
    #elseif os(macOS)
    
    /// Shows a save panel for selecting where to save media files
    ///
    /// - Returns: The selected URL or nil if cancelled
    @MainActor
    private func showSavePanel() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [
            .png,
            .jpeg,
            .gif,
            .heic,
            .webP,
            .mpeg4Movie,
            .quickTimeMovie,
            .movie,
        ]
        
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save your media"
        savePanel.message = "Choose a folder and a name to store the media file."
        savePanel.nameFieldLabel = "File name:"
        
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
    
    /// Saves media data to the specified path
    ///
    /// - Parameters:
    ///   - data: The media data to save
    ///   - path: The destination URL
    ///   - contentTypes: The type of content being saved
    /// - Throws: `MediaSaverErrors` if the operation fails
    private func saveMedia(data: Data, path: URL, contentTypes: AllowedContentTypes) async throws {
        switch contentTypes {
        case .jpeg, .jpg, .png, .webp, .gif, .heic, .mp4, .m4v, .mov, .quicktimeMovie, .appleProtectedMPEG4Video:
            try data.write(to: path, options: Data.WritingOptions.atomic)
        default:
            throw MediaSaverErrors.unsupportedContentType
        }
    }
    #endif
}

#if os(macOS)
func _swiftDTFEncodePNG(image: NSImage) -> Data? {
    guard let tiffData = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiffData) else {
        return nil
    }
    return rep.representation(using: .png, properties: [:])
}

func _swiftDTFEncodeJPEG(image: NSImage, quality: CGFloat) -> Data? {
    let clampedQuality = max(0, min(1, quality))
    guard let tiffData = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiffData) else {
        return nil
    }
    return rep.representation(using: .jpeg, properties: [.compressionFactor: clampedQuality])
}
#endif

/// Supported content types for media operations
public enum AllowedContentTypes: String, CaseIterable, Sendable {
    case data
    case jpeg
    case jpg
    case appleProtectedMPEG4Audio
    case appleProtectedMPEG4Video
    case epub
    case pdf
    case png
    case webp
    case gif
    case heic
    case mp3
    case mp4
    case m4v
    case webm
    case mov
    case quicktimeMovie = "com.apple.quicktime-movie"
    
    /// The file extension for this content type
    public var pathExtension: String {
        switch self {
        case .data:
            return "data"
        case .jpg:
            return "jpg"
        case .jpeg:
            return "jpeg"
        case .appleProtectedMPEG4Audio:
            return "m4a"
        case .appleProtectedMPEG4Video:
            return "m4v"
        case .epub:
            return "epub"
        case .pdf:
            return "pdf"
        case .png:
            return "png"
        case .webp:
            return "webp"
        case .gif:
            return "gif"
        case .heic:
            return "heic"
        case .mp3:
            return "mp3"
        case .mp4:
            return "mp4"
        case .m4v:
            return "m4v"
        case .webm:
            return "webm"
        case .mov, .quicktimeMovie:
            return "mov"
        }
    }

    #if os(iOS)
    var uniformTypeIdentifier: String {
        switch self {
        case .jpg, .jpeg:
            return UTType.jpeg.identifier
        case .png:
            return UTType.png.identifier
        case .webp:
            return UTType.webP.identifier
        case .gif:
            return UTType.gif.identifier
        case .heic:
            return UTType.heic.identifier
        case .mp4:
            return UTType.mpeg4Movie.identifier
        case .m4v, .appleProtectedMPEG4Video:
            return "com.apple.m4v-video"
        case .mov, .quicktimeMovie:
            return UTType.quickTimeMovie.identifier
        default:
            return UTType.data.identifier
        }
    }
    #endif
    
    /// Creates an AllowedContentTypes from a raw string value
    ///
    /// - Parameter rawValue: The raw string value
    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "data":
            self = .data
        case "jpg":
            self = .jpg
        case "jpeg":
            self = .jpeg
        case "appleprotectedmpeg4audio":
            self = .appleProtectedMPEG4Audio
        case "appleprotectedmpeg4video":
            self = .appleProtectedMPEG4Video
        case "epub":
            self = .epub
        case "pdf":
            self = .pdf
        case "png":
            self = .png
        case "webp":
            self = .webp
        case "gif":
            self = .gif
        case "heic", "heif":
            self = .heic
        case "mp3":
            self = .mp3
        case "mp4":
            self = .mp4
        case "m4v":
            self = .m4v
        case "webm":
            self = .webm
        case "mov", "quicktimemovie":
            self = .mov
        default:
            return nil
        }
    }
    
    /// Creates an AllowedContentTypes from a file extension
    ///
    /// - Parameter fileExtension: The file extension (without the dot)
    public init?(fileExtension: String) {
        self.init(rawValue: fileExtension)
    }
}
