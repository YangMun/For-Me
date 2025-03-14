import SwiftUI

struct AIChatButton: View {
    var action: () -> Void
    var isEnabled: Bool
    var isAdReady: Bool
    
    var body: some View {
        Button(action: {
            if isEnabled && isAdReady {
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image("AI Chatting")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                Text(isAdReady ? "AI와 대화하기" : "AI와 대화 준비중...")
                    .font(.system(size: 16))
                    .foregroundColor(isEnabled && isAdReady ? .black : .gray)
                
                Spacer()
                
                if isAdReady {
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
            .opacity(isEnabled && isAdReady ? 1.0 : 0.5)
        }
        .disabled(!isEnabled || !isAdReady)
    }
}
