//
//  DataStoreBackupTests.swift
//  DataStore
//
//  Created by Bernardo Breder on 24/12/16.
//
//

import XCTest
@testable import Json
@testable import FileSystem
@testable import DataStore

class DataStoreBackupTests: XCTestCase {
    
    var fs: MemoryFileSystem!
    
    var dfs: DataStoreFileSystem!
    
    override func setUp() {
        fs = MemoryFileSystem()
        dfs = DataStoreFileSystem(folder: fs.home())
    }

    func testOnePage() throws {
        let backup = DataStoreBackup(fileSystem: dfs)
        try dfs.writePage(name: "a", page: 1, json: try Json(data: "[{\"name\": \"test\"}]".data(using: .utf8)!))
        backup.changed(name: "a", page: 1)
        let json = try backup.jsonNamePageContent()
        XCTAssertEqual("test", json["a"]?["1"]?[0]["name"].string)
    }
    
    func testManyPages() throws {
        let backup = DataStoreBackup(fileSystem: dfs)
        try dfs.writePage(name: "a", page: 1, json: try Json(data:"[{\"name\": \"A\"}]".data(using: .utf8)!))
        try dfs.writePage(name: "b", page: 2, json: try Json(data:"[{\"name\": \"B\"}]".data(using: .utf8)!))
        try dfs.writePage(name: "c", page: 3, json: try Json(data:"[{\"name\": \"C\"}]".data(using: .utf8)!))
        backup.changed(name: "a", page: 1)
        backup.changed(name: "c", page: 3)
        let json = try backup.jsonNamePageContent()
        XCTAssertEqual("A", json["a"]?["1"]?[0]["name"].string)
        XCTAssertEqual("C", json["c"]?["3"]?[0]["name"].string)
    }
    
    func testRestore() throws {
        let pageA1Json = try Json(data: "[{\"name\": \"test\"}]".data(using: .utf8)!)
        let backup = DataStoreBackup(fileSystem: dfs)
        try dfs.writePage(name: "a", page: 1, json: pageA1Json)
        backup.changed(name: "a", page: 1)
        try dfs.writeBackup(json: backup.json())
        let restore = try DataStoreRestore(fileSystem: dfs)
        XCTAssertNil(restore.sequence)
        XCTAssertEqual(1, restore.datas.count)
        XCTAssertEqual("a", restore.datas[0].name)
        XCTAssertEqual(1, restore.datas[0].page)
        XCTAssertEqual(try pageA1Json.data(), restore.datas[0].data)
    }

    func testRestore2Changes() throws {
        let pageA1Json = try Json(data: "[{\"name\": \"1\"}]".data(using: .utf8)!)
        let pageA2Json = try Json(data: "[{\"name\": \"2\"}]".data(using: .utf8)!)
        let pageA3Json = try Json(data: "[{\"name\": \"3\"}]".data(using: .utf8)!)
        try dfs.writePage(name: "a", page: 1, json: pageA1Json)
        try dfs.writePage(name: "a", page: 2, json: pageA2Json)
        try dfs.writePage(name: "a", page: 3, json: pageA3Json)
        let backup = DataStoreBackup(fileSystem: dfs)
        backup.changed(name: "a", page: 1)
        backup.changed(name: "a", page: 3)
        try dfs.writeBackup(json: backup.json())
        let restore = try DataStoreRestore(fileSystem: dfs)
        XCTAssertNil(restore.sequence)
        XCTAssertEqual(2, restore.datas.count)
        XCTAssertEqual("a", restore.datas[0].name)
        XCTAssertEqual(1, restore.datas[0].page)
        XCTAssertEqual("a", restore.datas[1].name)
        XCTAssertEqual(3, restore.datas[1].page)
        XCTAssertEqual(try pageA1Json.data(), restore.datas[0].data)
        XCTAssertEqual(try pageA3Json.data(), restore.datas[1].data)
    }

    func testRestoreApply() throws {
        let sequenceJson = try Json(data: "{\"a\": 1}".data(using: .utf8)!)
        let sequenceChangedJson = try Json(data: "{\"a\": 2}".data(using: .utf8)!)
        let pageA1Json = try Json(data: "[{\"name\": \"1\"}]".data(using: .utf8)!)
        let pageA2Json = try Json(data: "[{\"name\": \"2\"}]".data(using: .utf8)!)
        let pageA3Json = try Json(data: "[{\"name\": \"3\"}]".data(using: .utf8)!)
        try dfs.writeSequence(json: sequenceJson)
        try dfs.writePage(name: "a", page: 1, json: pageA1Json)
        try dfs.writePage(name: "a", page: 2, json: pageA2Json)
        try dfs.writePage(name: "a", page: 3, json: pageA3Json)
        let backup = DataStoreBackup(fileSystem: dfs)
        backup.sequences = sequenceJson.dic!.intValues
        backup.changed(name: "a", page: 1)
        backup.changed(name: "a", page: 3)
        try dfs.writeBackup(json: backup.json())
        XCTAssertEqual(try sequenceJson.data(), try dfs.readSequence().data())
        XCTAssertEqual(try pageA1Json.data(), try dfs.readPage(name: "a", page: 1).data())
        XCTAssertEqual(try pageA2Json.data(), try dfs.readPage(name: "a", page: 2).data())
        XCTAssertEqual(try pageA3Json.data(), try dfs.readPage(name: "a", page: 3).data())
        try dfs.writeSequence(json: sequenceChangedJson)
        try dfs.writePage(name: "a", page: 1, json: pageA2Json)
        try dfs.writePage(name: "a", page: 2, json: pageA2Json)
        try dfs.writePage(name: "a", page: 3, json: pageA2Json)
        XCTAssertEqual(try sequenceChangedJson.data(), try dfs.readSequence().data())
        XCTAssertEqual(try pageA2Json.data(), try dfs.readPage(name: "a", page: 1).data())
        XCTAssertEqual(try pageA2Json.data(), try dfs.readPage(name: "a", page: 2).data())
        XCTAssertEqual(try pageA2Json.data(), try dfs.readPage(name: "a", page: 3).data())
        try DataStoreRestore(fileSystem: dfs).apply()
        XCTAssertEqual(try sequenceJson.jsonToString(), try dfs.readSequence().jsonToString())
        XCTAssertEqual(try pageA1Json.data(), try dfs.readPage(name: "a", page: 1).data())
        XCTAssertEqual(try pageA2Json.data(), try dfs.readPage(name: "a", page: 2).data())
        XCTAssertEqual(try pageA3Json.data(), try dfs.readPage(name: "a", page: 3).data())
    }

}
