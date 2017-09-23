//
//  DataStoreReadOnlyTests.swift
//  DataStore
//
//  Created by Bernardo Breder on 31/12/16.
//
//

import XCTest
@testable import Json
@testable import FileSystem
@testable import DataStore

class DataStoreReadOnlyTests: XCTestCase {
    
    var fs: MemoryFileSystem!
    
    var dfs: ReadOnlyDataStoreFileSystem!
    
    override func setUp() {
        fs = MemoryFileSystem()
        dfs = ReadOnlyDataStoreFileSystem(folder: fs.home())
    }
    
    func testPageConnection() throws {
        let db = try MyDataSetStore(fileSystem: dfs)
        defer { db.close() }
        try db.write { wdb in
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "A", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "B", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "C", phones: []))
        }
        dfs.pageWorking = false
        XCTAssertNil(try? db.write { wdb in
            try wdb.person.update(Person(id: 2, name: "b", phones: []))
            })
        XCTAssertNil(try? db.write { wdb in
            try wdb.person.update(Person(id: 2, name: "b", phones: []))
            })
        dfs.pageWorking = true
        try db.read { rdb in
            XCTAssertEqual("A", try rdb.person.get(1).name)
            XCTAssertEqual("B", try rdb.person.get(2).name)
            XCTAssertEqual("C", try rdb.person.get(3).name)
        }
    }
    
    func testPageConnections() throws {
        try MyDataSetStore(fileSystem: dfs) { db in try db.write { wdb in
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "A", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "B", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "C", phones: []))
            } }
        dfs.pageWorking = false
        XCTAssertNil(try? MyDataSetStore(fileSystem: dfs) { db in try db.write { wdb in
            try wdb.person.update(Person(id: 2, name: "b", phones: []))
            } })
        XCTAssertNil(try? MyDataSetStore(fileSystem: dfs) { db in try db.write { wdb in
            try wdb.person.update(Person(id: 2, name: "b", phones: []))
            } })
        dfs.pageWorking = true
        try MyDataSetStore(fileSystem: dfs) { db in try db.read { rdb in
            XCTAssertEqual("A", try rdb.person.get(1).name)
            XCTAssertEqual("B", try rdb.person.get(2).name)
            XCTAssertEqual("C", try rdb.person.get(3).name)
            } }
    }

    func testSequenceConnection() throws {
        let db = try MyDataSetStore(fileSystem: dfs)
        defer { db.close() }
        try db.write { wdb in
            XCTAssertEqual(1, try wdb.person.sequence())
        }
        dfs.sequenceWorking = false
        XCTAssertNil(try? db.write { wdb in
            XCTAssertEqual(2, try wdb.person.sequence())
            })
        XCTAssertNil(try? db.write { wdb in
            XCTAssertEqual(2, try wdb.person.sequence())
            })
        dfs.sequenceWorking = true
        try db.write { wdb in
            XCTAssertEqual(2, try wdb.person.sequence())
        }
    }
    
    func testSequenceConnections() throws {
        try MyDataSetStore(fileSystem: dfs) { db in try db.write { wdb in
            XCTAssertEqual(1, try wdb.person.sequence())
            } }
        dfs.sequenceWorking = false
        XCTAssertNil(try? MyDataSetStore(fileSystem: dfs) { db in try db.write { wdb in
            XCTAssertEqual(2, try wdb.person.sequence())
            } })
        XCTAssertNil(try? MyDataSetStore(fileSystem: dfs) { db in try db.write { wdb in
            XCTAssertEqual(2, try wdb.person.sequence())
            } })
        dfs.sequenceWorking = true
        try MyDataSetStore(fileSystem: dfs) { db in try db.write { wdb in
            XCTAssertEqual(2, try wdb.person.sequence())
            } }
    }

}

public enum ReadOnlyDataStoreFileSystemError: Error {
    case write
}

open class ReadOnlyDataStoreFileSystem: DataStoreFileSystem {
    
    var sequenceWorking: Bool = true
    
    var pageWorking: Bool = true
    
    var backupWorking: Bool = true
    
    var deleteBackupWorking: Bool = true
    
    open override func writeSequence(json: Json) throws {
        if sequenceWorking {
            try super.writeSequence(json: json)
        } else {
            throw ReadOnlyDataStoreFileSystemError.write
        }
    }
    
    open override func writePage(name: String, page index: Int, json: Json) throws {
        if pageWorking {
            try super.writePage(name: name, page: index, json: json)
        } else {
            throw ReadOnlyDataStoreFileSystemError.write
        }
    }
    
    open override func writeBackup(json: Json) throws {
        if backupWorking {
            try super.writeBackup(json: json)
        } else {
            throw ReadOnlyDataStoreFileSystemError.write
        }
    }
    
    open override func deleteBackup() throws {
        if deleteBackupWorking {
            try super.deleteBackup()
        } else {
            throw ReadOnlyDataStoreFileSystemError.write
        }
    }
    
}
