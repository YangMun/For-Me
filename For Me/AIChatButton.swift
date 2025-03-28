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
    
    // 광고 로딩 상태 추가
    @State private var isLoadingAd = false
    @State private var isAttemptingToShowAd = false
    
    var body: some View {
        Button(action: {
            if isEnabled && !isChatCompleted {
                // 광고가 없거나 준비되지 않은 경우 바로 action 실행
                if !AdMobManager.shared.isInterstitialReady {
                    action()
                    return
                }
                
                // 광고가 있는 경우 광고 표시 로직 실행
                if !isAttemptingToShowAd {
                    isAttemptingToShowAd = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let adShown = AdMobManager.shared.showInterstitialAd()
                        if !adShown {
                            action()
                        }
                        isAttemptingToShowAd = false
                    }
                }
            }
        }) {
            HStack(spacing: 12) {
                Image("AI Chatting")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                Text(isChatCompleted ? "오늘의 대화가 완료되었습니다" : "AI와 대화하기")
                    .font(.system(size: 16))
                    .foregroundColor(isEnabled && !isChatCompleted ? .black : .gray)
                
                Spacer()
                
                if isChatCompleted {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .opacity(isEnabled && !isChatCompleted ? 1.0 : 0.5)
        }
        .disabled(!isEnabled || isChatCompleted)
    }
}
