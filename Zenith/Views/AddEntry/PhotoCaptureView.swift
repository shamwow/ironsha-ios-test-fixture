import SwiftUI
import UIKit

struct PhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isRecognizing = false
    @State private var recognitionResult: RecognizedFood?
    @State private var errorMessage: String?

    let onFoodRecognized: (String, Int, Double, Double, Double) -> Void

    var body: some View {
        VStack(spacing: 20) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isRecognizing {
                    ProgressView("Recognizing food...")
                } else if let result = recognitionResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.name)
                            .font(.headline)
                        Text("\(result.calories) kcal per serving")
                        HStack {
                            MacroLabel("P", value: result.protein, color: .proteinColor)
                            MacroLabel("F", value: result.fat, color: .fatColor)
                            MacroLabel("C", value: result.carbs, color: .carbsColor)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                    Button("Use This Food") {
                        onFoodRecognized(result.name, result.calories, result.protein, result.fat, result.carbs)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }

                Button("Retake Photo") {
                    capturedImage = nil
                    recognitionResult = nil
                    errorMessage = nil
                    showCamera = true
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)

                    Text("Take a photo of your food")
                        .font(.headline)

                    Button("Open Camera") {
                        showCamera = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .navigationTitle("Photo Recognition")
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newImage in
            if newImage != nil {
                recognizeFood()
            }
        }
    }

    private func recognizeFood() {
        isRecognizing = true
        errorMessage = nil

        let service = PhotoRecognitionService(apiClient: MockAPIClient())
        Task {
            do {
                let response = try await service.recognize(image: capturedImage!)
                if response.recognized, let candidate = response.candidates.first {
                    recognitionResult = RecognizedFood(
                        name: candidate.name,
                        calories: candidate.calories,
                        protein: candidate.proteinGrams,
                        fat: candidate.fatGrams,
                        carbs: candidate.carbsGrams
                    )
                } else {
                    errorMessage = response.errorMessage ?? "Could not recognize food."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isRecognizing = false
        }
    }
}

private struct RecognizedFood {
    let name: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        #if targetEnvironment(simulator)
        picker.sourceType = .photoLibrary
        #else
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        #endif
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
