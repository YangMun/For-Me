import SwiftUI

struct RecordPage: View {
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var selectedScore: Int = 0
    @State private var showAddTaskSheet = false
    @State private var tasks: [String] = []  // 할 일 목록을 저장할 배열
    @State private var editingTask: String?  // 현재 수정 중인 task
    @State private var editedText: String = ""  // 수정 중인 텍스트
    @State private var showDeleteAlert = false  // 삭제 확인 알림
    @State private var taskToDelete: String?    // 삭제할 task
    @State private var showSpeechAIPage = false
    @State private var chatSummary: String? = nil  // 대화 요약 내용을 저장할 변수 추가
    @State private var showSaveAlert = false  // 저장 성공 알림 추가
    @State private var saveErrorMessage: String? = nil  // 저장 실패 메시지 저장
    @State private var adObserverAdded = false
    @State private var observer: NSObjectProtocol? = nil
    
    private let calendar = Calendar.current
    
    // 오늘 날짜인지 확인하는 계산 프로퍼티
    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }
    
    // 수정 모드를 해제하는 함수
    private func cancelEditing() {
        if editingTask != nil {
            editingTask = nil
        }
    }


    var body: some View {
        NavigationView {
            ZStack {
                // 배경색
                Color.backgroundColor
                    .ignoresSafeArea()
                    // 전체 화면에 탭 제스처 추가 - 버튼 영역 제외
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                    .onTapGesture {
                        cancelEditing()
                    }
                
                VStack(spacing: 15) {  // 전체 간격을 20에서 15로 줄임
                    // 상단 헤더 수정
                    HStack {
                        Text("\(calendar.component(.day, from: selectedDate))일")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // + 버튼 수정 - 오늘 날짜일 때만 활성화
                        Button(action: {
                            if isToday {  // 오늘 날짜일 때만 동작
                                cancelEditing()
                                showAddTaskSheet = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(isToday ? Color.accentColor : Color.gray)  // 오늘이 아니면 회색으로 표시
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .disabled(!isToday)  // 오늘 날짜가 아니면 비활성화
                        .opacity(isToday ? 1.0 : 0.5)  // 오늘 날짜가 아니면 투명도 낮춤
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 할 일 목록
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(tasks, id: \.self) { task in
                                HStack(spacing: 10) {
                                    if editingTask == task {
                                        TextField("할 일을 입력하세요", text: $editedText)
                                            .font(.system(size: 16))
                                            .padding(.horizontal)
                                            .onSubmit {
                                                if let index = tasks.firstIndex(of: task) {
                                                    tasks[index] = editedText
                                                    editingTask = nil
                                                }
                                            }
                                    } else {
                                        Text(task)
                                            .font(.system(size: 16))
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 20) {
                                            Button(action: {
                                                editingTask = task
                                                editedText = task
                                            }) {
                                                Image(systemName: "pencil")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 16))
                                            }
                                            
                                            Button(action: {
                                                taskToDelete = task
                                                showDeleteAlert = true
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 16))
                                            }
                                        }
                                        .padding(.horizontal, 5)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .offset(y: 20)),
                                    removal: .opacity.combined(with: .offset(y: -20))
                                ))
                            }
                            .animation(.easeInOut(duration: 0.3), value: tasks)
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 230)  // 할 일 목록 높이를 250에서 230으로 줄임
                    
                    // CircleScore 수정
                    CircleScore(
                        score: $selectedScore,
                        isEnabled: isToday,
                        date: selectedDate,
                        onScoreChange: { _ in
                            cancelEditing()
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .allowsHitTesting(true)
                    
                    // AIChatButton 수정
                    AIChatButton(
                        action: {
                            cancelEditing()
                            
                            // 광고가 준비되지 않은 경우 바로 SpeechAIPage 표시
                            if !AdMobManager.shared.isInterstitialReady {
                                showSpeechAIPage = true
                            }
                            // 광고가 준비된 경우는 옵저버에서 처리 (광고 닫힘 이벤트 후 자동으로 SpeechAIPage 표시)
                        },
                        isEnabled: isToday && chatSummary == nil,
                        isAdReady: true,
                        isChatCompleted: chatSummary != nil
                    )
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .allowsHitTesting(true)
                    
                    // 대화 요약 표시
                    if let summary = chatSummary {
                        SummaryChat(summary: summary, date: selectedDate)
                            .padding(.top, 5)
                    }
                    
                    Spacer()
                    
                    // 저장하기 버튼 추가 (오늘 날짜일 때만 표시)
                    SaveButton(
                        action: {
                            // FirestoreManager를 사용하여 데이터 저장
                            saveDataToFirestore()
                        },
                        isEnabled: true,
                        isToday: isToday  // RecordPage의 isToday 계산 프로퍼티 전달
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTaskSheet) {
                AddTaskView(
                    selectedDate: selectedDate,
                    onTaskAdded: { newTask in
                        cancelEditing()
                        tasks.append(newTask)
                    },
                    existingTasks: tasks
                )
            }
            .sheet(isPresented: $showSpeechAIPage, onDismiss: {
                // SpeechAIPage가 닫힐 때 요약 다시 불러오기
                withAnimation {
                    loadSummary()
                }
            }) {
                SpeechAIPage(selectedDate: selectedDate)
            }
            // 삭제 확인 알림
            .alert("할 일 삭제", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    withAnimation {
                        if let taskToDelete = taskToDelete,
                           let index = tasks.firstIndex(of: taskToDelete) {
                            tasks.remove(at: index)
                        }
                    }
                }
            } message: {
                Text("정말로 이 할 일을 삭제하시겠습니까?")
            }
            // 저장 성공 알림 추가
            .alert("저장 완료", isPresented: $showSaveAlert) {
                Button("확인") {
                    // 알림 확인 시 페이지 닫기
                    dismiss()
                }
            } message: {
                Text("데이터가 성공적으로 저장되었습니다.")
            }
            // 저장 실패 알림 추가
            .alert("저장 실패", isPresented: Binding<Bool>(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(saveErrorMessage ?? "알 수 없는 오류가 발생했습니다.")
            }
            .onAppear {
                // 페이지가 나타날 때 해당 날짜의 요약 불러오기
                loadSummary()
                
                // 페이지가 나타날 때 Firestore에서 데이터 불러오기
                loadDataFromFirestore()
                
                // 옵저버가 아직 없는 경우에만 추가
                if observer == nil {
                    observer = NotificationCenter.default.addObserver(
                        forName: NSNotification.Name("AdDismissed"),
                        object: nil,
                        queue: .main
                    ) { _ in
                        // 광고가 닫힌 후 SpeechAIPage 표시
                        showSpeechAIPage = true
                    }
                }
            }
            .onDisappear {
                // 페이지가 사라질 때 옵저버 제거
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                    self.observer = nil
                }
            }
        }
        .environment(\.colorScheme, .light)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
    
    // 요약 불러오기 함수 수정
    private func loadSummary() {
        let newSummary = SummaryManager.shared.getSummary(for: selectedDate)
        
        // 요약이 변경되었을 때만 애니메이션 적용
        if chatSummary != newSummary {
            withAnimation(.easeInOut(duration: 0.3)) {
                chatSummary = newSummary
            }
        } else {
            chatSummary = newSummary
        }
    }
    
    // Firestore에 데이터 저장하는 함수 수정
    private func saveDataToFirestore() {
        // FirestoreManager 호출하여 데이터 저장
        FirestoreManager.shared.saveRecord(
            date: selectedDate,
            score: selectedScore, 
            tasks: tasks,
            summary: chatSummary
        ) { success, error in
            // UI 업데이트는 메인 스레드에서 처리
            DispatchQueue.main.async {
                if success {
                    // print("데이터가 성공적으로 저장되었습니다!")
                    // 저장 성공 알림 표시
                    showSaveAlert = true
                } else {
                    // print("데이터 저장 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                    // 저장 실패 알림 표시
                    saveErrorMessage = error?.localizedDescription ?? "알 수 없는 오류가 발생했습니다."
                }
            }
        }
    }
    
    // Firestore에서 데이터 불러오는 함수 추가
    private func loadDataFromFirestore() {
        // FirestoreManager 호출하여 데이터 불러오기
        FirestoreManager.shared.fetchRecord(date: selectedDate) { data, error in
            if let error = error {
                // print("데이터 불러오기 실패: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                // 점수 설정
                if let score = data["score"] as? Int {
                    self.selectedScore = score
                }
                
                // 할 일 목록 설정
                if let tasks = data["tasks"] as? [String] {
                    self.tasks = tasks
                }
                
                // 요약 설정 (chatSummary가 nil인 경우에만)
                if self.chatSummary == nil, let summary = data["summary"] as? String {
                    self.chatSummary = summary
                }
                
                // print("Firestore에서 데이터를 성공적으로 불러왔습니다!")
            } else {
                // print("해당 날짜의 데이터가 존재하지 않습니다.")
            }
        }
    }
}

#Preview {
    RecordPage(selectedDate: Date())
}
