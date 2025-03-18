import Foundation
import UIKit

class UserIdManager {
    // 싱글톤 패턴 구현
    static let shared = UserIdManager()
    
    // UserDefaults 키 상수 정의
    private let userIdKey = "com.forme.app.userId"
    
    private init() {}
    
    // 사용자 ID 가져오기 (없으면 생성)
    func getUserId() -> String {
        // UserDefaults에서 저장된 ID 확인
        if let savedUserId = UserDefaults.standard.string(forKey: userIdKey) {
            return savedUserId
        }
        
        // 저장된 ID가 없으면 새로 생성
        let newUserId = createNewUserId()
        UserDefaults.standard.set(newUserId, forKey: userIdKey)
        
        return newUserId
    }
    
    // 새 사용자 ID 생성
    private func createNewUserId() -> String {
        // UUID 생성 (iOS 디바이스에서 유일한 값)
        return UUID().uuidString
    }
    
    // 사용자 ID 강제 재설정 (필요 시 사용)
    func resetUserId() -> String {
        let newUserId = createNewUserId()
        UserDefaults.standard.set(newUserId, forKey: userIdKey)
        return newUserId
    }
    
    // 사용자 ID가 존재하는지 확인
    func hasUserId() -> Bool {
        return UserDefaults.standard.string(forKey: userIdKey) != nil
    }
}
