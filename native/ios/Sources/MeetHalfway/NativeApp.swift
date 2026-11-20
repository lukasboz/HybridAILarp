import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
@MainActor
struct MeetHalfwayApp: App {
    @StateObject private var store: MeetStore
    init() { NativeFirebase.configureIfPresent(); _store = StateObject(wrappedValue:MeetStore()) }
    var body: some Scene {
        WindowGroup {
            MeetRootView().environmentObject(store).preferredColorScheme(.light).tint(MHDesign.accent)
                .task {await store.connect()}
                .onOpenURL {store.pendingInvite = $0.absoluteString;store.sheet = .join}
        }
    }
}
enum NativeFirebase {
    static func configureIfPresent() {
        guard FirebaseApp.app() == nil, let url = Bundle.main.url(forResource:"NativeConfig",withExtension:"plist"),
          let v = NSDictionary(contentsOf:url) as? [String:String], let id = v["GOOGLE_APP_ID"], !id.isEmpty,
          let sender = v["GCM_SENDER_ID"], let key = v["API_KEY"], !key.isEmpty, let project = v["PROJECT_ID"] else {return}
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(MeetAttestationFactory())
        #endif
        let options = FirebaseOptions(googleAppID:id,gcmSenderID:sender)
        options.apiKey = key;options.projectID = project;options.bundleID = Bundle.main.bundleIdentifier
        FirebaseApp.configure(options:options)
    }
}
final class MeetAttestationFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {AppAttestProvider(app:app)}
}
