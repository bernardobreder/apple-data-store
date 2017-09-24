# Introduction

The DataStore component is responsible for creating a small database for storing values in Json.

# Example

The example below shows the creation of a file system with a directory and a file with a content:

```swift
let folder = MemoryFileSystem().home()
let db = try DataStoreDatabase(fileSystem: DataStoreFileSystem(folder: folder))

db.write { wdb in
    let person = DataStoreRecord(json: try Json(["name": "Abc"]))
    let phone = DataStoreRecord(json: try Json(["number": 123]))
    wdb.insert(name: "person", page: 1, id: 1, record: person)
    wdb.insert(name: "phone", page: 1, id: 1, record: phone)
}

try db.read { rdb in
    let name = try rdb.list(name: "person", decode: { r in r.requireString("name") })
    let number = try rdb.list(name: "phone", decode: { r in r.requireInt("number") })
}
```

