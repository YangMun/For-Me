import SwiftUI

// Color Extension for Hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // 앱에서 사용되는 공통 색상 정의
    static let backgroundColor = Color(hex: "E8E6DD")
    static let accentColor = Color(hex: "6E3CBC")
}

// TabBar 스타일 설정을 위한 extension
extension UITabBar {
    static func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = UIColor(Color.backgroundColor)
        appearance.stackedLayoutAppearance.normal.iconColor = .black
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.accentColor)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
