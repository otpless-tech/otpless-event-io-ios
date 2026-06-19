import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

internal final class EventDatabase: EventLocalSource {

    private static let dbName = "otpless_event.db"
    private static let dbVersion: Int32 = 4
    private static let table = "events"
    private static let colEventType = "event_type"
    private static let colBody = "body"
    private static let colCreatedAt = "created_at"
    private static let colIsSyncFailed = "is_sync_failed"

    private static let createTable = """
        CREATE TABLE \(table) (
            id                  INTEGER PRIMARY KEY AUTOINCREMENT,
            \(colEventType)     TEXT    NOT NULL,
            \(colBody)          TEXT    NOT NULL,
            \(colCreatedAt)     INTEGER NOT NULL,
            \(colIsSyncFailed)  INTEGER NOT NULL DEFAULT 0
        )
    """

    private static var sharedInstance: EventDatabase?
    private static let sharedLock = NSLock()

    static func getInstance() -> EventDatabase {
        sharedLock.lock()
        defer { sharedLock.unlock() }
        if let existing = sharedInstance { return existing }
        let created = EventDatabase()
        sharedInstance = created
        return created
    }

    private var db: OpaquePointer?
    private let lock = NSLock()

    private init() {
        let path = Self.databasePath()
        if sqlite3_open(path, &db) == SQLITE_OK {
            applySchema()
        } else {
            db = nil
        }
    }

    deinit {
        if let db = db { sqlite3_close(db) }
    }

    private static func databasePath() -> String {
        let fm = FileManager.default
        let appSupport = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("OtplessEventIO", isDirectory: true)
        if !fm.fileExists(atPath: directory.path) {
            try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent(dbName).path
    }

    private func applySchema() {
        guard let db = db else { return }
        let currentVersion = sqlite3_user_version(db)
        if currentVersion == 0 {
            execute(Self.createTable)
            sqlite3_set_user_version(db, Self.dbVersion)
        } else if currentVersion != Self.dbVersion {
            execute("DROP TABLE IF EXISTS \(Self.table)")
            execute(Self.createTable)
            sqlite3_set_user_version(db, Self.dbVersion)
        }
    }

    @discardableResult
    private func execute(_ sql: String) -> Bool {
        guard let db = db else { return false }
        return sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK
    }

    func insertPending(eventType: String, body: String) -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        guard let db = db else { return -1 }
        let sql = "INSERT INTO \(Self.table) (\(Self.colEventType), \(Self.colBody), \(Self.colCreatedAt)) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?
        defer { if stmt != nil { sqlite3_finalize(stmt) } }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return -1 }
        sqlite3_bind_text(stmt, 1, eventType, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, body, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(stmt, 3, Int64(Date().timeIntervalSince1970 * 1000))
        guard sqlite3_step(stmt) == SQLITE_DONE else { return -1 }
        return sqlite3_last_insert_rowid(db)
    }

    func delete(id: Int64) {
        guard id > 0 else { return }
        lock.lock()
        defer { lock.unlock() }
        guard let db = db else { return }
        let sql = "DELETE FROM \(Self.table) WHERE id = ?"
        var stmt: OpaquePointer?
        defer { if stmt != nil { sqlite3_finalize(stmt) } }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_int64(stmt, 1, id)
        sqlite3_step(stmt)
    }

    func markFailed(id: Int64) {
        guard id > 0 else { return }
        lock.lock()
        defer { lock.unlock() }
        guard let db = db else { return }
        let sql = "UPDATE \(Self.table) SET \(Self.colIsSyncFailed) = -1 WHERE id = ?"
        var stmt: OpaquePointer?
        defer { if stmt != nil { sqlite3_finalize(stmt) } }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_int64(stmt, 1, id)
        sqlite3_step(stmt)
    }

    func deleteAllFailed() {
        lock.lock()
        defer { lock.unlock() }
        execute("DELETE FROM \(Self.table) WHERE \(Self.colIsSyncFailed) = -1")
    }

    func getFailed() -> [PendingEvent] {
        lock.lock()
        defer { lock.unlock() }
        guard let db = db else { return [] }
        let sql = "SELECT id, \(Self.colEventType), \(Self.colBody) FROM \(Self.table) WHERE \(Self.colIsSyncFailed) = -1 ORDER BY \(Self.colCreatedAt) ASC"
        var stmt: OpaquePointer?
        defer { if stmt != nil { sqlite3_finalize(stmt) } }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        var results: [PendingEvent] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            guard
                let typePtr = sqlite3_column_text(stmt, 1),
                let bodyPtr = sqlite3_column_text(stmt, 2)
            else { continue }
            let eventType = String(cString: typePtr)
            let body = String(cString: bodyPtr)
            results.append(PendingEvent(id: id, eventType: eventType, body: body))
        }
        return results
    }
}

private func sqlite3_user_version(_ db: OpaquePointer) -> Int32 {
    var stmt: OpaquePointer?
    defer { if stmt != nil { sqlite3_finalize(stmt) } }
    guard sqlite3_prepare_v2(db, "PRAGMA user_version", -1, &stmt, nil) == SQLITE_OK else { return 0 }
    guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
    return sqlite3_column_int(stmt, 0)
}

private func sqlite3_set_user_version(_ db: OpaquePointer, _ version: Int32) {
    sqlite3_exec(db, "PRAGMA user_version = \(version)", nil, nil, nil)
}
