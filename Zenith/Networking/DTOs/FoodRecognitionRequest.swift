import Foundation

struct FoodRecognitionRequest: Codable {
    let imageBase64: String
    let requestId: String
}
