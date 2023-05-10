import SwiftUI

//the start
struct SplashScreenView: View {
    @State private var showMainView = false
    
    var body: some View {
        ZStack {
            if !showMainView {
                
                Color.gray.opacity(0.1).ignoresSafeArea()
                
                VStack {
                    
                    Image("image")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: 250, alignment: .center)
                        .clipped()
                        .mask { RoundedRectangle(cornerRadius: 10, style: .continuous) }
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .padding(.top)
                    
                    Label(
                        title: { 
                            Text("The mountains flowed before the Lord Reiner")
                                .multilineTextAlignment(.center)
                                .font(
                                    .headline.monospaced().italic()
                                )
                        },
                        icon: { 
                            Image(systemName: "mountain.2")
                            
                        }
                    )
                    .padding(40)
                    
                    
                    
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        PatternStorage.shared.clear()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showMainView = true
                        }
                    }
                }
                
            }
            
            if showMainView {
                ContentView()
            }
        }
    }
}

