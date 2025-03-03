import SwiftUI
import CoreGraphics

struct CameraView: View {
    
    @StateObject private var model = CameraModeViewModel()
    
    var body: some View {
        if let image = model.backCameraFrame {
            Image(image, scale: 1.0, orientation: .up, label: Text(""))
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Color.black
        }
    }
    
}
