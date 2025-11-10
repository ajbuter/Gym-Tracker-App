//  Persistence.swift
//  Lift App
//
//  Created by Aiden Buter on 11/6/25.
//

//
// =========================
// File: Persistence.swift
// =========================

import Foundation

/// Simple file-based persistence using Codable and JSON files in Documents directory.
final class PersistenceManager {
    static let shared = PersistenceManager()
    private init() {}

    let fm = FileManager.default

    func documentsURL(filename: String) -> URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(filename)
    }

    func save<T: Encodable>(_ value: T, filename: String) throws {
        let url = documentsURL(filename: filename)
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: [.atomicWrite])
    }

    func load<T: Decodable>(_ type: T.Type, filename: String) throws -> T {
        let url = documentsURL(filename: filename)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func exists(filename: String) -> Bool {
        fm.fileExists(atPath: documentsURL(filename: filename).path)
    }
}
