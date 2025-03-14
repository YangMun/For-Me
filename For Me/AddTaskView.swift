import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedDate: Date
    @State private var taskText = ""
    let onTaskAdded: (String) -> Void  // 할 일이 추가될 때 호출될 클로저
    let existingTasks: [String]  // 기존 할 일 목록을 받을 프로퍼티 추가
    
    let quickTasks = [
        "물 마시기", "영양제 먹기", "3끼 챙겨먹기",
        "이불 정리", "집 청소", "운동하기",
        "일기 쓰기", "책 읽기", "산책하기",
        "공부하기", "숨 열심히 쉬기", "샤워하기"
    ]
    
    // 현재 입력된 할 일이 이미 존재하는지 확인하는 계산 프로퍼티
    private var isTaskDuplicate: Bool {
        !taskText.isEmpty && existingTasks.contains(taskText)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 상단 헤더
                    HStack {
                        Button("취소") {
                            dismiss()
                        }
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("한 일 추가")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("추가") {
                            if !taskText.isEmpty {
                                onTaskAdded(taskText)  // 할 일 추가
                                dismiss()
                            }
                        }
                        .foregroundColor(taskText.isEmpty || isTaskDuplicate ? .gray : Color.accentColor)
                        .disabled(taskText.isEmpty || isTaskDuplicate)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        TextField("오늘 한 일을 입력하세요", text: $taskText)
                            .font(.system(size: 16))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // 중복된 할 일일 경우 경고 메시지 표시
                        if isTaskDuplicate {
                            Text("이미 추가된 할 일입니다")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("빠른 선택")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(quickTasks, id: \.self) { task in
                                    Button(action: {
                                        taskText = task
                                    }) {
                                        Text(task)
                                            .font(.system(size: 14))
                                            .foregroundColor(.black)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 15)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(taskText == task ? Color.accentColor.opacity(0.2) : Color.white)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(taskText == task ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .environment(\.colorScheme, .light)
    }
}
