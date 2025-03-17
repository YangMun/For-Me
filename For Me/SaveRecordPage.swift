import SwiftUI

struct SaveButton: View {
    var action: () -> Void
    var isEnabled: Bool = true
    var isToday: Bool = true
    
    var body: some View {
        if isToday {
            Button(action: {
                if isEnabled {
                    action()
                }
            }) {
                HStack {
                    Spacer()
                    
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    Text("저장하기")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isEnabled ? Color(hex: "4CAF50") : Color.gray)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .disabled(!isEnabled)
        } else {
            EmptyView()
        }
    }
}
