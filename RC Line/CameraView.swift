import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    var allowsEditing: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = allowsEditing
        picker.delegate = context.coordinator
        picker.cameraCaptureMode = .photo
        picker.cameraDevice =
            UserDefaults.standard.bool(forKey: "priorityFrontCamera") ? .front : .rear
        picker.modalPresentationStyle = .fullScreen

        if let screen = picker.view.window?.windowScene?.screen {
            picker.view.frame = screen.bounds
        }

        picker.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate,
        UINavigationControllerDelegate
    {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let key: UIImagePickerController.InfoKey =
                parent.allowsEditing ? .editedImage : .originalImage
            if let img = info[key] as? UIImage {
                parent.image = img
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
