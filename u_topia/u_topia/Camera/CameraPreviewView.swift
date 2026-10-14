//
//  CameraPreviewView.swift
//  u_topia
//

import SwiftUI
import AVFoundation
import UIKit

public struct CameraPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public var body: some View {
        ZStack {
            if cameraManager.isCameraAvailable && !cameraManager.isDisconnected {
                RealCameraViewRepresentable(session: cameraManager.session)
                    .edgesIgnoringSafeArea(.all)
            } else if cameraManager.isRequestingAuthorization {
                Color(uiColor: .systemBackground).edgesIgnoringSafeArea(.all)
                    .overlay {
                        ProgressView("Requesting camera access…")
                            .tint(.primary)
                    }
            } else if cameraManager.authorizationStatus == .denied || cameraManager.authorizationStatus == .restricted {
                CameraPermissionView {
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(settingsURL)
                }
            } else {
                DisconnectedCameraView()
            }
        }
    }
}

private struct CameraPermissionView: View {
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 30))
                .foregroundStyle(.blue)
            Text("Camera access is off")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Allow camera access in Settings to scan prices and change.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Open Settings", action: openSettings)
                .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

private struct RealCameraViewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraUIView {
        let view = CameraUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: CameraUIView, context: Context) {}
}

private class CameraUIView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

public struct DisconnectedCameraView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appCard)
                        .frame(width: 76, height: 76)
                    
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text("Camera has disconnected")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Camera is unavailable on this device")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}
