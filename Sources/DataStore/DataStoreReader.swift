//
//  DataStoreWriter.swift
//  DataStore
//
//  Created by Bernardo Breder on 23/12/16.
//
//

import Foundation

#if SWIFT_PACKAGE
    import AtomicValue
    import Json
#endif

public class DataStoreReader {
    
    weak var lock: RWLock?
    
    let fs: DataStoreFileSystem
    
    var entrys: [String: [Int: DataStoreChanges]] = [:]
    
    public init(lock: RWLock, fileSystem fs: DataStoreFileSystem) {
        self.lock = lock
        self.fs = fs
    }
    
    public func list() throws -> [String] {
        var result: Set<String> = Set(try fs.readTables().map({$0}))
        for key in entrys.keys { result.insert(key) }
        return result.map{$0}
    }
    
    public func list(name: String) throws -> [Int] {
        var result: Set<Int> = Set(try fs.readPages(name: name).map({$0}))
        if let entry = entrys[name] {
            for key in entry.keys { result.insert(key) }
        }
        return result.map{$0}
    }
    
    public func list<T>(name: String, decode: (DataStoreRecord) throws -> T) throws -> [T] {
        return try list(name: name).flatMap { page in try load(name: name, page: page).values.map{$0}.map(decode) }
    }
    
    public func list<T>(name: String, page: Int, filter: (DataStoreFileEntry, DataStoreRecord) throws -> Bool, decode: (DataStoreRecord) throws -> T) throws -> [T] {
        return try load(name: name, page: page).filter { e in (try? filter(e.key, e.value)) ?? false }.map { e in try decode(e.value) }
    }
    
    public func list(name: String, page: Int) throws -> [Int] {
        return try load(name: name, page: page).map { e in e.key.id }
    }

    public func deep<T,F>(name: String, page: (F) -> Int, filter: @escaping (DataStoreFileEntry, DataStoreRecord, F) throws -> Bool, decode: @escaping (DataStoreRecord) throws -> T, children: (T) throws -> [F], startWith: [F]) throws -> [T] {
        var result: [T] = [], parents = startWith
        var i = 0; while i < parents.count {
            let parent = parents[i]
            for item in try list(name: name, page: page(parent), filter: { i, r in try filter(i, r, parent) }, decode: { r in try decode(r) }) {
                parents.append(contentsOf: (try? children(item)) ?? [F]())
                result.append(item)
            }
            i += 1
        }
        return result
    }

    public func load(name: String, page: Int) throws -> [DataStoreFileEntry: DataStoreRecord] {
        guard let jsonPage = try? fs.readPage(name: name, page: page) else { throw DataStoreReaderError.canNotReadPage(name, page) }
        guard let jsonArray = jsonPage.array else { throw DataStoreReaderError.pageNotAArrayOfJson(name, page) }
        var records = try jsonArray.native.dic { (json: Json) -> (DataStoreFileEntry, DataStoreRecord) in
            guard let id = json["id"].int else { throw DataStoreReaderError.pageNotACorrentJson(name, page) }
            guard json["data"].exists else { throw DataStoreReaderError.pageNotACorrentJson(name, page) }
            return (DataStoreFileEntry(id: id), DataStoreRecord(json: json["data"]))
        }
        if let entry = entrys[name], let entryPage = entry[page] {
            for change in entryPage.changes {
                switch change.type {
                case .delete:
                    records.removeValue(forKey: DataStoreFileEntry(id: change.id))
                case .update:
                    let key = DataStoreFileEntry(id: change.id)
                    guard let _ = records[key] else { throw DataStoreReaderError.canNotLoadPageAndMergeInserts }
                    records[key] = change.record
                case .insert:
                    let key = DataStoreFileEntry(id: change.id)
                    guard records[key] == nil else { throw DataStoreReaderError.canNotLoadPageAndMergeInserts }
                    records[key] = change.record
                }
            }
        }
        return records
    }
    
    public func get<T>(name: String, page: Int, id: Int, decode: @escaping (DataStoreRecord) throws -> T) throws -> T {
        for entry in try load(name: name, page: page) {
            if entry.key.id == id { return try decode(entry.value) }
        }
        throw DataStoreReaderError.jsonNotFound(name, page, id)
    }
    
    public func exist(name: String, page: Int, id: Int) throws -> Bool {
        for entry in try load(name: name, page: page) {
            if entry.key.id == id { return true }
        }
        return false
    }
    
    public func exist<T>(name: String, page: Int, id: Int, decode: @escaping (DataStoreRecord) throws -> T) throws -> T? {
        for entry in try load(name: name, page: page) {
            if entry.key.id == id { return try decode(entry.value) }
        }
        return nil
    }
    
    public func get<T>(name: String, page: Int, filter: (DataStoreFileEntry, DataStoreRecord) throws -> Bool, decode: @escaping (DataStoreRecord) throws -> T) throws -> T? {
        for entry in try load(name: name, page: page) {
            if let bool = try? filter(entry.key, entry.value), bool { return try decode(entry.value) }
        }
        return nil
    }
    
    internal func readSequence() throws -> [String: Int] {
        return try fs.readSequence().dicOrSet
            .intValues.orThrow(DataStoreWriterError.sequenceFileNotAJsonDic)
    }
    
    public func sequence(name: String) throws -> Int {
        return try readSequence()[name] ?? 0
    }
    
    public func close() {
        lock?.unlock()
    }
    
}

public struct DataStoreFileEntry: Hashable {
    
    public let id: Int
    
    public var hashValue: Int {
        return id
    }
    
    public static func ==(lhs: DataStoreFileEntry, rhs: DataStoreFileEntry) -> Bool {
        return lhs.id == rhs.id
    }
    
}

public enum DataStoreReaderError: Error {
    case pageNotFound(String, Int)
    case canNotReadPage(String, Int)
    case pageNotAArrayOfJson(String, Int)
    case pageNotACorrentJson(String, Int)
    case jsonNotFound(String, Int, Int)
    case jsonSeachNotFound(String, Int)
    case canNotLoadPageAndMergeInserts
}
