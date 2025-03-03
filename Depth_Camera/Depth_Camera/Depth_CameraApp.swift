import SwiftUI

@main
struct Depth_CameraApp: App {
    var body: some Scene {
        WindowGroup {
            CameraView()
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
        }
    }
}
