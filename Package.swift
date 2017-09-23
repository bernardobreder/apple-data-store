//
//  Package.swift
//  DataStore
//
//

import PackageDescription

let package = Package(
	name: "DataStore",
	targets: [
		Target(name: "DataStore", dependencies: ["AtomicValue", "Dictionary", "FileSystem", "Json", "Optional", "Regex"]),
		Target(name: "Array", dependencies: []),
		Target(name: "AtomicValue", dependencies: []),
		Target(name: "Dictionary", dependencies: []),
		Target(name: "FileSystem", dependencies: []),
		Target(name: "IndexLiteral", dependencies: []),
		Target(name: "Json", dependencies: ["Array", "IndexLiteral", "Literal"]),
		Target(name: "Literal", dependencies: []),
		Target(name: "Optional", dependencies: []),
		Target(name: "Regex", dependencies: []),
	]
)

