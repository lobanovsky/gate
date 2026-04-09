import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            Group {
                if appModel.isAuthenticated {
                    GatesView()
                } else {
                    LoginView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert(item: $appModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

