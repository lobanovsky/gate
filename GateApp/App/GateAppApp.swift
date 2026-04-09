import SwiftUI

@main
struct GateAppApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .task {
                    await appModel.bootstrap()
                }
        }
    }
}

