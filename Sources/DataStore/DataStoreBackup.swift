//
//  DataStoreBackup.swift
//  DataStore
//
//  Created by Bernardo Breder on 24/12/16.
//
//

import Foundation

#if SWIFT_PACKAGE
    import Json
    import Array
    import Dictionary
#endif

public class DataStoreBackup {
    
    internal var entrys: [String: Set<Int>] = [:]
    
    internal var sequences: [String: Int]?
    
    internal let fs: DataStoreFileSystem
    
    public init(fileSystem fs: DataStoreFileSystem) {
        self.fs = fs
    }
    
    public func changed(name: String, page: Int) {
        var pages: Set<Int> = entrys[name] ?? []
        pages.insert(page)
        entrys[name] = pages
    }
    
    internal func jsonSequences() throws -> Json {
        return try fs.readSequence()
    }
    
    internal func jsonNamePageContent() throws -> [String: [String: Json]] {
        return try entrys.map { e1 in
            (e1.key, try e1.value.map{$0}.dic { e2 in
                (String(e2), try fs.readPage(name: e1.key, page: e2))
            })
        }
    }
    
    public func json() throws -> Json {
        var dic: [String: Json] = [:]
        if let _ = self.sequences {
            dic["sequence"] = try fs.readSequence()
        }
        dic["data"] = try Json(jsonNamePageContent())
        return try Json(dic)
    }
    
}

public enum DataStoreRestoreError: Error {
    case createBackup
    case backupFileNotFound
    case readBackupFile
    case backupSequenceToData
    case backupNotJsonFile
    case backupJsonNotADictionary
    case backupJsonNotHaveDatas
    case backupJsonDataNotAArray
    case backupJsonDataItemNotADic
    case backupJsonDataItempageNotADic(String)
    case backupJsonDataItempageNotApage(String)
    case restoreSequenceIsNotJsonReadable(String?)
    case restoreSequenceCanNotWrite(String?)
    case restorePageIsNotJsonReadable(String, Int, String?)
    case restorePageCanNotWrite(String, Int, String?)
}

public class DataStoreRestore {
    
    public var sequence: Data?
    
    public var datas: [(name: String, page: Int, data: Data)] = []
    
    internal let fs: DataStoreFileSystem
    
    public init(fileSystem fs: DataStoreFileSystem) throws {
        self.fs = fs
        guard let json = try fs.readBackup() else { return }
        guard let dic = json.dic else { throw DataStoreRestoreError.backupJsonNotADictionary }
        if let sequences = dic["sequence"] {
            guard let data = try? sequences.data() else { throw DataStoreRestoreError.backupSequenceToData }
            self.sequence = data
        }
        guard let datasJson = dic["data"] else { throw DataStoreRestoreError.backupJsonNotHaveDatas }
        guard let datasDic = datasJson.dic else { throw DataStoreRestoreError.backupJsonDataNotAArray }
        for itemJson in datasDic.native {
            let name = itemJson.key
            guard let pageDic = itemJson.value.dic else { throw DataStoreRestoreError.backupJsonDataItempageNotADic(name) }
            for pageDicEntry in pageDic.native {
                guard let page = Int(pageDicEntry.key) else { throw DataStoreRestoreError.backupJsonDataItempageNotApage(name) }
                guard let data = try? pageDicEntry.value.data() else { throw DataStoreRestoreError.createBackup }
                datas.append((name: name, page: page, data: data))
            }
        }
        datas.sort(by: { a, b in a.name == b.name ? a.page <= b.page : a.name <= b.name })
    }
    
    public func apply() throws {
        if let sequence = self.sequence {
            guard let json = try? Json(data: sequence) else { throw DataStoreRestoreError.restoreSequenceIsNotJsonReadable(String(data: sequence, encoding: .utf8)) }
            guard let _ = try? fs.writeSequence(json: json) else { throw DataStoreRestoreError.restoreSequenceCanNotWrite(try? json.jsonToString()) }
        }
        for data in datas {
            guard let json = try? Json(data: data.data) else { throw DataStoreRestoreError.restorePageIsNotJsonReadable(data.name, data.page, String(data: data.data, encoding: .utf8)) }
            guard let _ = try? fs.writePage(name: data.name, page: data.page, json: json) else { throw DataStoreRestoreError.restorePageCanNotWrite(data.name, data.page, try? json.jsonToString()) }
        }
    }
    
}
