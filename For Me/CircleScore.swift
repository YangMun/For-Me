import SwiftUI

struct CircleScore: View {
    @Binding var score: Int
    let maxScore = 5
    let isEnabled: Bool
    let date: Date  // 날짜 프로퍼티
    var onScoreChange: ((Int) -> Void)? = nil  // 점수 변경 시 호출될 클로저 추가
    
    var body: some View {
        VStack(spacing: 15) {
            Text("나에게 주는 오늘의 점수")
                .font(.system(size: 20))
                .foregroundColor(isEnabled ? .black : .gray)
            
            HStack {
                Spacer()
                ForEach(1...maxScore, id: \.self) { index in
                    Circle()
                        .fill(index <= score ? Color(hex: "4CAF50") : Color.white)
                        .frame(width: 35, height: 35)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .contentShape(Circle())  // 탭 영역을 명확히 정의
                        .onTapGesture {
                            if isEnabled {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    score = index
                                    onScoreChange?(index)  // 점수 변경 시 클로저 호출
                                }
                            }
                        }
                        .frame(width: 44, height: 44)  // 탭 영역 확장
                        .opacity(isEnabled ? 1.0 : 0.5)
                    if index < maxScore {
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical, 10)
    }
}
