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
                            showSpeechAIPage = true
                        },
                        isEnabled: isToday,
                        isAdReady: true
                    )
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .allowsHitTesting(true)
                    
                    // 대화 요약 표시
                    if let summary = chatSummary {
                        SummaryChat(summary: summary, date: selectedDate)
                            .padding(.top, 5)  // 상단 패딩 추가
                    }
                    
                    Spacer()
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
            .onAppear {
                // 페이지가 나타날 때 해당 날짜의 요약 불러오기
                loadSummary()
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
}

#Preview {
    RecordPage(selectedDate: Date())
}
