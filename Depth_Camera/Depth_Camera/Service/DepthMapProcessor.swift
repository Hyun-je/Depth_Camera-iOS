import Combine
import Vision
import CoreImage

class DepthMapProcessor {
    
    private var model: DepthAnythingV2SmallF16?
    private var request: VNCoreMLRequest?
    @Published public private(set) var isModelReady = false
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.model = try DepthAnythingV2SmallF16()
                if let visionModel = try? VNCoreMLModel(for: self.model!.model) {
                    let request = VNCoreMLRequest(model: visionModel)
                    request.imageCropAndScaleOption = .scaleFill
                    self.request = request
                    self.isModelReady = true
                }
            } catch {
                print("📡 DepthEstimation configure : Fail - \(error)")
            }
        }
    }
    
    public func predict(_ ciImage: CIImage, invert: Bool = false) -> CIImage? {
        guard isModelReady, let request = request else { return ciImage }
    
        let handler = VNImageRequestHandler(ciImage: ciImage)
        guard let depthMap = predict(handler)
        else { return ciImage }
        
        if invert {
            return depthMap
                .invert()
                .resize(size: ciImage.extent.size)
        }
        else {
            return depthMap
                .resize(size: ciImage.extent.size)
        }
    }
    
    public func predict(_ pixelBuffer: CVPixelBuffer, invert: Bool = false) -> CIImage? {
        guard isModelReady, let request = request else { 
            return CIImage(cvPixelBuffer: pixelBuffer)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        guard let depthMap = predict(handler)
        else { return CIImage(cvPixelBuffer: pixelBuffer) }
        
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        
        if invert {
            return depthMap
                .invert()
                .resize(size: .init(width: width, height: height))
        }
        else {
            return depthMap
                .resize(size: .init(width: width, height: height))
        }
    }
    
    private func predict(_ handler: VNImageRequestHandler) -> CIImage? {
        guard let request = request else { return nil }
        
        try? handler.perform([request])
        
        guard let predictions = request.results as? [VNPixelBufferObservation],
              let pixelBuffer = predictions.first?.pixelBuffer
        else { return nil }
        
        return CIImage(cvPixelBuffer: pixelBuffer)
    }
    
}
