//
//  CameraViewModel.swift
//  ColorWalk
//

import UIKit
import AVFoundation
import CoreImage
import RxSwift
import RxCocoa

// MARK: - Filter

enum CameraFilter: String, CaseIterable {
    case normal = "노멀"
    case warm   = "따뜻하게"
    case cool   = "차갑게"
    case vivid  = "선명하게"
    case soft   = "부드럽게"
    case mono   = "흑백"
}

// MARK: - ViewModel

final class CameraViewModel: NSObject {

    // MARK: Session
    let session      = AVCaptureSession()
    private let videoOutput  = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session")
    private let renderQueue  = DispatchQueue(label: "camera.render")
    private var currentInput: AVCaptureDeviceInput?

    // MARK: Outputs
    let previewImage  = PublishRelay<UIImage?>()
    let detectedColor = BehaviorRelay<UIColor>(value: .gray)
    let detectedHex   = BehaviorRelay<String>(value: "#888888")
    let matchPercent  = BehaviorRelay<Int>(value: 0)
    let currentFilter = BehaviorRelay<CameraFilter>(value: .normal)
    let missionName   = BehaviorRelay<String>(value: ColorMissionStore.shared.mission.value.name)
    let missionColor  = BehaviorRelay<UIColor>(value: ColorMissionStore.shared.mission.value.color)

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let disposeBag = DisposeBag()

    override init() {
        super.init()
        
        ColorMissionStore.shared.mission
            .map { $0.name }
            .bind(to: missionName)
            .disposed(by: disposeBag)
            
        ColorMissionStore.shared.mission
            .map { $0.color }
            .bind(to: missionColor)
            .disposed(by: disposeBag)
    }

    // MARK: - Session Setup

    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1280x720

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input  = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration(); return
            }
            self.session.addInput(input)
            self.currentInput = input

            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            self.videoOutput.setSampleBufferDelegate(self, queue: self.renderQueue)
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }
            if let conn = self.videoOutput.connection(with: .video) {
                conn.videoOrientation = .portrait
            }
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self, let cur = self.currentInput else { return }
            let nextPos: AVCaptureDevice.Position = cur.device.position == .back ? .front : .back
            guard
                let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: nextPos),
                let newInput = try? AVCaptureDeviceInput(device: dev)
            else { return }
            self.session.beginConfiguration()
            self.session.removeInput(cur)
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentInput = newInput
            }
            if let conn = self.videoOutput.connection(with: .video) {
                conn.videoOrientation = .portrait
            }
            self.session.commitConfiguration()
        }
    }

    func setFilter(_ filter: CameraFilter) {
        currentFilter.accept(filter)
    }

    // MARK: - Color Detection

    private func detectColor(from image: CIImage) {
        let ext = image.extent
        let rect = CGRect(x: ext.midX - 1, y: ext.midY - 1, width: 2, height: 2).intersection(ext)
        guard !rect.isEmpty,
              let avg = CIFilter(name: "CIAreaAverage", parameters: [
                  kCIInputImageKey: image.cropped(to: rect),
                  "inputExtent": CIVector(cgRect: rect)
              ])?.outputImage
        else { return }

        var px = [UInt8](repeating: 0, count: 4)
        ciContext.render(avg, toBitmap: &px, rowBytes: 4,
                         bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                         format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        let r = CGFloat(px[0]) / 255
        let g = CGFloat(px[1]) / 255
        let b = CGFloat(px[2]) / 255
        let color = UIColor(red: r, green: g, blue: b, alpha: 1)
        let hex   = String(format: "#%02X%02X%02X", px[0], px[1], px[2])
        let match = colorMatch(r: r, g: g, b: b)

        DispatchQueue.main.async { [weak self] in
            self?.detectedColor.accept(color)
            self?.detectedHex.accept(hex)
            self?.matchPercent.accept(match)
        }
    }

    private func colorMatch(r: CGFloat, g: CGFloat, b: CGFloat) -> Int {
        var mr: CGFloat = 0, mg: CGFloat = 0, mb: CGFloat = 0, a: CGFloat = 0
        missionColor.value.getRed(&mr, green: &mg, blue: &mb, alpha: &a)
        let dist = sqrt(pow(r - mr, 2) + pow(g - mg, 2) + pow(b - mb, 2))
        return max(0, min(100, Int((1 - dist / sqrt(3)) * 100)))
    }

    // MARK: - Filter Application

    func apply(_ filter: CameraFilter, to image: CIImage) -> CIImage {
        switch filter {
        case .normal:
            return image

        case .warm:
            return image.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.15, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1.02, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.78, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])

        case .cool:
            return image.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0.82, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1.0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1.22, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])

        case .vivid:
            return image
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 1.9,
                    kCIInputContrastKey:   1.15
                ])

        case .soft:
            return image
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey:  0.65,
                    kCIInputBrightnessKey:  0.04
                ])
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 1.2])

        case .mono:
            return image.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0
            ])
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let original = CIImage(cvPixelBuffer: pixelBuffer)

        detectColor(from: original)

        let filtered  = apply(currentFilter.value, to: original)
        guard let cg  = ciContext.createCGImage(filtered, from: filtered.extent) else { return }
        let uiImage   = UIImage(cgImage: cg)

        DispatchQueue.main.async { [weak self] in
            self?.previewImage.accept(uiImage)
        }
    }
}
