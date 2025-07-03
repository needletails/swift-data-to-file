//
//  SwiftDTF+ApplePlatforms.swift
//  SwiftDTF
//
//  Created by Cole M on 8/7/23.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
import AppKit
#endif
#if os(iOS) || os(macOS)
import UniformTypeIdentifiers
import NeedleTailMediaKit
#endif

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
        case .png, .jpeg, .jpg:
            guard let imageData = UIImage(data: data) else { 
                throw MediaSaverErrors.notSaved 
            }
            UIImageWriteToSavedPhotosAlbum(imageData, self, nil, nil)
        case .mov:
            UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, nil, nil)
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
        
        public var errorDescription: String? {
            switch self {
            case .notSaved:
                return "Failed to save media"
            case .unsupportedContentType:
                return "Unsupported content type"
            case .cancelled:
                return "Operation was cancelled"
            }
        }
    }
    
    #if os(iOS)
    // iOS-specific implementations can be added here
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
        case .jpeg:
            guard let image = NSImage(data: data) else { 
                throw MediaSaverErrors.notSaved 
            }
            guard let jpegData = image.jpegData(maxSize: image.size) else { 
                throw MediaSaverErrors.notSaved 
            }
            try jpegData.write(to: path)
        case .png:
            guard let image = NSImage(data: data) else { 
                throw MediaSaverErrors.notSaved 
            }
            guard let pngData = image.pngData(size: image.size) else { 
                throw MediaSaverErrors.notSaved 
            }
            try pngData.write(to: path)
        case .mov:
            try data.write(to: path, options: .atomic)
        default:
            throw MediaSaverErrors.unsupportedContentType
        }
    }
    #endif
}

/// Supported content types for media operations
public enum AllowedContentTypes: String, CaseIterable {
    case data
    case jpeg
    case jpg
    case appleProtectedMPEG4Audio
    case appleProtectedMPEG4Video
    case epub
    case pdf
    case png
    case mp3
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
        case .mp3:
            return "mp3"
        case .mov, .quicktimeMovie:
            return "mov"
        }
    }
    
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
        case "mp3":
            self = .mp3
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
