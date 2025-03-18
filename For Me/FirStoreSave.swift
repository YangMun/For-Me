import Foundation
import Firebase
import FirebaseFirestore

class FirestoreManager {
    // 싱글톤 패턴 구현
    static let shared = FirestoreManager()
    
    // Firestore 데이터베이스 참조
    private let db = Firestore.firestore()
    
    // 컬렉션 이름 상수
    private let collectionName = "DailyRecords"
    private let subCollectionName = "records"
    
    private init() {}
    
    // 기록 저장 함수
    func saveRecord(date: Date, score: Int, tasks: [String], summary: String?, completion: @escaping (Bool, Error?) -> Void) {
        // 사용자 ID 가져오기
        let userId = UserIdManager.shared.getUserId()
        
        // 날짜 형식 변환
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // 저장할 데이터 구성
        var recordData: [String: Any] = [
            "date": dateString,
            "score": score,
            "tasks": tasks,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // summary가 nil이 아닌 경우에만 추가
        if let summary = summary {
            recordData["summary"] = summary
        }
        
        // 문서 참조 생성
        let docRef = db.collection(collectionName).document(userId)
            .collection(subCollectionName).document(dateString)
        
        // 문서가 존재하는지 확인
        docRef.getDocument { (document, error) in
            if let error = error {
                print("문서 확인 중 오류 발생: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            if let document = document, document.exists {
                // 기존 문서 업데이트
                docRef.updateData(recordData) { error in
                    if let error = error {
                        print("데이터 업데이트 실패: \(error.localizedDescription)")
                        completion(false, error)
                    } else {
                        print("데이터 업데이트 성공!")
                        completion(true, nil)
                    }
                }
            } else {
                // 새 문서 생성 (createdAt 필드 추가)
                recordData["createdAt"] = FieldValue.serverTimestamp()
                
                docRef.setData(recordData) { error in
                    if let error = error {
                        print("새 데이터 저장 실패: \(error.localizedDescription)")
                        completion(false, error)
                    } else {
                        print("새 데이터 저장 성공!")
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    // 특정 날짜의 기록 불러오기
    func fetchRecord(date: Date, completion: @escaping ([String: Any]?, Error?) -> Void) {
        // 사용자 ID 가져오기
        let userId = UserIdManager.shared.getUserId()
        
        // 날짜 형식 변환
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Firestore에서 데이터 조회
        db.collection(collectionName).document(userId)
            .collection(subCollectionName).document(dateString)
            .getDocument { document, error in
                if let error = error {
                    print("데이터 불러오기 실패: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let document = document, document.exists, let data = document.data() else {
                    print("해당 날짜의 데이터가 존재하지 않습니다.")
                    completion(nil, nil)
                    return
                }
                
                completion(data, nil)
            }
    }
    
    // 특정 사용자의 모든 기록 불러오기
    func fetchAllRecords(completion: @escaping ([String: [String: Any]]?, Error?) -> Void) {
        // 사용자 ID 가져오기
        let userId = UserIdManager.shared.getUserId()
        
        // Firestore에서 모든 기록 조회
        db.collection(collectionName).document(userId)
            .collection(subCollectionName)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("모든 데이터 불러오기 실패: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("저장된 기록이 없습니다.")
                    completion([:], nil)
                    return
                }
                
                var allRecords = [String: [String: Any]]()
                
                for document in documents {
                    let dateString = document.documentID
                    let data = document.data()
                    allRecords[dateString] = data
                }
                
                completion(allRecords, nil)
            }
    }
    
    // 기록 삭제 함수
    func deleteRecord(date: Date, completion: @escaping (Bool, Error?) -> Void) {
        // 사용자 ID 가져오기
        let userId = UserIdManager.shared.getUserId()
        
        // 날짜 형식 변환
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Firestore에서 문서 삭제
        db.collection(collectionName).document(userId)
            .collection(subCollectionName).document(dateString)
            .delete() { error in
                if let error = error {
                    print("데이터 삭제 실패: \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    print("데이터 삭제 성공!")
                    completion(true, nil)
                }
            }
    }
}
