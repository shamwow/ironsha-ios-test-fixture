import Foundation

struct SyncDownloadRequest: Codable {
    let deviceId: String
    let lastSyncTimestamp: Date?
}
