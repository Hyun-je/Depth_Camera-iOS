import SwiftUI
import Combine
import Vision
import CoreImage
import CoreGraphics

class CameraModeViewModel: ObservableObject {
    
    private let cameraSession = CameraSession()
    private let depthMapProcessor = DepthMapProcessor()
    
    
    @Published var backCameraFrame: CGImage?
    
    var backCameraQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    init() {
        
        cameraSession.backCameraPublisher
            .receive(on: backCameraQueue)
            .compactMap { pixelBuffer in
                var inputImage = CIImage(cvPixelBuffer: pixelBuffer)
                inputImage = inputImage.oriented(.down)
                
                let depthMap = self.depthMapProcessor.predict(inputImage)!
                
                self.backCameraQueue.cancelAllOperations()
                
                return depthMap.cgImage
            }
            .receive(on: RunLoop.main)
            .assign(to: &$backCameraFrame)
        
        cameraSession.configure()
        cameraSession.start()
        
    }
}
    
