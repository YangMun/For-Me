import SwiftUI

struct AIChatButton: View {
    var action: () -> Void
    var isEnabled: Bool
    var isAdReady: Bool
    var isChatCompleted: Bool  // 대화가 이미 완료되었는지 여부 (요약이 있는 경우)
    
    init(action: @escaping () -> Void, isEnabled: Bool, isAdReady: Bool, isChatCompleted: Bool = false) {
        self.action = action
        self.isEnabled = isEnabled
        self.isAdReady = isAdReady
        self.isChatCompleted = isChatCompleted
    }
    
    // 광고 표시 시도 상태 추적
    @State private var isAttemptingToShowAd = false
    
    var body: some View {
        Button(action: {
            if isEnabled && isAdReady && !isChatCompleted {
                if !isAttemptingToShowAd && AdMobManager.shared.isInterstitialReady {
                    // 광고 표시 시도 상태로 변경
                    isAttemptingToShowAd = true
                    
                    // 약간의 지연 후 광고 표시 시도 (UI 업데이트가 완료되도록)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let adShown = AdMobManager.shared.showInterstitialAd()
                        
                        if !adShown {
                            // 광고 표시 실패 시 바로 액션 실행
                            action()
                        }
                        
                        // 시도 상태 초기화
                        isAttemptingToShowAd = false
                    }
                } else {
                    // 광고가 준비되지 않았거나 현재 표시 시도 중이면 바로 액션 실행
                    action()
                }
            }
        }) {
            HStack(spacing: 12) {
                Image("AI Chatting")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                Text(isChatCompleted ? "오늘의 대화가 완료되었습니다" : 
                     (isAdReady ? "AI와 대화하기" : "AI와 대화 준비중..."))
                    .font(.system(size: 16))
                    .foregroundColor(isEnabled && isAdReady && !isChatCompleted ? .black : .gray)
                
                Spacer()
                
                if isChatCompleted {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                } else if isAdReady {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .opacity(isEnabled && isAdReady && !isChatCompleted ? 1.0 : 0.5)
        }
        .disabled(!isEnabled || !isAdReady || isChatCompleted)
    }
}
