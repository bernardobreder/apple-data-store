# Introdução

O componente DataStore é responsável por criar um pequeno banco de dados para armazenar em tabelas valores em Json.

# Exemplo

O exemplo abaixo mostra a criação um sistema de arquivo com um diretório e um arquivo com um conteúdo:

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

