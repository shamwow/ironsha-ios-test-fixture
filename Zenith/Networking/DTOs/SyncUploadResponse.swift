import Foundation

struct SyncUploadResponse: Codable {
    let serverTimestamp: Date
    let conflictCount: Int
    let success: Bool
}
