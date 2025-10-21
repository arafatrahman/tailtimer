import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            // Once active, show the main content
            MainTabView()
        } else {
            // Show the splash screen with a gradient background
            ZStack {
                // Gradient Background (Orange to Red, as per the previous request's palette context)
                LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Change: Use Image("AppLogo") and appropriate modifiers
                    Image("AppLogo") // Reference the custom image asset
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150) // Set a specific size for the logo
                        .foregroundColor(.white) // Optional: applies tint if the logo is a template asset
                    
                    Text("MediTracker")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    // Animate the icon
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                    // Transition to main view after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}
