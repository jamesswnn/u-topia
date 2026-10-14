//
//  CameraManager.swift
//  u_topia
//

import Foundation
import AVFoundation
import SwiftUI
import Combine
import Vision
import ImageIO
import UIKit

public struct CameraScanResult {
    public let amount: Double?
    public let imageData: Data?

    public init(amount: Double?, imageData: Data?) {
        self.amount = amount
        self.imageData = imageData
    }
}

public final class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published public var isCameraAvailable: Bool = false
    @Published public var isDisconnected: Bool = false
    @Published public var isRequestingAuthorization: Bool = false
    @Published public var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published public var isLiveGuideTrackingEnabled = false {
        didSet {
            trackingLock.lock()
            liveTrackingEnabled = isLiveGuideTrackingEnabled
            trackingLock.unlock()
            if !isLiveGuideTrackingEnabled {
                DispatchQueue.main.async { self.liveDetectedTextBox = nil }
                visionQueue.async { self.lastLiveDetectedTextBox = nil }
            }
        }
    }
    @Published public private(set) var liveDetectedTextBox: CGRect?
    
    public let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "u_topia.camera.sessionQueue")
    private let visionQueue = DispatchQueue(label: "u_topia.camera.liveOCR")
    private let trackingLock = NSLock()
    private var liveTrackingEnabled = false
    private var lastVisionRunAt = Date.distantPast
    private var lastLiveDetectedTextBox: CGRect?
    private var photoProcessor: PhotoTextProcessor?
    private var authorizationRequestInFlight = false
    
    public override init() {
        super.init()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        #if targetEnvironment(simulator)
        self.isCameraAvailable = false
        self.isDisconnected = true
        #else
        checkAuthorization()
        #endif
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    public func checkAuthorization() {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.isCameraAvailable = false
            self.isDisconnected = true
        }
        #else
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = status
        
        switch status {
        case .authorized:
            DispatchQueue.main.async {
                self.isRequestingAuthorization = false
                self.isDisconnected = false
            }
            setupSession()
        case .notDetermined:
            guard !authorizationRequestInFlight else { return }
            authorizationRequestInFlight = true
            isRequestingAuthorization = true
            isDisconnected = false
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationRequestInFlight = false
                    self?.isRequestingAuthorization = false
                    self?.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.isCameraAvailable = false
                        self?.isDisconnected = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isRequestingAuthorization = false
                self.isCameraAvailable = false
                self.isDisconnected = true
            }
        @unknown default:
            DispatchQueue.main.async {
                self.isRequestingAuthorization = false
                self.isCameraAvailable = false
                self.isDisconnected = true
            }
        }
        #endif
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            #if targetEnvironment(simulator)
            DispatchQueue.main.async {
                self.isCameraAvailable = false
                self.isDisconnected = true
            }
            #else
            guard !self.session.isRunning else {
                DispatchQueue.main.async {
                    self.isCameraAvailable = true
                    self.isDisconnected = false
                }
                return
            }

            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                    self.isDisconnected = true
                }
                return
            }
            
            do {
                self.session.beginConfiguration()
                if self.session.inputs.isEmpty {
                    let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                    guard self.session.canAddInput(videoInput) else {
                        self.session.commitConfiguration()
                        DispatchQueue.main.async {
                            self.isCameraAvailable = false
                            self.isDisconnected = true
                        }
                        return
                    }
                    self.session.addInput(videoInput)
                }
                if !self.session.outputs.contains(where: { $0 === self.photoOutput }) {
                    guard self.session.canAddOutput(self.photoOutput) else {
                        self.session.commitConfiguration()
                        DispatchQueue.main.async { self.isCameraAvailable = false; self.isDisconnected = true }
                        return
                    }
                    self.session.addOutput(self.photoOutput)
                }
                if !self.session.outputs.contains(where: { $0 === self.videoOutput }) {
                    self.videoOutput.videoSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                    ]
                    self.videoOutput.alwaysDiscardsLateVideoFrames = true
                    self.videoOutput.setSampleBufferDelegate(self, queue: self.visionQueue)
                    guard self.session.canAddOutput(self.videoOutput) else {
                        self.session.commitConfiguration()
                        DispatchQueue.main.async { self.isCameraAvailable = false; self.isDisconnected = true }
                        return
                    }
                    self.session.addOutput(self.videoOutput)
                }
                self.session.commitConfiguration()
                
                self.session.startRunning()
                DispatchQueue.main.async {
                    let running = self.session.isRunning
                    self.isCameraAvailable = running
                    self.isDisconnected = !running
                }
            } catch {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                    self.isDisconnected = true
                }
            }
            #endif
        }
    }
    
    public func startSession() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if currentStatus != .authorized {
            checkAuthorization()
            return
        }
        setupSession()
    }

    public func retryAuthorization() {
        checkAuthorization()
    }

    public func captureAmount(completion: @escaping (CameraScanResult) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning,
                  self.session.outputs.contains(where: { $0 === self.photoOutput }) else {
                DispatchQueue.main.async { completion(CameraScanResult(amount: nil, imageData: nil)) }
                return
            }
            let settings = AVCapturePhotoSettings()
            let processor = PhotoTextProcessor { amount, imageData in
                DispatchQueue.main.async { completion(CameraScanResult(amount: amount, imageData: imageData)) }
                self.sessionQueue.async { self.photoProcessor = nil }
            }
            self.photoProcessor = processor
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        trackingLock.lock()
        let shouldTrack = liveTrackingEnabled
        trackingLock.unlock()
        guard shouldTrack else { return }

        let now = Date()
        guard now.timeIntervalSince(lastVisionRunAt) >= 0.3,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastVisionRunAt = now

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                      orientation: currentImageOrientation,
                                      options: [:]).perform([request])
            let boxes = (request.results ?? []).compactMap { observation -> (box: CGRect, confidence: Float)? in
                guard let candidate = observation.topCandidates(1).first,
                      candidate.confidence >= 0.45 else { return nil }
                let normalized = candidate.string.replacingOccurrences(of: ",", with: "")
                guard normalized.range(of: #"\d+(?:\.\d+)?"#, options: .regularExpression) != nil else { return nil }
                return (observation.boundingBox, candidate.confidence)
            }
            guard !boxes.isEmpty else { return }

            let previous = lastLiveDetectedTextBox
            let match = boxes.max { first, second in
                trackingScore(first, previous: previous) < trackingScore(second, previous: previous)
            }
            guard let match else { return }
            lastLiveDetectedTextBox = match.box
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.trackingLock.lock()
                let stillTracking = self.liveTrackingEnabled
                self.trackingLock.unlock()
                if stillTracking { self.liveDetectedTextBox = match.box }
            }
        } catch {
            // Live tracking is a visual guide only; still-photo OCR reports scan errors.
        }
    }

    private func trackingScore(_ candidate: (box: CGRect, confidence: Float), previous: CGRect?) -> Double {
        guard let previous else { return Double(candidate.confidence) }
        let dx = candidate.box.midX - previous.midX
        let dy = candidate.box.midY - previous.midY
        let distance = hypot(dx, dy)
        return Double(candidate.confidence) - Double(distance) * 0.45
    }

    private var currentImageOrientation: CGImagePropertyOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft: return .up
        case .landscapeRight: return .down
        case .portraitUpsideDown: return .left
        case .portrait, .faceUp, .faceDown, .unknown: return .right
        @unknown default: return .right
        }
    }
    
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            #if !targetEnvironment(simulator)
            if self.session.isRunning {
                self.session.stopRunning()
            }
            #endif
        }
    }
}

private final class PhotoTextProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Double?, Data?) -> Void

    init(completion: @escaping (Double?, Data?) -> Void) { self.completion = completion }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation() else { completion(nil, nil); return }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        do {
            try VNImageRequestHandler(data: data).perform([request])
            let candidates = (request.results ?? []).compactMap { observation -> (amount: Double, score: Double)? in
                guard let recognized = observation.topCandidates(1).first else { return nil }
                let normalized = recognized.string.replacingOccurrences(of: ",", with: "")
                guard let range = normalized.range(of: #"\d+(?:\.\d+)?"#, options: .regularExpression),
                      let amount = Double(normalized[range]), amount > 0 else { return nil }
                let box = observation.boundingBox
                let centerDistance = Double(hypot(box.midX - 0.5, box.midY - 0.5))
                let isInsideGuide = (0.2...0.8).contains(box.midX) && (0.2...0.8).contains(box.midY)
                let centerScore = isInsideGuide ? 1.0 - centerDistance : 0.0 - centerDistance
                return (amount, Double(recognized.confidence) + centerScore)
            }
            completion(candidates.max(by: { $0.score < $1.score })?.amount, data)
        } catch {
            completion(nil, data)
        }
    }
}
