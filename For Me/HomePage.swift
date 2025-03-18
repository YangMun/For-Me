import SwiftUI
import UserNotifications

struct CustomCalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showDatePicker = false
    @State private var currentYear: Int
    let endYear: Int
    @State private var showRecordPage = false  // RecordPage 표시 여부
    @State private var lastSelectedDate: Date? = nil // 마지막으로 선택된 날짜
    @State private var userRecords: [String: [String: Any]] = [:]  // 날짜별 기록 데이터를 저장할 상태 변수
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    private let days = ["일", "월", "화", "수", "목", "금", "토"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    init() {
        let currentDate = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        
        _currentYear = State(initialValue: year)
        _currentMonth = State(initialValue: calendar.date(from: DateComponents(year: year, month: month)) ?? currentDate)
        
        endYear = min(year + 5, 2099)
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            showDatePicker.toggle()
                        }
                    }) {
                        HStack {
                            Text(monthYearString())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .black : .black)
                            Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                .foregroundColor(colorScheme == .dark ? .black : .black)
                        }
                    }
                    
                    Spacer()
                    
                }
                .padding(.horizontal)
                .padding(.top, 15)
                
                // 배너 광고 공간 (임시)
                HomeBannerView()
                    .frame(height: 50)
                    .padding(.vertical, 5)
                
                Spacer()
                
                // 달력 컨텐츠를 VStack으로 묶어서 관리
                VStack(spacing: 0) {  // spacing을 0으로 설정
                    // 요일 헤더
                    HStack {
                        ForEach(days, id: \.self) { day in
                            Text(day)
                                .font(Font.custom("Hakgyoansim Badasseugi TTF L", size: 25, relativeTo: .body))
                                .fontWeight(.regular)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(
                                    day == "일" ? .red :
                                    (day == "토" ? .blue : .black)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // 달력 그리드
                    GeometryReader { geo in
                        let cellWidth = (geo.size.width - 40) / 7
                        let availableHeight = geo.size.height
                        let spacing = availableHeight * 0.05  // spacing 감소
                        
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(daysInMonth(), id: \.self) { date in
                                if let date = date {
                                    DayCell(date: date, selectedDate: $selectedDate, currentMonth: currentMonth, userRecords: userRecords)
                                        .frame(height: cellWidth)
                                        .onTapGesture {
                                            if lastSelectedDate == date {
                                                // showRecordPage = true  // RecordPage 구현 시 주석 해제
                                            } else {
                                                lastSelectedDate = date
                                            }
                                        }
                                } else {
                                    Text("")
                                        .frame(maxWidth: .infinity)
                                        .frame(height: cellWidth)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    
                }
                
                Spacer(minLength: 0)  // 하단 여백 최소화
            }
            
            if showDatePicker {
                VStack {
                    Color.black.opacity(0.001) // 투명한 배경 추가
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showDatePicker = false
                                applySelectedDate()
                            }
                        }
                    
                    VStack {
                        Picker("년도", selection: $currentYear) {
                            ForEach(2025...endYear, id: \.self) { year in
                                Text("\(year)년")
                                    .tag(year)
                                    .foregroundColor(.black)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                        
                        Picker("월", selection: Binding(
                            get: { Calendar.current.component(.month, from: currentMonth) },
                            set: { newMonth in
                                let components = Calendar.current.dateComponents([.year], from: currentMonth)
                                let newComponents = DateComponents(year: components.year, month: newMonth)
                                if let newDate = Calendar.current.date(from: newComponents) {
                                    currentMonth = newDate
                                }
                            }
                        )) {
                            ForEach(1...12, id: \.self) { month in
                                Text("\(month)월")
                                    .tag(month)
                                    .foregroundColor(.black)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .offset(y: -UIScreen.main.bounds.height / 2 + 150)
                }
                .background(Color.black.opacity(0.001)) // 전체 화면을 덮는 배경 추가
                .onTapGesture {
                    withAnimation {
                        showDatePicker = false
                        applySelectedDate()
                    }
                }
            }
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold {
                        withAnimation {
                            previousMonth()
                        }
                    } else if value.translation.width < -threshold {
                        withAnimation {
                            nextMonth()
                        }
                    }
                }
        )
        .animation(.easeInOut, value: currentMonth)
        .onAppear {
            // 앱이 시작될 때 모든 기록 한 번에 로드
            loadAllRecords()
        }
    }
    
    private func monthYearString() -> String {
        dateFormatter.dateFormat = "yyyy년 M월"
        return dateFormatter.string(from: currentMonth)
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func daysInMonth() -> [Date?] {
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        
        let daysInMonth = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        
        var dates: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: interval.start) {
                dates.append(date)
            }
        }
        
        while dates.count % 7 != 0 {
            dates.append(nil)
        }
        
        return dates
    }
    
    private func applySelectedDate() {
        // 선택한 년도와 월을 적용하는 로직
        let components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        let newComponents = DateComponents(year: currentYear, month: components.month)
        if let newDate = Calendar.current.date(from: newComponents) {
            currentMonth = newDate
        }
    }
    
    // 모든 기록 로드 함수 추가
    private func loadAllRecords() {
        FirestoreManager.shared.fetchAllRecords { records, error in
            if let records = records {
                self.userRecords = records
            } else if let error = error {
                print("기록 로드 실패: \(error.localizedDescription)")
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date
    let currentMonth: Date
    let userRecords: [String: [String: Any]]  // 상위 뷰에서 전달받을 프로퍼티 추가
    @State private var showRecordPage = false
    @State private var hasRecord = false  // 기록 여부 추적을 위한 상태 변수 추가
    
    private let calendar = Calendar.current
    
    var body: some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        
        Button(action: {
            if calendar.isDate(date, inSameDayAs: selectedDate) {
                showRecordPage = true
            }
            selectedDate = date
        }) {
            VStack(spacing: 0) {
                Text("\(calendar.component(.day, from: date))")
                    .font(Font.custom("Hakgyoansim Badasseugi TTF L", size: 20, relativeTo: .body))
                    .fontWeight(isToday ? .bold : .regular)
                    .frame(maxWidth: .infinity, alignment: .top)
                Spacer()
                
                // 기록 완료 표시
                Text(hasRecord ? "O" : " ")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "4CAF50"))  // 녹색으로 표시
                    .frame(height: 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 10) // 높이 조정
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "6E3CBC").opacity(0.2) : Color.clear)
            )
            .overlay(
                isToday ?
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "6E3CBC"), lineWidth: 1)
                : nil
            )
        }
        .foregroundColor(
            calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                ? (calendar.component(.weekday, from: date) == 1
                    ? .red
                    : (calendar.component(.weekday, from: date) == 7
                        ? .blue
                        : .black))
                : .gray
        )
        .sheet(isPresented: $showRecordPage, onDismiss: {
            // 페이지가 닫힐 때 기록 상태 다시 확인
            checkHasRecord()
        }) {
            RecordPage(selectedDate: date)
        }
        .onAppear {
            // 로컬 데이터로 기록 여부 확인
            checkHasRecord()
        }
    }
    
    // 로컬 데이터로 기록 여부 확인하는 함수
    private func checkHasRecord() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        if let record = userRecords[dateString] {
            let hasScore = record["score"] as? Int != nil && (record["score"] as? Int ?? 0) > 0
            let hasTasks = record["tasks"] as? [String] != nil && !(record["tasks"] as? [String] ?? []).isEmpty
            
            hasRecord = hasScore || hasTasks
        } else {
            hasRecord = false
        }
    }
}

struct HomePage: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    CustomCalendarView()
                        .frame(height: geometry.size.height)
                        .padding(.horizontal, 0)
                        .padding(.top, 1)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .background(
                Color.backgroundColor
                    .ignoresSafeArea()
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("홈")
            }
            .tag(0)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
                .tag(1)
        }
        .onAppear {
            UITabBar.setupAppearance()
        }
        .tint(Color.accentColor)
        .toolbarBackground(Color.backgroundColor, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var notificationsEnabled = false
    @State private var showNotificationAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "E8E6DD")
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // 설정 옵션들
                    VStack(spacing: 0) {
                        // 앱 정보
                        NavigationLink(destination: AppInfoView()) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 25)
                                Text("앱 정보")
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                        
                        Divider()
                        
                        // 개인정보 처리방침
                        NavigationLink(destination: PrivacyPolicyView()) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 25)
                                Text("개인정보 처리방침")
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.white)
                    )
                    .padding(.horizontal)
                    .padding(.top) // 상단 여백 추가
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .environment(\.colorScheme, .light)
    }
}

// AppInfoView 수정
struct AppInfoView: View {
    var body: some View {
        List {
            Section(header: Text("앱 정보").foregroundColor(.black)) {
                // 버전 정보
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.purple)
                    Text("버전")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                
                // 아이콘 제공 정보
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.blue)
                    Link("Icons by Icons8", destination: URL(string: "https://icons8.kr/")!)
                        .foregroundColor(.black)
                }
                
                // 광고 문의 링크
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.green)
                    Link("광고 문의", destination: URL(string: "mailto:yang486741@gmail.com")!)
                        .foregroundColor(.black)
                }
            }
        }
        .navigationTitle("앱 정보")
        .background(Color(hex: "E8E6DD"))
        .scrollContentBackground(.hidden)
        .environment(\.colorScheme, .light)
    }
}

// 개인정보 처리방침 뷰
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("개인정보 처리방침")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("1. 개인정보의 처리 목적")
                        .font(.headline)
                    Text("ForMe는 다음의 목적을 위하여 개인정보를 처리합니다:\n• 사용자 일상 기록 서비스 제공\n• AI 대화 기능 제공 및 대화 내용 저장\n• 사용자 경험 개선 및 서비스 품질 향상")
                    
                    Text("2. 수집하는 개인정보 항목")
                        .font(.headline)
                    Text("ForMe는 다음의 개인정보 항목을 수집합니다:\n• 기기 고유 식별자\n• 사용자가 작성한 일상 기록 및 과제\n• AI와의 대화 내용\n• 앱 사용 로그")
                    
                    Text("3. 개인정보의 보유 및 이용기간")
                        .font(.headline)
                    Text("사용자의 개인정보는 서비스 이용 기간 동안 안전하게 보관되며, 계정 삭제 시 모든 데이터가 삭제됩니다.")
                }
                
                Group {
                    Text("4. 개인정보의 파기")
                        .font(.headline)
                    Text("앱 삭제 후 모든 개인정보는 자동으로 파기되며, 이는 복구할 수 없습니다.")
                    
                    Text("5. 개인정보의 제3자 제공")
                        .font(.headline)
                    Text("ForMe는 사용자의 개인정보를 제3자에게 제공하지 않습니다.")
                    
                    Text("6. AI 대화 데이터 처리")
                        .font(.headline)
                    Text("ForMe의 AI 대화 기능은 OpenAI API를 사용합니다. 사용자와 AI 간의 대화 내용은 대화 품질 향상을 위해 OpenAI에 전송될 수 있으며, 이는 OpenAI의 개인정보 처리방침을 따릅니다.")
                    
                    
                    Text("7. 개인정보 보호 책임자")
                        .font(.headline)
                    Text("개인정보 보호 책임자\n이메일: yang486741@gmail.com")
                    
                    Text("8. 변경 사항 고지")
                        .font(.headline)
                    Text("본 개인정보 처리방침은 법률 또는 서비스 변경사항을 반영하기 위해 수정될 수 있습니다. 변경사항이 있을 경우 앱 내 공지를 통해 사용자에게 알립니다.")
                    
                    Text("마지막 업데이트: 2024년 3월 18일")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                }
            }
            .padding()
        }
        .background(Color(hex: "E8E6DD").ignoresSafeArea())
        .navigationTitle("개인정보 처리방침")
        .environment(\.colorScheme, .light)
    }
}

#Preview {
    HomePage()
}
