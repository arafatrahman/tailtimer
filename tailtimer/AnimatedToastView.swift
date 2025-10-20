import SwiftUI

// A struct to hold the info for our toast
struct ToastInfo {
    var symbol: String
    var text: String
    var color: Color
}

// The animated toast view itself
struct AnimatedToastView: View {
    let info: ToastInfo
    
    // This binding allows the view to close itself
    @Binding var isShowing: Bool

    var body: some View {
        // --- THIS IS THE CHANGE ---
        // We remove the VStack and Spacer to allow the
        // ZStack in TodayView to center this content.
        HStack(spacing: 12) {
            Image(systemName: info.symbol)
                .font(.title)
                .foregroundColor(info.color)
            
            Text(info.text)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        // Change the transition to scale and fade
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            // Start a timer to hide the toast after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}
