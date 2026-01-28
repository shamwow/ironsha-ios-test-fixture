import Foundation

protocol APIClient {
    func recognizeFood(request: FoodRecognitionRequest) async throws -> FoodRecognitionResponse
    func uploadSync(request: SyncUploadRequest) async throws -> SyncUploadResponse
    func downloadSync(request: SyncDownloadRequest) async throws -> SyncDownloadResponse
}
