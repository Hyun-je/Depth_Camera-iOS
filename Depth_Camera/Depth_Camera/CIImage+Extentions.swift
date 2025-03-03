import CoreImage

extension CIImage {
    
    var cgImage: CGImage? {
        
        let ciContext = CIContext(options: nil)
        let cgImage = ciContext.createCGImage(self, from: self.extent)
        
        return cgImage
    }
    
    func resize(_ scale: Float, aspectRatio: Float) -> CIImage {
        
        return self.applyingFilter(
            "CILanczosScaleTransform",
            parameters: [
                "inputScale": scale,
                "inputAspectRatio": aspectRatio
            ]
        )
        
    }
    
    func resize(size: CGSize) -> CIImage {
        
        let scale = size.height / self.extent.height
        let aspectRatio = size.width / (self.extent.width * scale)

        return self.resize(Float(scale), aspectRatio: Float(aspectRatio))
        
    }
    
    func invert() -> CIImage {
        
        return self.applyingFilter(
            "CIColorInvert",
            parameters: [:]
        )
        
    }
    
}
