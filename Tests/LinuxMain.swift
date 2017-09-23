//
//  DataStoreTests.swift
//  DataStore
//
//  Created by Bernardo Breder.
//
//

import XCTest
@testable import DataStoreTests

extension DataStoreBackupTests {

	static var allTests : [(String, (DataStoreBackupTests) -> () throws -> Void)] {
		return [
			("testManyPages", testManyPages),
			("testOnePage", testOnePage),
			("testRestore2Changes", testRestore2Changes),
			("testRestore", testRestore),
			("testRestoreApply", testRestoreApply),
		]
	}

}

extension DataStoreSampleTests {

	static var allTests : [(String, (DataStoreSampleTests) -> () throws -> Void)] {
		return [
			("testCreate1Data", testCreate1Data),
			("testCreate2Data", testCreate2Data),
			("testCreate3Data", testCreate3Data),
			("testDelete", testDelete),
			("testSequence", testSequence),
			("testUpdate", testUpdate),
		]
	}

}

extension DataStoreReadOnlyTests {

	static var allTests : [(String, (DataStoreReadOnlyTests) -> () throws -> Void)] {
		return [
			("testPageConnection", testPageConnection),
			("testPageConnections", testPageConnections),
			("testSequenceConnection", testSequenceConnection),
			("testSequenceConnections", testSequenceConnections),
		]
	}

}

extension DataStoreTests {

	static var allTests : [(String, (DataStoreTests) -> () throws -> Void)] {
		return [
			("testDeleteNotExist", testDeleteNotExist),
			("testEmpty", testEmpty),
			("testExample", testExample),
			("testInsertAlreadyExist", testInsertAlreadyExist),
			("testList", testList),
			("testListFilter", testListFilter),
			("testListTablePage", testListTablePage),
			("testUpdateNotExist", testUpdateNotExist),
			("testWriteAndReadOwnerInserts", testWriteAndReadOwnerInserts),
		]
	}

}

XCTMain([
	testCase(DataStoreBackupTests.allTests),
	testCase(DataStoreSampleTests.allTests),
	testCase(DataStoreReadOnlyTests.allTests),
	testCase(DataStoreTests.allTests),
])

