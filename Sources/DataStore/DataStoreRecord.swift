//
//  DataStore.swift
//  DataStore
//
//  Created by Bernardo Breder on 23/12/16.
//
//

import Foundation

#if SWIFT_PACKAGE
    import Json
    import Array
    import Optional
#endif

public class DataStoreRecord {
    
    public static let classid = "classid"
    
    public let json: Json
    
    public init(json: Json) {
        self.json = json
    }
    
    public func requireInt(_ name: String) throws -> Int {
        guard let int = json[name].int else { throw DataStoreRecordError.intRequired(name, description) }
        return int
    }
    
    public func requireClassId() throws -> Int {
        return try requireInt(DataStoreRecord.classid)
    }
    
    public func requireId() throws -> Int {
        return try requireInt("id")
    }
    
    public func requireString(_ name: String) throws -> String {
        guard let string = json[name].string else { throw DataStoreRecordError.stringRequired(name, description) }
        return string
    }
    
    public func requireJson(_ name: String) throws -> Json {
        guard let string = json[name].string else { throw DataStoreRecordError.jsonRequired(name, description) }
        guard let data: Data = string.data(using: .utf8) else { throw DataStoreRecordError.jsonRequired(name, description) }
        return try Json(data: data)
    }
    
    public func requireStringComponents<T>(_ name: String, decoder: (String) throws -> T) throws -> [T] {
        return try requireString(name).components().map(decoder)
    }
    
    public func requireStringEncoded<T>(_ name: String, decoder: (String) throws -> T) throws -> T {
        guard let string = json[name].string else { throw DataStoreRecordError.stringRequired(name, description) }
        return try decoder(string)
    }
    
    public func requireBool(_ name: String) throws -> Bool {
        guard let boolean = json[name].bool else { throw DataStoreRecordError.booleanRequired(name, description) }
        return boolean
    }
    
    public func requireIntArray(_ name: String) throws -> [Int] {
        guard let array = json[name].array else { throw DataStoreRecordError.intArrayRequired(name, description) }
        return array.native.map {$0.int}.notnil()
    }
    
    public func requireStringArray(_ name: String) throws -> [String] {
        guard let array = json[name].array else { throw DataStoreRecordError.intArrayRequired(name, description) }
        return array.native.map { $0.string }.notnil()
    }

    public func requireArray<T>(_ name: String, mapValue: @escaping (DataStoreRecord) throws -> T?) throws -> [T] {
        guard let array = json[name].array else { throw DataStoreRecordError.intArrayRequired(name, description) }
        return array.native.map { try? mapValue(DataStoreRecord(json: $0))}.notnil().notnil()
    }

    public func requireDictionary<T>(_ name: String, mapValue: @escaping (DataStoreRecord) throws -> T) throws -> [String: T] {
        guard let dic = json[name].dic else { throw DataStoreRecordError.dictionaryRequired(name, description) }
        return dic.typedValues(function: { try? mapValue(DataStoreRecord(json: $1)) })
    }
    
    public func getInt(_ name: String) -> Int? {
        return json[name].int
    }
    
    public func getId() -> Int {
        return getInt("id") ?? -1
    }
    
    public func getString(_ name: String) -> String? {
        guard let string = json[name].string else { return nil }
        return string
    }
    
    public func getJson(_ name: String) -> Json? {
        guard let string = json[name].string else { return nil }
        guard let data: Data = string.data(using: .utf8) else { return nil }
        return try? Json(data: data)
    }
    
    public func getBool(_ name: String) -> Bool? {
        guard let boolean = json[name].bool else { return nil }
        return boolean
    }
    
    public func getIntArray(_ name: String) -> [Int]? {
        guard let array = json[name].array else { return nil }
        return array.native.map {$0.int}.notnil()
    }
    
    public func data() throws -> Data {
        return try json.data()
    }
    
}

extension DataStoreRecord: CustomStringConvertible {
    
    public var description: String {
        return (try? json.jsonToString()) ?? "?"
    }
    
}

public enum DataStoreRecordError: Error {
    case intRequired(String, String)
    case stringRequired(String, String)
    case jsonRequired(String, String)
    case booleanRequired(String, String)
    case intArrayRequired(String, String)
    case dictionaryRequired(String, String)
}
