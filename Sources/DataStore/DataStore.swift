//
//  DataStore.swift
//  DataStore
//
//  Created by Bernardo Breder on 16/12/16.
//  Copyright © 2016 Breder Company. All rights reserved.
//

import Foundation

#if SWIFT_PACKAGE
    import AtomicValue
    import FileSystem
#endif

public enum DataStoreError: Error {
    case databaseClosed
    case notnil
}

public class DataStore {
    
    internal let fs: DataStoreFileSystem
    
    private lazy var lock: RWLock = RWLock()
    
    public var closed: AtomicBool = AtomicBool(false)
    
    public init(fileSystem fs: DataStoreFileSystem) throws {
        self.fs = fs
        try DataStoreRestore(fileSystem: fs).apply()
    }
    
    public var folder: Folder {
        return fs.folder
    }
    
    private func checkRestore() throws {
        lock.writeLock()
        defer { lock.unlock() }
        try DataStoreRestore(fileSystem: fs).apply()
    }
    
    public func read() throws -> DataStoreReader {
        try checkRestore()
        lock.readLock()
        if closed.get() { lock.unlock(); throw DataStoreError.databaseClosed }
        return DataStoreReader(lock: lock, fileSystem: fs)
    }
    
    @discardableResult
    public func read<T>(_ function: (DataStoreReader) throws -> T) throws -> T {
        let read = try self.read()
        do {
            let result = try function(read)
            read.close()
            return result
        } catch let e {
            read.close()
            throw e
        }
    }
    
    public func write() throws -> DataStoreWriter {
        try checkRestore()
        lock.writeLock()
        if closed.get() { lock.unlock(); throw DataStoreError.databaseClosed }
        return DataStoreWriter(lock: lock, fileSystem: fs)
    }
    
    @discardableResult
    public func write<T>(_ function: (DataStoreWriter) throws -> T) throws -> T {
        let writer = try self.write()
        do {
            let result = try function(writer)
            try writer.commit()
            for done in writer.dones.reversed() { done() }
            writer.close()
            return result
        } catch let e {
            for revert in writer.reverts.reversed() { revert() }
            writer.close()
            throw e
        }
    }
    
    public func close() {
        lock.writeLock()
        defer { lock.unlock() }
        closed.set(true)
    }
    
}
