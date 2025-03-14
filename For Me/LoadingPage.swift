import SwiftUI

struct LoadingPage: View {
    @State private var shouldNavigateToHome = false
    @State private var shouldNavigateToNameInput = false
    
    // 명언과 저자를 담은 구조체 정의
    struct Quote {
        let text: String
        let author: String
    }
    
    // 명언 배열
    let quotes: [Quote] = [
        Quote(text: "위대한 일을 이루고 싶다면, 먼저 침대를 정리하라.", author: "William H. McRaven"),
        Quote(text: "천 리 길도 한 걸음부터.", author: "노자 (老子)"),
        Quote(text: "큰일을 하려면 사소한 것부터 시작하라.", author: "공자 (孔子)"),
        Quote(text: "높은 곳에 오르려면 낮은 곳에서 시작해야 한다.", author: "세네카"),
        Quote(text: "나무를 심기에 가장 좋은 시기는 20년 전이었고, 두 번째로 좋은 시기는 지금이다.", author: "중국 속담"),
        Quote(text: "규칙적인 작은 노력들이 인생에서 큰 변화를 만든다.", author: "루이스 캐럴"),
        Quote(text: "당신이 하는 작은 행동들이 결국 당신을 만든다.", author: "아리스토텔레스"),
        Quote(text: "한 사람의 하루 습관이 그 사람의 미래를 결정한다.", author: "마하트마 간디"),
        Quote(text: "지금 당장 할 수 있는 작은 일부터 시작하라.", author: "테오도어 루즈벨트"),
        Quote(text: "어떤 위대한 목표도 작은 첫걸음 없이는 이루어질 수 없다.", author: "마틴 루터 킹 주니어")
    ]
    
    // 랜덤 명언 선택
    @State private var selectedQuote: Quote
    
    // 생성자에서 초기 랜덤 명언 설정
    init() {
        let randomQuote = quotes.randomElement()!
        self._selectedQuote = State(initialValue: randomQuote)
    }
    
    var body: some View {
        ZStack {
            // 배경색
            Color(hex: "E8E6DD")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 로고 이미지
                Circle()
                    .fill(Color.white)
                    .frame(width: 150, height: 150)
                    .shadow(color: Color.black.opacity(0.1), radius: 10)
                    .overlay(
                        Image("Check")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "6E3CBC"))
                    )
                    .padding(.bottom, 20)
                
                // 앱 이름과 설명
                VStack(spacing: 12) {
                    Text("간단한 일부터 천천히")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("\"\(selectedQuote.text)\"")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(selectedQuote.author)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 40)
                
                Spacer()
            }
            .padding(.top, 100)
            
            // 조건부 풀스크린 커버
            if shouldNavigateToHome {
                HomePage()
                    .transition(.opacity)
            }
        }
        .environment(\.colorScheme, .light)
        .onAppear {
            // 2초 후 자동으로 홈페이지로 이동
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    shouldNavigateToHome = true
                }
            }
        }
    }
}
