import Foundation
import UIKit

struct PhotoRecognitionService {
    let apiClient: APIClient

    func recognize(image: UIImage) async throws -> FoodRecognitionResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return FoodRecognitionResponse(
                requestId: UUID().uuidString,
                recognized: false,
                candidates: [],
                errorMessage: "Failed to process image."
            )
        }

        let base64 = imageData.base64EncodedString()
        let request = FoodRecognitionRequest(
            imageBase64: base64,
            requestId: UUID().uuidString
        )

        return try await apiClient.recognizeFood(request: request)
    }
}
