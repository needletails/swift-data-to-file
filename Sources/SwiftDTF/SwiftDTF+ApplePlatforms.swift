//
//  SwiftDTF+ApplePlatforms.swift
//  
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
    public func writeToPhotoAlbum(data: Data, videoPath: String = "", contentType: AllowedContentTypes = .png) async throws {
#if os(iOS)
        switch contentType {
        case .png, .jpeg, .jpg:
            guard let imageData = UIImage(data: data) else { throw MediaSaverErrors.notSaved }
            UIImageWriteToSavedPhotosAlbum(imageData, self, nil, nil)
        case .mov:
            UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, nil, nil)
        default:
            break
        }
#elseif os(macOS)
        if let mediaURL = await showSavePanel() {
            try await saveMedia(data: data, path: mediaURL, contentTypes: contentType)
        } else {
            throw MediaSaverErrors.notSaved
        }
#endif
    }
#endif
    private enum MediaSaverErrors: Error {
        case notSaved
    }
    
#if os(iOS)

#elseif os(macOS)
    
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
        savePanel.title = "Save your image"
        savePanel.message = "Choose a folder and a name to store the image."
        savePanel.nameFieldLabel = "Image file name:"
        
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
    
    private func saveMedia(data: Data, path: URL, contentTypes: AllowedContentTypes) async throws {
        switch contentTypes {
        case .jpeg:
            guard let image = NSImage(data: data) else { throw MediaSaverErrors.notSaved }
            guard let jpegData = image.jpegData(size: image.size) else { throw MediaSaverErrors.notSaved }
            do {
                try jpegData.write(to: path)
            } catch {
                throw error
            }
        case .png:
            guard let image = NSImage(data: data) else { throw MediaSaverErrors.notSaved }
            guard let pngData = image.pngData(size: image.size) else { throw MediaSaverErrors.notSaved }
            do {
                try pngData.write(to: path)
            } catch {
                throw error
            }
        case .mov:
            do {
                try data.write(to: path, options: .atomic)
            } catch {
                throw error
            }
        default:
            break
        }
    }
#endif
}

public enum AllowedContentTypes: String {
    case data, jpeg, jpg, appleProtectedMPEG4Audio, appleProtectedMPEG4Video, epub, pdf, png, mp3, mov
    case quicktimeMovie = "com.apple.quicktime-movie"
    
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
    
    public init?(rawValue: String) {
        switch rawValue {
        case "data":
            self = .data
        case "jpg":
            self = .jpg
        case "jpeg":
            self = .jpeg
        case "appleProtectedMPEG4Audio":
            self = .appleProtectedMPEG4Audio
        case "appleProtectedMPEG4Video":
            self = .appleProtectedMPEG4Video
        case "epub":
            self = .epub
        case "pdf":
            self = .pdf
        case "png":
            self = .png
        case "mp3":
            self = .mp3
        case "mov", "quicktimeMovie":
            self = .mov
        default:
            self = .png
        }
    }
}
