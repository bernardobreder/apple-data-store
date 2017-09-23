//
//  DataStoreTests.swift
//  DataStore
//
//  Created by Bernardo Breder on 24/12/16.
//
//

import XCTest
@testable import Json
@testable import FileSystem
@testable import DataStore

class DataStoreSampleTests: XCTestCase {
    
    let fs: MemoryFileSystem = MemoryFileSystem()
    
    func testSequence() throws {
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            XCTAssertEqual(1, try wdb.person.sequence())
            XCTAssertEqual(2, try wdb.person.sequence())
            XCTAssertEqual(3, try wdb.person.sequence())
            XCTAssertEqual(1, try wdb.phone.sequence())
            XCTAssertEqual(2, try wdb.phone.sequence())
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            XCTAssertEqual(4, try wdb.person.sequence())
            XCTAssertEqual(5, try wdb.person.sequence())
            XCTAssertEqual(6, try wdb.person.sequence())
            XCTAssertEqual(3, try wdb.phone.sequence())
            XCTAssertEqual(4, try wdb.phone.sequence())
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            XCTAssertEqual(7, try wdb.person.sequence())
            XCTAssertEqual(8, try wdb.person.sequence())
            XCTAssertEqual(9, try wdb.person.sequence())
            XCTAssertEqual(5, try wdb.phone.sequence())
            XCTAssertEqual(6, try wdb.phone.sequence())
            } }
    }
    
    func testCreate1Data() throws {
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "teste", phones: []))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertEqual("teste", try rdb.person.get(1).name)
            } }
    }
    
    
    func testCreate2Data() throws {
        print("init")
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "A", phones: []))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "B", phones: []))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertEqual("A", try rdb.person.get(1).name)
            XCTAssertEqual("B", try rdb.person.get(2).name)
            } }
    }
    
    func testCreate3Data() throws {
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "A", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "B", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "C", phones: []))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertEqual("A", try rdb.person.get(1).name)
            XCTAssertEqual("B", try rdb.person.get(2).name)
            XCTAssertEqual("C", try rdb.person.get(3).name)
            } }
    }

    func testUpdate() throws {
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "A", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "B", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "C", phones: []))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.update(Person(id: 2, name: "b", phones: []))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertEqual("A", try rdb.person.get(1).name)
            XCTAssertEqual("b", try rdb.person.get(2).name)
            XCTAssertEqual("C", try rdb.person.get(3).name)
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.update(Person(id: 1, name: "a", phones: []))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertEqual("a", try rdb.person.get(1).name)
            XCTAssertEqual("b", try rdb.person.get(2).name)
            XCTAssertEqual("C", try rdb.person.get(3).name)
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.update(Person(id: 3, name: "c", phones: []))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertEqual("a", try rdb.person.get(1).name)
            XCTAssertEqual("b", try rdb.person.get(2).name)
            XCTAssertEqual("c", try rdb.person.get(3).name)
            } }
    }

    func testDelete() throws {
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "A", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "B", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "C", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "D", phones: []))
            try wdb.person.insert(Person(id: wdb.person.sequence(), name: "E", phones: []))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.delete(3)
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertEqual("A", try rdb.person.get(1).name)
            XCTAssertEqual("B", try rdb.person.get(2).name)
            XCTAssertNil(try? rdb.person.get(3))
            XCTAssertEqual("D", try rdb.person.get(4).name)
            XCTAssertEqual("E", try rdb.person.get(5).name)
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.delete(4)
            try wdb.person.delete(5)
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertEqual("A", try rdb.person.get(1).name)
            XCTAssertEqual("B", try rdb.person.get(2).name)
            XCTAssertNil(try? rdb.person.get(3))
            XCTAssertNil(try? rdb.person.get(4))
            XCTAssertNil(try? rdb.person.get(5))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.delete(1)
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertNil(try? rdb.person.get(1))
            XCTAssertEqual("B", try rdb.person.get(2).name)
            XCTAssertNil(try? rdb.person.get(3))
            XCTAssertNil(try? rdb.person.get(4))
            XCTAssertNil(try? rdb.person.get(5))
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.write { wdb in
            try wdb.person.delete(2)
            } }
        try MyDataSetStore(fileSystem: DataStoreFileSystem(folder: fs.home())) { db in try db.read { rdb in
            XCTAssertNil(try? rdb.person.get(1))
            XCTAssertNil(try? rdb.person.get(2))
            XCTAssertNil(try? rdb.person.get(3))
            XCTAssertNil(try? rdb.person.get(4))
            XCTAssertNil(try? rdb.person.get(5))
            } }
    }
    
}

