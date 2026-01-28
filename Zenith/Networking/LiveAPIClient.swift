import Foundation

struct LiveAPIClient: APIClient {
    private let baseURL = "https://api.example.com/api/v1"
    private let session = URLSession.shared
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func recognizeFood(request: FoodRecognitionRequest) async throws -> FoodRecognitionResponse {
        let url = URL(string: "\(baseURL)/food/recognize")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)

        let (data, _) = try await session.data(for: urlRequest)
        return try decoder.decode(FoodRecognitionResponse.self, from: data)
    }

    func uploadSync(request: SyncUploadRequest) async throws -> SyncUploadResponse {
        let url = URL(string: "\(baseURL)/sync/upload")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)

        let (data, _) = try await session.data(for: urlRequest)
        return try decoder.decode(SyncUploadResponse.self, from: data)
    }

    func downloadSync(request: SyncDownloadRequest) async throws -> SyncDownloadResponse {
        let url = URL(string: "\(baseURL)/sync/download")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)

        let (data, _) = try await session.data(for: urlRequest)
        return try decoder.decode(SyncDownloadResponse.self, from: data)
    }
}
