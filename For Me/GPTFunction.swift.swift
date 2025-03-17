import Foundation

class GPTFunction {
    static let shared = GPTFunction()
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini"
    private var messageHistory: [[String: String]] = []
    
    private init() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String else {
            fatalError("OpenAI API key not found")
        }
        self.apiKey = key
        // 시스템 메시지 수정
        messageHistory.append([
            "role": "system",
            "content": """
                당신은 사용자와 일상적인 대화를 나누는 AI입니다.
                규칙:
                1. 사용자의 이전 발언을 정확히 이해하고 응답하기
                2. 사용자가 말한 주제에 대해서만 대화하기
                3. 공감하는 톤으로 짧게 답변하기
                4. 답변 후에는 관련된 한 가지 질문하기
                5. 주어진 100개의 토큰 내로 문장의 마무리를 완성 해야 한다.
                """
        ])
    }
    
    func sendMessage(_ message: String) async throws -> String {
        // 이전 대화 내용 유지 (최근 4개 메시지만)
        if messageHistory.count > 7 { // system + 3쌍의 대화(user/assistant)
            messageHistory = [messageHistory[0]] + messageHistory.suffix(6)
        }
        
        // 사용자 메시지 추가
        messageHistory.append(["role": "user", "content": message])
        
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messageHistory,
            "temperature": 0.7,
            "max_tokens": 100
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // HTTP 응답 상태 확인
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(httpResponse.statusCode)"])
        }
        
        let decoder = JSONDecoder()
        let gptResponse = try decoder.decode(GPTResponse.self, from: data)
        
        if let assistantMessage = gptResponse.choices.first?.message {
            // AI 응답을 히스토리에 추가
            messageHistory.append(["role": "assistant", "content": assistantMessage.content])
            return assistantMessage.content
        }
        
        return "죄송해요, 잠시 오류가 발생했어요."
    }
    
    func resetConversation() {
        // 시스템 메시지만 남기고 초기화
        messageHistory = [messageHistory[0]]
    }
    
    // 대화 내용을 문자열로 변환하는 함수 추가 (요약에 사용)
    func getConversationString() -> String {
        return messageHistory
            .filter { $0["role"] != "system" }
            .map { "\($0["role"] == "user" ? "사용자" : "AI"): \($0["content"] ?? "")" }
            .joined(separator: "\n")
    }
    
    // 대화 요약 함수 추가
    func generateSummary(from messages: [(text: String, isUser: Bool)]) async throws -> String {
        // 기존 대화 내용을 저장
        let originalHistory = messageHistory
        
        // 요약을 위한 새로운 대화 컨텍스트 생성
        messageHistory = [[
            "role": "system",
            "content": "당신은 대화 내용을 간결하게 요약하는 AI입니다. 50자 이내로 핵심만 요약해주세요."
        ]]
        
        // 대화 내용을 문자열로 변환
        let conversationString = messages.map { 
            "\($0.isUser ? "사용자" : "AI"): \($0.text)" 
        }.joined(separator: "\n")
        
        // 요약 요청
        let summaryPrompt = "다음 대화를 50자 이내로 요약해주세요:\n\(conversationString)"
        
        do {
            let summary = try await sendMessage(summaryPrompt)
            
            // 원래 대화 컨텍스트 복원
            messageHistory = originalHistory
            
            return summary
        } catch {
            // 오류 발생 시 원래 대화 컨텍스트 복원하고 오류 전파
            messageHistory = originalHistory
            throw error
        }
    }
}

struct GPTResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        enum CodingKeys: String, CodingKey {
            case message
        }
    }
    
    struct Message: Codable {
        let content: String
        let role: String
        
        enum CodingKeys: String, CodingKey {
            case content
            case role
        }
    }
}
