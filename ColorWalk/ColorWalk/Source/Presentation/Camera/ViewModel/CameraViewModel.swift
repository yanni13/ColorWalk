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

    // MARK: - Color Matching
    private let areaAvgFilter: CIFilter? = CIFilter(name: "CIAreaAverage")
    private var frameCount = 0
    private var lastMatchPercent = 0
    private let unitRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    private var missionUIColor: UIColor = ColorMissionStore.shared.mission.value.color

    private enum Constants {
        static let deltaEFrameInterval: Int = 6
        static let maxHueDegrees: CGFloat  = 60.0
        static let maxSatDiff: CGFloat     = 0.7
    }

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

        ColorMissionStore.shared.mission
            .subscribe(onNext: { [weak self] mission in
                self?.missionUIColor = mission.color
            })
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
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
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

    func setZoom(factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self, let input = self.currentInput else { return }
            let device = input.device
            
            do {
                try device.lockForConfiguration()
                let zoom = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
                device.videoZoomFactor = zoom
                device.unlockForConfiguration()
            } catch {
                print("Failed to lock for configuration: \(error)")
            }
        }
    }

    var currentZoomFactor: CGFloat {
        return currentInput?.device.videoZoomFactor ?? 1.0
    }

    // MARK: - Color Detection

    private func detectColor(from image: CIImage) {
        let ext = image.extent
        let sampleRect = CGRect(x: ext.midX - 1, y: ext.midY - 1, width: 2, height: 2).intersection(ext)
        guard !sampleRect.isEmpty else { return }

        areaAvgFilter?.setValue(image.cropped(to: sampleRect), forKey: kCIInputImageKey)
        areaAvgFilter?.setValue(CIVector(cgRect: sampleRect), forKey: "inputExtent")
        guard let avgImage = areaAvgFilter?.outputImage else { return }

        var px = [UInt8](repeating: 0, count: 4)
        ciContext.render(avgImage, toBitmap: &px, rowBytes: 4,
                         bounds: unitRect,
                         format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        let color = UIColor(red: CGFloat(px[0]) / 255,
                            green: CGFloat(px[1]) / 255,
                            blue: CGFloat(px[2]) / 255,
                            alpha: 1)
        let hex   = String(format: "#%02X%02X%02X", px[0], px[1], px[2])
        let match = computeHSBMatch(detected: color)

        DispatchQueue.main.async { [weak self] in
            self?.detectedColor.accept(color)
            self?.detectedHex.accept(hex)
            self?.matchPercent.accept(match)
        }
    }

    // Brightness를 완전히 제외하고 Hue·Saturation만 비교 → 조명 무관
    private func computeHSBMatch(detected: UIColor) -> Int {
        var dH: CGFloat = 0, dS: CGFloat = 0, dB: CGFloat = 0
        var mH: CGFloat = 0, mS: CGFloat = 0, mB: CGFloat = 0

        guard detected.getHue(&dH, saturation: &dS, brightness: &dB, alpha: nil),
              missionUIColor.getHue(&mH, saturation: &mS, brightness: &mB, alpha: nil)
        else { return lastMatchPercent }

        // 원형 색상환 거리 (0.0 ~ 0.5) → 도 단위 변환
        let rawDiff = abs(dH - mH)
        let hueDiff = min(rawDiff, 1.0 - rawDiff) * 360.0
        let satDiff = abs(dS - mS)

        let hueScore = max(0.0, 1.0 - hueDiff / Constants.maxHueDegrees)
        let satScore = max(0.0, 1.0 - satDiff / Constants.maxSatDiff)

        let match = Int(round((hueScore * 0.75 + satScore * 0.25) * 100))
        lastMatchPercent = match
        return match
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
        autoreleasepool {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let original = CIImage(cvPixelBuffer: pixelBuffer)

            frameCount += 1
            if frameCount % Constants.deltaEFrameInterval == 0 {
                detectColor(from: original)
            }

            let filtered = apply(currentFilter.value, to: original)
            guard let cg = ciContext.createCGImage(filtered, from: filtered.extent) else { return }
            let uiImage  = UIImage(cgImage: cg)

            DispatchQueue.main.async { [weak self] in
                self?.previewImage.accept(uiImage)
            }
        }
    }
}
