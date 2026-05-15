import SwiftUI
import UIKit
import ARKit
import SceneKit

class EyeTrackingViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    
    var onBlink: (() -> Void)?
    var onLeftWink: (() -> Void)?
    var onRightWink: (() -> Void)?
    
    private var blinked = false
    private var leftWinked = false
    private var rightWinked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(sceneView)
        
        sceneView.scene = SCNScene()
        sceneView.delegate = self

        if !ARFaceTrackingConfiguration.isSupported {
            print("非対応")
            return
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTracking()
    }
    
    func startTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stopTracking() {
        sceneView.session.pause()
    }
    
    nonisolated func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        let leftBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
        let rightBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0
        
        Task { @MainActor in
            handleEyeStates(leftBlink: leftBlink, rightBlink: rightBlink)
        }
    }
    
    @MainActor
    private func handleEyeStates(leftBlink: Float, rightBlink: Float) {
        if leftBlink > 0.25 && rightBlink > 0.25 {
            if !blinked {
                onBlink?()
                blinked = true
            }
        } else {
            blinked = false
        }
        
        if leftBlink > 0.5 && rightBlink < 0.3 {
            if !leftWinked {
                onLeftWink?()
                leftWinked = true
            }
        } else {
            leftWinked = false
        }
        
        if rightBlink > 0.5 && leftBlink < 0.3 {
            if !rightWinked {
                onRightWink?()
                rightWinked = true
            }
        } else {
            rightWinked = false
        }
    }
}

struct EyeTrackingView: UIViewControllerRepresentable {
    var onBlink: () -> Void
    var onLeftWink: () -> Void
    var onRightWink: () -> Void
    var isActive: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> EyeTrackingViewController {
        let vc = EyeTrackingViewController()
        vc.onBlink = onBlink
        vc.onLeftWink = onLeftWink
        vc.onRightWink = onRightWink
        return vc
    }
    
    func updateUIViewController(_ uiViewController: EyeTrackingViewController, context: Context) {
        uiViewController.onBlink = onBlink
        uiViewController.onLeftWink = onLeftWink
        uiViewController.onRightWink = onRightWink
        
        if isActive {
            uiViewController.startTracking()
        } else {
            uiViewController.stopTracking()
        }
    }
    
    class Coordinator: NSObject {
        var parent: EyeTrackingView
        init(_ parent: EyeTrackingView) {
            self.parent = parent
        }
    }
}

struct EyeTrackingContainer: View {
    @Binding var eyeTracking: Bool
    let onBlink: () -> Void
    let onLeftWink: () -> Void
    let onRightWink: () -> Void
    
    var body: some View {
        ZStack {
            EyeTrackingView(
                onBlink: onBlink,
                onLeftWink: onLeftWink,
                onRightWink: onRightWink,
                isActive: eyeTracking
            )
            .ignoresSafeArea()
            
            if !ARFaceTrackingConfiguration.isSupported {
                Text("Face Tracking 非対応")
                    .foregroundStyle(.red)
                    .font(.title)
                    .padding()
                    .background(.black.opacity(0.7))
                    .cornerRadius(12)
            }
        }
    }
}
