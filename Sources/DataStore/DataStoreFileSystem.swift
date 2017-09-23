//
//  DataStoreFileSystem.swift
//  DataStore
//
//  Created by Bernardo Breder on 26/12/16.
//
//

import Foundation

#if SWIFT_PACKAGE
    import FileSystem
    import Json
    import Regex
    import Optional
#endif

public enum DataStoreFileSystemError: Error {
    case writeSequenceJsonToData
    case writePageJsonToData
    case writeBackupJsonToData
}

open class DataStoreFileSystem {
    
    let folder: Folder
    
    public init(folder: Folder) {
        self.folder = folder
    }
    
    public func readTables() throws -> [String] {
        let regex = Regex("^(.*)\\.([0-9]+).db$", groupCount: 1)
        let names = try folder.listFiles().map {regex.matches($0.name)}.notnil().map {$0[1]}
        return Set<String>(names).map {$0}
    }
    
    public func readPages(name: String) throws -> [Int] {
        let regex = Regex("^\(name).([0-9]+).db$", groupCount: 1)
        let files: [File] = try folder.listFiles()
        let matches = files.lazy.map {regex.matches($0.name)}.notnil()
        let pages = matches.map {$0[1]}.map {Int($0)}.notnil()
        return Set<Int>(pages).map{$0}
    }
    
    public func readSequence() throws -> Json {
        let file = folder.getFile("sequence.db")
        guard file.exist else { return Json([:]) }
        return try Json(data: file.read())
    }
    
    public func readPage(name: String, page: Int) throws -> Json {
        let file = folder.getFile(fileName(name: name, page: page))
        guard file.exist else { return Json([]) }
        return try Json(data: folder.getFile(fileName(name: name, page: page)).read())
    }
    
    public func readBackup() throws -> Json? {
        let file = folder.getFile("backup.db")
        guard file.exist else { return nil }
        let data = try file.read()
        let json = try Json(data: data)
        return json
    }
    
    public func writeSequence(json: Json) throws {
        guard let data = try? json.data() else { throw DataStoreFileSystemError.writeSequenceJsonToData }
        try folder.getFile("sequence.db").write(data: data)
    }
    
    public func writePage(name: String, page: Int, json: Json) throws {
        guard let data = try? json.data() else { throw DataStoreFileSystemError.writePageJsonToData }
        try folder.getFile(fileName(name: name, page: page)).write(data: data)
    }
    
    public func writeBackup(json: Json) throws {
        guard let data = try? json.data() else { throw DataStoreFileSystemError.writeBackupJsonToData }
        try folder.getFile("backup.db").write(data: data)
    }
    
    public func deleteBackup() throws {
        try folder.getFile("backup.db").delete()
    }
    
    internal func fileName(name: String, page: Int) -> String {
        return name + "." + String(page) + ".db"
    }
    
}
