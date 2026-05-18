import SwiftUI
import FirebaseCore

@main
struct TretApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState: AppState

    init() {
        // FirebaseApp.configure() ДОЛЖЕН отработать ДО того, как сервисы
        // (UserService.shared и т.п.) первый раз вызовут Firestore.firestore()
        // при инициализации AppState. AppDelegate.didFinishLaunching фактически
        // запускается ПОСЛЕ конструирования App-структуры с её @State полями,
        // поэтому конфигурируем здесь явно.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        _appState = State(initialValue: AppState())
    }

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
