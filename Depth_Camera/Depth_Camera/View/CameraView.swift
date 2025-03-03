import SwiftUI
import CoreGraphics
import Combine

struct CameraView: View {
    
    @StateObject private var model = CameraModeViewModel()
    
    var body: some View {
        ZStack {
            if let image = model.backCameraFrame {
                Image(image, scale: 1.0, orientation: .up, label: Text(""))
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Color.black
            }
            
            if !model.isModelReady {
                Text("Depth Map Loading...")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
    }
    
}
