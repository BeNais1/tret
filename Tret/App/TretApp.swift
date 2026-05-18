import SwiftUI
import FirebaseCore

@main
struct TretApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(nil)
                .task {
                    appState.bootstrap()
                }
        }
    }
}
