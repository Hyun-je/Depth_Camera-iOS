//
//  CameraSession.swift
//  Landscape_Decoder-iOS
//
//  Created by Jaehyeon Park on 2023/03/24.
//

import Combine
import AVFoundation


class CameraSession: NSObject {
    
    private let session = AVCaptureMultiCamSession()
    private let backCameraVideoDataOutput = AVCaptureVideoDataOutput()
    
    private let outputQueue = DispatchQueue(label: "outputQueue")
    
    private let backCameraSubject = PassthroughSubject<CVPixelBuffer, Never>()
    public let backCameraPublisher: AnyPublisher<CVPixelBuffer, Never>
    
    private(set) var externalCamera = false
    
    
    override init() {
        
        backCameraPublisher = backCameraSubject.eraseToAnyPublisher()

    }
    
    
    func configure() {
        
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            assertionFailure("📷 CameraSession configure : Fail")
            return
        }
        
        session.beginConfiguration()

        configureBackCamera(prefered: [.builtInUltraWideCamera])
        
        session.commitConfiguration()
        
        print("📷 CameraSession configure : Success")
    }
    
    func start() {
        
        session.startRunning()
        
        print("📷 CameraSession Start")
    }
    
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard
            let output = output as? AVCaptureVideoDataOutput,
            let buffer = sampleBuffer.imageBuffer
        else { return }
        
        if output == backCameraVideoDataOutput {
            backCameraSubject.send(buffer)
        }

    }
    
}


fileprivate extension CameraSession {
    
    func configureBackCamera(prefered: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]) {
        
        var devices = [AVCaptureDevice]()
        
        if #available(iOS 17.0, *) {
            let externalVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
            devices += externalVideoDeviceDiscoverySession.devices
            if devices.count > 0 {
                externalCamera = true
            }
        }
        
        let backVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: prefered, mediaType: .video, position: .back)
        devices += backVideoDeviceDiscoverySession.devices
        
        
        guard let device = devices.first,
            let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        configureInput(input, targetDims: CMVideoDimensions(width: 1280, height: 720))
        
        if session.canAddInput(input) {
            session.addInputWithNoConnections(input)
        }

        backCameraVideoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        backCameraVideoDataOutput.setSampleBufferDelegate(self, queue: outputQueue)
        if session.canAddOutput(backCameraVideoDataOutput) {
            session.addOutputWithNoConnections(backCameraVideoDataOutput)
        }

        let port = input.ports(for: .video, sourceDeviceType: device.deviceType, sourceDevicePosition: device.position)
        let connection = AVCaptureConnection(inputPorts: port, output: backCameraVideoDataOutput)
        connection.videoOrientation = .landscapeLeft

        if session.canAddConnection(connection) {
            session.addConnection(connection)
        }

    }
    
    func configureInput(_ input: AVCaptureDeviceInput, targetDims: CMVideoDimensions) {
        
        try? input.device.lockForConfiguration()
        defer {
            input.device.unlockForConfiguration()
        }
        
        for format in input.device.formats.filter({$0.isMultiCamSupported}) {
            
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            
            if dims.width == targetDims.width && dims.height == targetDims.height {
                print(input.device, dims)
                input.device.activeFormat = format
            }

        }
        
        if !externalCamera {
            input.device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 15)
            input.device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 25)
        }

    }
    
}
