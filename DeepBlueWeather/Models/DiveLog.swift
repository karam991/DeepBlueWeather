//
//  DiveLog.swift
//  DeepBlueWeather
//
//  What actually happened on a dive. Stored on the DivePlan in Firestore;
//  photos are kept on the device.
//

import Foundation
import UIKit

struct DiveLog: Codable, Equatable {
    var actualDepth: Int
    var actualDuration: Int
    var waterTemperature: Double?
    var visibility: Int?          // metres underwater
    var rating: Int               // 1–5
    var notes: String
    var buddy: String?
    var loggedAt: Date = Date()
}

/// Saves dive photos as JPEGs in Documents/DivePhotos/<planId>/.
enum DivePhotoStore {
    private static func folder(for planId: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("DivePhotos/\(planId)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func photoURLs(for planId: String) -> [URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: folder(for: planId), includingPropertiesForKeys: [.creationDateKey])) ?? []
        return urls.filter { $0.pathExtension == "jpg" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    @discardableResult
    static func save(_ image: UIImage, for planId: String) -> URL? {
        // Downscale so photos stay small on disk.
        let maxSide: CGFloat = 1600
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let data = resized.jpegData(compressionQuality: 0.8) else { return nil }
        let name = "\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        let url = folder(for: planId).appendingPathComponent(name)
        try? data.write(to: url)
        return url
    }

    static func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    static func deleteAll(for planId: String) {
        try? FileManager.default.removeItem(at: folder(for: planId))
    }
}
