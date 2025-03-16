import SwiftUI

// 채팅 버블 컴포넌트
struct ChatBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isUser ? Color(hex: "6E3CBC") : Color.white
                )
                .foregroundColor(isUser ? .white : .black)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            if !isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}

struct SpeechAIPage: View {
    @Environment(\.dismiss) private var dismiss
    let selectedDate: Date
    @State private var messageText = ""
    @State private var chatMessages: [(text: String, isUser: Bool)] = [
        (text: "오늘 하루는 어땠나요?", isUser: false)
    ]
    @State private var conversationCount = 0  // 대화 횟수를 추적하기 위한 변수 추가
    private let maxConversations = 3  // 최대 대화 횟수 설정
    
    private let calendar = Calendar.current
    
    // 대화 횟수 계산 (사용자 메시지 기준)
    private var userMessageCount: Int {
        chatMessages.filter { $0.isUser }.count
    }
    
    // 대화 횟수 제한에 도달했는지 확인
    private var reachedMaxConversations: Bool {
        userMessageCount >= maxConversations
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "E8E6DD")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 상단 헤더
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("\(calendar.component(.day, from: selectedDate))일의 대화")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.clear)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    
                    // 대화 내용 표시 영역
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(spacing: 20) {
                                ForEach(Array(chatMessages.enumerated()), id: \.offset) { index, message in
                                    ChatBubble(text: message.text, isUser: message.isUser)
                                        .id(index)
                                }
                                
                                if reachedMaxConversations {
                                    Text("오늘의 대화 횟수를 모두 사용했습니다")
                                        .foregroundColor(.gray)
                                        .padding(.top, 20)
                                }
                            }
                            .padding(.vertical)
                        }
                        .onChange(of: chatMessages.count) { _ in
                            withAnimation {
                                scrollProxy.scrollTo(chatMessages.count - 1, anchor: .bottom)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 입력창 또는 + 버튼 표시
                    if reachedMaxConversations {
                        // + 버튼
                        Button(action: {
                            // 추후 구현 예정
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "6E3CBC"))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.bottom, 30)
                    } else {
                        // 채팅 입력창
                        HStack(spacing: 12) {
                            TextField("메시지를 입력하세요", text: $messageText)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .submitLabel(.send)
                                .onSubmit {
                                    sendMessage()
                                }
                            
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(messageText.isEmpty ? .gray : Color(hex: "6E3CBC"))
                            }
                            .disabled(messageText.isEmpty)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color.white)
                    }
                }
            }
        }
        .environment(\.colorScheme, .light)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = messageText
        messageText = "" // 입력창 초기화
        
        // 사용자 메시지 추가
        chatMessages.append((text: userMessage, isUser: true))
        
        // TODO: AI 응답 처리 로직 추가
        // 임시 응답
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            chatMessages.append((text: "AI 응답을 기다리고 있습니다...", isUser: false))
        }
    }
}

#Preview {
    SpeechAIPage(selectedDate: Date())
}

