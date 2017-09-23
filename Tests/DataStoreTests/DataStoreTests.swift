//
//  DataStoreTests.swift
//  DataStore
//
//  Created by Bernardo Breder on 14/01/17.
//
//

import XCTest
import Foundation
@testable import Json
@testable import FileSystem
@testable import DataStore

class DataStoreTests: XCTestCase {
    
    let fs = MemoryFileSystem()
    
    func personDecode(_ record: DataStoreRecord) throws -> String {
        return try record.requireString("name")
    }
    
    func phoneDecode(_ record: DataStoreRecord) throws -> Int {
        return try record.requireInt("number")
    }
    
    func testEmpty() throws {
        let db = try DataStore(fileSystem: DataStoreFileSystem(folder: fs.home()))
        try db.read { rdb in
            XCTAssertEqual([], try rdb.list(name: "person", decode: personDecode).sorted())
            XCTAssertEqual([], try rdb.list(name: "phone", decode: phoneDecode).sorted())
        }
        try db.read { rdb in
            XCTAssertEqual([], try rdb.list(name: "person", page: 1, filter: { _ in true }, decode: personDecode))
            XCTAssertEqual([], try rdb.list(name: "phone", page: 1, filter: { _ in true }, decode: personDecode))
        }
    }
    
    func testInsertAlreadyExist() throws {
        let db = try DataStore(fileSystem: DataStoreFileSystem(folder: fs.home()))
        try db.write { wdb in
            wdb.insert(name: "person", page: 1, id: 1, record: DataStoreRecord(json: Json(["id": 1, "name": "A"])))
        }
        XCTAssertNil(try? db.write { wdb in
            wdb.insert(name: "person", page: 1, id: 1, record: DataStoreRecord(json: Json(["id": 1, "name": "A"])))
            })
    }
    
    func testUpdateNotExist() throws {
        let db = try DataStore(fileSystem: DataStoreFileSystem(folder: fs.home()))
        XCTAssertNil(try? db.write { wdb in
            wdb.update(name: "person", page: 1, id: 1, record: DataStoreRecord(json: Json(["id": 1, "name": "A"])))
            })
    }
    
    func testDeleteNotExist() throws {
        let db = try DataStore(fileSystem: DataStoreFileSystem(folder: fs.home()))
        try db.write { wdb in
            wdb.delete(name: "person", page: 1, id: 1)
        }
    }
    
    func testList() throws {
        let db = try DataStore(fileSystem: DataStoreFileSystem(folder: fs.home()))
        try db.write { wdb in
            wdb.insert(name: "person", page: 1, id: 1, record: DataStoreRecord(json: Json(["id": 1, "name": "A"])))
            wdb.insert(name: "phone", page: 1, id: 1, record: DataStoreRecord(json: try Json(["id": 1, "number": 123])))
        }
        try db.read { rdb in
            XCTAssertEqual(["person", "phone"], try rdb.list().sorted())
        }
    }
    
    
    func testListTablePage() throws {
        let db = try DataStore(fileSystem: DataStoreFileSystem(folder: fs.home()))
        try db.write { wdb in
            wdb.insert(name: "person", page: 1, id: 1, record: DataStoreRecord(json: Json(["id": 1, "name": "A"])))
            wdb.insert(name: "person", page: 1, id: 5, record: DataStoreRecord(json: Json(["id": 5, "name": "E"])))
        }
        try db.read { rdb in
            XCTAssertEqual([1, 5], try rdb.list(name: "person", page: 1).sorted())
        }
    }
    
    func testExample() throws {
        let db = try DataStore(fileSystem: DataStoreFileSystem(folder: fs.home()))
        try db.write { wdb in
            wdb.insert(name: "person", page: 1, id: 1, record: DataStoreRecord(json: Json(["id": 1, "name": "A"])))
            wdb.insert(name: "person", page: 1, id: 2, record: DataStoreRecord(json: Json(["id": 2, "name": "B"])))
            wdb.insert(name: "person", page: 2, id: 3, record: DataStoreRecord(json: Json(["id": 3, "name": "C"])))
            wdb.insert(name: "person", page: 2, id: 4, record: DataStoreRecord(json: Json(["id": 4, "name": "D"])))
            wdb.insert(name: "person", page: 3, id: 5, record: DataStoreRecord(json: Json(["id": 5, "name": "E"])))
            
            wdb.insert(name: "phone", page: 1, id: 1, record: DataStoreRecord(json: try Json(["id": 1, "number": 123])))
            wdb.insert(name: "phone", page: 1, id: 2, record: DataStoreRecord(json: try Json(["id": 2, "number": 321])))
        }
        try db.read { rdb in
            XCTAssertTrue(try rdb.exist(name: "person", page: 1, id: 1))
            XCTAssertTrue(try rdb.exist(name: "person", page: 1, id: 2))
            XCTAssertTrue(try rdb.exist(name: "person", page: 2, id: 3))
            XCTAssertTrue(try rdb.exist(name: "person", page: 2, id: 4))
            XCTAssertTrue(try rdb.exist(name: "person", page: 3, id: 5))
            XCTAssertFalse(try rdb.exist(name: "person", page: 3, id: 6))
            XCTAssertTrue(try rdb.exist(name: "phone", page: 1, id: 1))
            XCTAssertTrue(try rdb.exist(name: "phone", page: 1, id: 2))
            XCTAssertFalse(try rdb.exist(name: "phone", page: 1, id: 3))
            XCTAssertFalse(try rdb.exist(name: "phone", page: 2, id: 3))
            XCTAssertEqual(["A", "B", "C", "D", "E"].sorted(), try rdb.list(name: "person", decode: personDecode).sorted())
            XCTAssertEqual([123, 321], try rdb.list(name: "phone", decode: phoneDecode).sorted())
        }
    }
    
    func testWriteAndReadOwnerInserts() throws {
        let db = try DataStore(fileSystem: DataStoreFileSystem(folder: fs.home()))
        try db.write { wdb in
            wdb.insert(name: "person", page: 1, id: 1, record: DataStoreRecord(json: Json(["id": 1, "name": "A"])))
            XCTAssertEqual(["A"].sorted(), try wdb.list(name: "person", decode: personDecode).sorted())
        }
        try db.write { wdb in
            wdb.insert(name: "person", page: 1, id: 2, record: DataStoreRecord(json: Json(["id": 2, "name": "B"])))
            wdb.insert(name: "person", page: 2, id: 3, record: DataStoreRecord(json: Json(["id": 3, "name": "C"])))
            XCTAssertEqual(["A", "B", "C"].sorted(), try wdb.list(name: "person", decode: personDecode).sorted())
        }
        try db.write { wdb in
            wdb.update(name: "person", page: 1, id: 2, record: DataStoreRecord(json: Json(["id": 2, "name": "b"])))
            XCTAssertEqual(["A", "C", "b"].sorted(), try wdb.list(name: "person", decode: personDecode).sorted())
        }
        try db.write { wdb in
            wdb.delete(name: "person", page: 1, id: 2)
            XCTAssertEqual(["A", "C"].sorted(), try wdb.list(name: "person", decode: personDecode).sorted())
        }
        try db.write { wdb in
            wdb.update(name: "person", page: 1, id: 1, record: DataStoreRecord(json: Json(["id": 1, "name": "a"])))
            wdb.update(name: "person", page: 2, id: 3, record: DataStoreRecord(json: Json(["id": 3, "name": "c"])))
            XCTAssertEqual(["a", "c"].sorted(), try wdb.list(name: "person", decode: personDecode).sorted())
        }
        try db.write { wdb in
            wdb.delete(name: "person", page: 1, id: 1)
            wdb.delete(name: "person", page: 2, id: 3)
            XCTAssertEqual([], try wdb.list(name: "person", decode: personDecode).sorted())
        }
    }
    
    func testListFilter() throws {
        let db = try DataStore(fileSystem: DataStoreFileSystem(folder: fs.home()))
        try db.write { wdb in
            wdb.insert(name: "person", page: 1, id: 1, record: DataStoreRecord(json: try Json(["name": "A"])))
            wdb.insert(name: "person", page: 1, id: 2, record: DataStoreRecord(json: try Json(["name": "B"])))
            wdb.insert(name: "person", page: 2, id: 3, record: DataStoreRecord(json: try Json(["name": "C"])))
            wdb.insert(name: "person", page: 2, id: 4, record: DataStoreRecord(json: try Json(["name": "D"])))
            wdb.insert(name: "person", page: 3, id: 5, record: DataStoreRecord(json: try Json(["name": "E"])))
            
            wdb.insert(name: "phone", page: 1, id: 1, record: DataStoreRecord(json: try Json(["number": 123])))
            wdb.insert(name: "phone", page: 1, id: 2, record: DataStoreRecord(json: try Json(["number": 321])))
        }
        try db.read { rdb in
            XCTAssertEqual(["C"].sorted(), try rdb.list(name: "person", page: 2, filter: { k,r in try r.requireString("name") == "C" }, decode: personDecode).sorted())
            XCTAssertEqual([], try rdb.list(name: "person", page: 1, filter: { k,r in try r.requireString("name") == "C" }, decode: personDecode).sorted())
            XCTAssertEqual(["C", "D"].sorted(), try rdb.list(name: "person", page: 2, filter: { _ in true }, decode: personDecode).sorted())
        }
    }
    
}
