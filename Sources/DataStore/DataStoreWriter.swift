//
//  DataStoreWriter.swift
//  DataStore
//
//  Created by Bernardo Breder on 23/12/16.
//
//

import Foundation

#if SWIFT_PACKAGE
    import FileSystem
    import AtomicValue
    import Json
#endif

public enum DataStoreWriterError: Error {
    case writerClosed
    case sequenceNotFound(String)
    case createSequenceFile
    case sequenceFileNotAJsonDic
    case sequenceItemValueIsNotAValue(String)
    case pageFileNotAJsonArray(String, Int)
    case entryHasNotId(String, Int)
    case restoreNotWorking
}

public enum DataStoreChangeType {
    case delete
    case update
    case insert
}

public struct DataStoreChange {
    
    public let type: DataStoreChangeType
    
    public let id: Int
    
    public let record: DataStoreRecord
    
}

public class DataStoreChanges {
    
    var changes: [DataStoreChange] = []
    
    public init() {
    }
    
}

public class DataStoreWriter: DataStoreReader {
    
    internal var id: [String: ()] = [:]
    
    internal var sequences: [String: Int]?
    
    public var dones: [() -> Void] = []
    
    public var reverts: [() -> Void] = []
    
    internal let backup: DataStoreBackup
    
    public override init(lock: RWLock, fileSystem fs: DataStoreFileSystem) {
        self.backup = DataStoreBackup(fileSystem: fs)
        super.init(lock: lock, fileSystem: fs)
    }
    
    public override func sequence(name: String) throws -> Int {
        var seqs = try sequences ?? readSequence()
        var sequence = seqs[name] ?? 0
        sequence += 1
        seqs[name] = sequence
        sequences = seqs
        backup.sequences = sequences
        return sequence
    }
    
    public func insert(name: String, page: Int, id: Int, record: DataStoreRecord) {
        var pages = entrys[name] ?? [:]
        let value = pages[page] ?? DataStoreChanges()
        value.changes.append(DataStoreChange(type: .insert, id: id, record: record))
        pages[page] = value
        entrys[name] = pages
        backup.changed(name: name, page: page)
    }
    
    public func delete(name: String, page: Int, id: Int) {
        var pages = entrys[name] ?? [:]
        let value = pages[page] ?? DataStoreChanges()
        value.changes.append(DataStoreChange(type: .delete, id: id, record: DataStoreRecord(json: Json())))
        pages[page] = value
        entrys[name] = pages
        backup.changed(name: name, page: page)
    }
    
    public func update(name: String, page: Int, id: Int, record: DataStoreRecord) {
        var pages = entrys[name] ?? [:]
        let value = pages[page] ?? DataStoreChanges()
        value.changes.append(DataStoreChange(type: .update, id: id, record: record))
        pages[page] = value
        entrys[name] = pages
        backup.changed(name: name, page: page)
    }
    
    public func commit() throws {
        do {
            guard sequences != nil || !entrys.isEmpty else { return }
            try fs.writeBackup(json: backup.json())
            guard let _ = try? DataStoreRestore(fileSystem: fs) else { throw DataStoreWriterError.restoreNotWorking }
            try sequences.peek({ s in try fs.writeSequence(json: Json(s)) })
            for name in try self.changes() {
                for page in name.value {
                    try fs.writePage(name: name.key, page: page.key, json: page.value)
                }
            }
            try fs.deleteBackup()
        } catch let e {
            try DataStoreRestore(fileSystem: fs).apply()
            throw e
        }
    }
    
    public func changes() throws -> [String: [Int: Json]] {
        var result: [String: [Int: Json]] = [:]
        for name in entrys {
            var dic: [Int: Json] = [:]
            for page in name.value {
                let entry = try load(name: name.key, page: page.key).sorted(by: { a, b in a.key.id <= b.key.id })
                dic[page.key] = try Json(entry.map { e in Json(["id": e.key.id, "data": e.value.json]) })
            }
            result[name.key] = dic
        }
        return result
    }
    
}
