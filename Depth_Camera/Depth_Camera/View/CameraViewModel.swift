import SwiftUI
import Combine
import Vision
import CoreImage
import CoreGraphics

class CameraModeViewModel: ObservableObject {
    
    private let cameraSession = CameraSession()
    private let depthMapProcessor = DepthMapProcessor()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var backCameraFrame: CGImage?
    @Published var isModelReady: Bool = false
    
    var backCameraQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    init() {
        // Observe model loading status
        depthMapProcessor.$isModelReady
            .receive(on: RunLoop.main)
            .assign(to: &$isModelReady)
        
        cameraSession.backCameraPublisher
            .receive(on: backCameraQueue)
            .compactMap { pixelBuffer in
                var inputImage = CIImage(cvPixelBuffer: pixelBuffer)
                inputImage = inputImage.oriented(.down)
                
                guard let processedImage = self.depthMapProcessor.predict(inputImage) else {
                    return inputImage.cgImage
                }
                
                self.backCameraQueue.cancelAllOperations()
                
                return processedImage.cgImage
            }
            .receive(on: RunLoop.main)
            .assign(to: &$backCameraFrame)
        
        cameraSession.configure()
        cameraSession.start()
    }
}
    
