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
import UniformTypeIdentifiers
import NeedletailMediaKit

extension DataToFile {
    
    public func writeToPhotoAlbum(data: Data, videoPath: String = "", contentType: AllowedContentTypes = .png) async throws {
#if os(iOS)
        switch contentType {
        case .png:
            guard let imageData = UIImage(data: data) else { throw MediaSaverErrors.notSaved }
            UIImageWriteToSavedPhotosAlbum(imageData, self, nil, nil)
        case .movie:
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
        case .movie:
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

public enum AllowedContentTypes {
    case data, jpeg, appleProtectedMPEG4Audio, appleProtectedMPEG4Video, epub, pdf, png, mp3, movie
}
