import SwiftUI

import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    // Firebase 연결 확인을 위한 print 문 추가
    print("Firebase가 성공적으로 초기화되었습니다.")
    
    // Firebase 인스턴스 확인
    if FirebaseApp.app() != nil {
      print("Firebase 인스턴스가 존재합니다: \(String(describing: FirebaseApp.app()?.name))")
    } else {
      print("Firebase 인스턴스가 존재하지 않습니다.")
    }

    return true
  }
}


@main
struct ForMeApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


