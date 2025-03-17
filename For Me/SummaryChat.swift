//
//  SummaryChat.swift
//  For Me
//
//  Created by 양문경 on 3/16/25.
//

import SwiftUI

struct SummaryChat: View {
    let summary: String?
    let date: Date
    
    var body: some View {
        if let summary = summary {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("오늘의 대화 요약")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                }
                
                Text(summary)
                    .font(.system(size: 16))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal)
            .padding(.top, 5)
            .padding(.bottom, 5)
            .transition(.opacity)
        } else {
            EmptyView()
        }
    }
}

// 요약 데이터를 관리하는 싱글톤 클래스
class SummaryManager {
    static let shared = SummaryManager()
    
    private var summaries: [String: String] = [:]  // [날짜 문자열: 요약 내용]
    
    private init() {
        // UserDefaults에서 저장된 요약 불러오기
        if let savedData = UserDefaults.standard.data(forKey: "chatSummaries"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: savedData) {
            summaries = decoded
        }
    }
    
    // 날짜에 해당하는 요약 가져오기
    func getSummary(for date: Date) -> String? {
        let key = dateKey(for: date)
        return summaries[key]
    }
    
    // 요약 저장하기
    func saveSummary(_ summary: String, for date: Date) {
        let key = dateKey(for: date)
        summaries[key] = summary
        
        // UserDefaults에 저장
        if let encoded = try? JSONEncoder().encode(summaries) {
            UserDefaults.standard.set(encoded, forKey: "chatSummaries")
        }
    }
    
    // 날짜를 문자열 키로 변환
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}

