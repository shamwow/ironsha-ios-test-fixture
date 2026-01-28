import Foundation

struct FoodRecognitionResponse: Codable {
    let requestId: String
    let recognized: Bool
    let candidates: [FoodCandidate]
    let errorMessage: String?
}

struct FoodCandidate: Codable, Identifiable {
    let id: String
    let name: String
    let confidence: Double
    let calories: Int
    let proteinGrams: Double
    let fatGrams: Double
    let carbsGrams: Double
    let servingDescription: String
}
