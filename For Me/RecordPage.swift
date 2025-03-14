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
                    // 전체 화면에 탭 제스처 추가
                    .onTapGesture {
                        cancelEditing()
                    }
                
                VStack(spacing: 20) {
                    // 상단 헤더 수정
                    HStack {
                        Text("\(calendar.component(.day, from: selectedDate))일")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // + 버튼 수정
                        Button(action: {
                            cancelEditing()  // 수정 모드 해제
                            showAddTaskSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(Color.accentColor)
                        }
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
                    .frame(maxHeight: 250)
                    
                    // CircleScore 수정
                    CircleScore(
                        score: $selectedScore,
                        isEnabled: isToday,
                        date: selectedDate,
                        onScoreChange: { _ in  // 점수 변경 시 호출될 클로저 추가
                            cancelEditing()
                        }
                    )
                    .padding(.horizontal)
                    .allowsHitTesting(true)
                    .onTapGesture {
                        cancelEditing()
                    }
                    
                    // AIChatButton 수정
                    AIChatButton(
                        action: {
                            cancelEditing()  // 수정 모드 해제
                            // 추후 기능 구현
                        },
                        isEnabled: isToday,
                        isAdReady: true
                    )
                    .padding(.horizontal)
                    .padding(.top, 30)
                    .allowsHitTesting(true)
                    
                    Spacer()
                }
            }
            // ScrollView의 탭 제스처 제거 (중복 방지)
            .onTapGesture {}
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTaskSheet) {
                AddTaskView(
                    selectedDate: selectedDate,
                    onTaskAdded: { newTask in
                        cancelEditing()  // 수정 모드 해제
                        tasks.append(newTask)
                    },
                    existingTasks: tasks  // 기존 할 일 목록 전달
                )
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
        }
        .environment(\.colorScheme, .light)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    RecordPage(selectedDate: Date())
}
