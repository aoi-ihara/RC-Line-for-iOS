import AVFoundation
import SwiftUI
@preconcurrency import Vision

func performOCR(on image: UIImage, completion: @escaping @Sendable (String) -> Void) {
    guard let cgImage = image.cgImage else {
        DispatchQueue.main.async { completion("OCRエラー: 画像を処理できません。") }
        return
    }

    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation],
            error == nil
        else {
            DispatchQueue.main.async { completion("OCRエラー: テキスト認識に失敗しました。") }
            return
        }

        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")

        DispatchQueue.main.async { completion(recognizedText) }
    }

    let ocrMode = UserDefaults.standard.integer(forKey: "ocrMode")
    request.recognitionLevel = ((ocrMode == 0) ? .accurate : .fast)
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["ja-JP", "en-US", "en-UK"]

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async { completion("OCRエラー: リクエストの実行に失敗しました: \(error.localizedDescription)") }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)

            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImagePicked(uiImage)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
