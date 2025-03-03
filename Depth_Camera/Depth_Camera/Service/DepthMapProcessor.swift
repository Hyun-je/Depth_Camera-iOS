import Combine
import Vision
import CoreImage

class DepthMapProcessor {
    
    private let model = try! DepthAnythingV2SmallF16()
    private lazy var request: VNCoreMLRequest = {
        
        guard let visionModel = try? VNCoreMLModel(for: model.model)
        else {
            fatalError("📡 DepthEstimation configure : Fail")
        }
        
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFill
        
        return request
    }()
    

    
    public func predict(_ ciImage: CIImage, invert: Bool = false) -> CIImage? {
    
        let handler = VNImageRequestHandler(ciImage: ciImage)
        guard let depthMap = predict(handler)
        else { return nil }
        
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
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        guard let depthMap = predict(handler)
        else { return nil }
        
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
        
        try? handler.perform([request])
        
        guard let predictions = request.results as? [VNPixelBufferObservation],
              let pixelBuffer = predictions.first?.pixelBuffer
        else { return nil }
        
        return CIImage(cvPixelBuffer: pixelBuffer)
        
    }
    
}
