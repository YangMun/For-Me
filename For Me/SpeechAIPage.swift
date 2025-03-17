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
    @State private var isWaitingForResponse = false // AI 응답 대기 상태 추가
    private let maxConversations = 3  // 최대 대화 횟수 설정
    @State private var summary: String? = nil  // 요약 내용을 저장할 변수 추가
    @State private var isGeneratingSummary = false  // 요약 생성 중 상태 추가
    
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
                    
                    // 입력창 또는 버튼들 표시
                    if reachedMaxConversations {
                        // 버튼 영역 수정 - + 버튼과 요약 버튼 함께 표시
                        HStack(spacing: 20) {
                            // + 버튼
                            Button(action: {
                                // 추후 구현 예정
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "6E3CBC"))
                                        .frame(width: 60, height: 60)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // 요약 버튼 - 요약 생성 후 페이지 닫힘
                            Button(action: {
                                generateSummary()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "4CAF50"))  // 녹색 계열 색상 사용
                                        .frame(width: 60, height: 60)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                                    
                                    if isGeneratingSummary {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.2)
                                    } else {
                                        Image(systemName: "text.redaction")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .disabled(isGeneratingSummary)
                        }
                        .padding(.bottom, 30)
                        
                        // 요약 생성 중일 때만 로딩 메시지 표시
                        if isGeneratingSummary {
                            Text("요약 생성 중...")
                                .foregroundColor(.gray)
                                .padding(.bottom, 20)
                        } else if summary == "요약 생성 실패" {
                            // 오류 메시지만 표시 (자동으로 사라짐)
                            Text(summary!)
                                .foregroundColor(.red)
                                .padding(.bottom, 20)
                                .transition(.opacity)
                        }
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
                                .disabled(isWaitingForResponse) // 응답 대기 중에는 비활성화
                            
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(messageText.isEmpty || isWaitingForResponse ? .gray : Color(hex: "6E3CBC"))
                            }
                            .disabled(messageText.isEmpty || isWaitingForResponse) // 응답 대기 중에는 비활성화
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
        guard !messageText.isEmpty && !isWaitingForResponse else { return }
        
        let userMessage = messageText
        messageText = "" // 입력창 초기화
        
        // 사용자 메시지 추가
        chatMessages.append((text: userMessage, isUser: true))
        
        // 응답 대기 상태로 변경
        isWaitingForResponse = true
        
        // 임시 대기 메시지 추가
        let waitingMessageIndex = chatMessages.count
        chatMessages.append((text: "AI 응답을 기다리고 있습니다...", isUser: false))
        
        // GPT API 호출
        Task {
            do {
                let response = try await GPTFunction.shared.sendMessage(userMessage)
                
                // UI 업데이트는 메인 스레드에서 수행
                DispatchQueue.main.async {
                    // 대기 메시지 제거하고 실제 응답으로 교체
                    if waitingMessageIndex < chatMessages.count {
                        chatMessages[waitingMessageIndex] = (text: response, isUser: false)
                    }
                    
                    // 응답 대기 상태 해제
                    isWaitingForResponse = false
                }
            } catch {
                // 오류 발생 시 처리
                DispatchQueue.main.async {
                    // 대기 메시지를 오류 메시지로 교체
                    if waitingMessageIndex < chatMessages.count {
                        chatMessages[waitingMessageIndex] = (text: "죄송합니다. 응답을 받아오는 중 오류가 발생했습니다.", isUser: false)
                    }
                    
                    // 응답 대기 상태 해제
                    isWaitingForResponse = false
                }
                print("GPT API 오류: \(error.localizedDescription)")
            }
        }
    }
    
    // 요약 생성 함수 수정
    private func generateSummary() {
        guard !isGeneratingSummary else { return }
        
        isGeneratingSummary = true
        
        // GPTFunction의 generateSummary 함수 호출
        Task {
            do {
                let summaryText = try await GPTFunction.shared.generateSummary(from: chatMessages)
                
                // UI 업데이트는 메인 스레드에서 수행
                DispatchQueue.main.async {
                    // 요약 내용을 SummaryManager에 저장
                    SummaryManager.shared.saveSummary(summaryText, for: selectedDate)
                    
                    // 요약 생성 완료 후 페이지 닫기
                    dismiss()
                }
            } catch {
                // 오류 발생 시 처리
                DispatchQueue.main.async {
                    isGeneratingSummary = false
                    
                    // 오류 메시지 표시 (1.5초 후 사라짐)
                    withAnimation {
                        summary = "요약 생성 실패"
                    }
                    
                    // 1.5초 후 오류 메시지 숨기기
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            summary = nil
                        }
                    }
                    
                    print("요약 생성 오류: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    SpeechAIPage(selectedDate: Date())
}
