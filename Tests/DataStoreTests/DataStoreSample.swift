//
//  DataStoreSample.swift
//  DataStore
//
//  Created by Bernardo Breder on 24/12/16.
//
//

import XCTest
@testable import Json
@testable import FileSystem
@testable import DataStore

public class MyDataSetStore {
    
    internal let db: DataStore
    
    public init(fileSystem fs: DataStoreFileSystem) throws {
        self.db = try DataStore(fileSystem: fs)
    }
    
    @discardableResult
    public convenience init(fileSystem fs: DataStoreFileSystem, _ f: ((MyDataSetStore) throws -> Void)) throws {
        try self.init(fileSystem: fs)
        defer { close() }
        try f(self)
    }
    
    public func read() throws -> MyDataStoreReader {
        return MyDataStoreReader(reader: try db.read())
    }
    
    public func read(_ f: ((MyDataStoreReader) throws -> Void)) throws {
        let reader = try MyDataStoreReader(reader: db.read())
        defer { reader.close() }
        try f(reader)
    }
    
    public func write() throws -> MyDataStoreWriter {
        return MyDataStoreWriter(writer: try db.write())
    }
    
    public func write(_ f: ((MyDataStoreWriter) throws -> Void)) throws {
        let writer = try MyDataStoreWriter(writer: db.write())
        defer { writer.close() }
        try f(writer)
        try writer.commit()
    }
    
    public func close() {
        db.close()
    }
    
}

public class MyDataStoreReader {
    
    internal let reader: DataStoreReader
    
    public let person: PersonDataStoreReader
    
    public let phone: PhoneDataStoreReader
    
    public init(reader: DataStoreReader) {
        self.reader = reader
        self.person = PersonDataStoreReader(reader: reader)
        self.phone = PhoneDataStoreReader(reader: reader)
    }
    
    public func close() {
        reader.close()
    }
    
}

public class MyDataStoreWriter {
    
    internal let writer: DataStoreWriter
    
    public let person: PersonDataStoreWriter
    
    public let phone: PhoneDataStoreWriter
    
    public init(writer: DataStoreWriter) {
        self.writer = writer
        self.person = PersonDataStoreWriter(writer: writer)
        self.phone = PhoneDataStoreWriter(writer: writer)
    }
    
    public func commit() throws {
        try writer.commit()
    }
    
    public func close() {
        writer.close()
    }
    
}

public struct Person {
    
    let id: Int
    
    let name: String
    
    let phones: [Int]
    
}

public struct Phone {
    
    let id: Int
    
    let number: String
    
}

public class PersonDataStoreReader {
    
    let reader: DataStoreReader
    
    public init(reader: DataStoreReader) {
        self.reader = reader
    }
    
    public func get(_ id: Int) throws -> Person {
        let index = id / 1024
        let array = try reader.load(name: "person", page: index)
        guard let first = array.filter({ k,r in k.id == id}).first?.value else { throw DataStoreReaderError.jsonNotFound("person", index, id) }
        let name = try first.requireString("name")
        let phones: [Int] = try first.requireIntArray("phones")
        return Person(id: id, name: name, phones: phones)
    }
    
}

public class PersonDataStoreWriter: PersonDataStoreReader {
    
    internal var writer: DataStoreWriter
    
    public init(writer: DataStoreWriter) {
        self.writer = writer
        super.init(reader: writer)
    }
    
    public func sequence() throws -> Int {
        return try writer.sequence(name: "person")
    }
    
    @discardableResult
    public func insert(_ element: Person) throws -> Self {
        let data = DataStoreRecord(json: Json(["id": element.id, "name": element.name, "phones": element.phones]))
        writer.insert(name: "person", page: index(element.id), id: element.id, record: data)
        return self
    }
    
    @discardableResult
    public func update(_ element: Person) throws -> Self {
        let data = DataStoreRecord(json: Json(["id": element.id, "name": element.name, "phones": element.phones]))
        writer.update(name: "person", page: index(element.id), id: element.id, record: data)
        return self
    }
    
    @discardableResult
    public func delete(_ id: Int) throws -> Self {
        writer.delete(name: "person", page: index(id), id: id)
        return self
    }
    
    public func index(_ id: Int) -> Int{
        return id / 1024
    }
    
}

public class PhoneDataStoreReader {
    
    let reader: DataStoreReader
    
    public init(reader: DataStoreReader) {
        self.reader = reader
    }
    
    public func get(_ id: Int) throws -> Phone {
        let index = id / 1024
        let array = try reader.load(name: "person", page: index)
        guard let first = array.filter({ k,v in k.id == id}).first?.value else { throw DataStoreReaderError.jsonNotFound("phone", index, id) }
        let number = try first.requireString("number")
        return Phone(id: id, number: number)
    }
    
}

public class PhoneDataStoreWriter: PhoneDataStoreReader {
    
    internal var writer: DataStoreWriter
    
    public init(writer: DataStoreWriter) {
        self.writer = writer
        super.init(reader: writer)
    }
    
    public func sequence() throws -> Int {
        return try writer.sequence(name: "phone")
    }
    
    @discardableResult
    public func insert(_ element: Phone) throws -> Self {
        let data = DataStoreRecord(json: Json(["id": element.id, "number": element.number]))
        writer.insert(name: "phone", page: index(element.id), id: element.id, record: data)
        return self
    }
    
    @discardableResult
    public func update(_ element: Phone) throws -> Self {
        let data = DataStoreRecord(json: Json(["id": element.id, "number": element.number]))
        writer.update(name: "phone", page: index(element.id), id: element.id, record: data)
        return self
    }
    
    @discardableResult
    public func delete(_ id: Int) throws -> Self {
        writer.delete(name: "phone", page: index(id), id: id)
        return self
    }
    
    public func index(_ id: Int) -> Int{
        return id / 1024
    }
    
}
