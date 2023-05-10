import SwiftUI
import SceneKit
struct MountainView: UIViewRepresentable {
    var pattern: Pattern
    @State var pstptn:Pattern?=nil
    var update: Bool
    var scale:Float
    func makeUIView(context: Context) -> MountainMTKView {
        return MountainMTKView(frame: .init(x: 0, y: 0, width: 100, height: 200), pattern: pattern, update: update,scale: scale)
    }
    
    func updateUIView(_ uiView: MountainMTKView, context: Context) {
        if  !(pstptn == pattern) || !update{
            withAnimation(.easeInOut, {
                uiView.updateMountain(pattern: pattern,update:update,scaleEffect: scale)       
            })
            self.pstptn=pattern
        }
    }
    
    typealias UIViewType = MountainMTKView
}

struct ContentView: View {
    @State var False=false
    @State private var showView = false
    @State public var currentPattern = Pattern()
    @State public var likenow = false
    @State private var showGrid = false
    @State private var isLoading = false
    @State private var patterns:[Pattern] = []
    @State private var likes:[Pattern]=[]
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: 2)
    var body: some View {
        NavigationView{
            if showView{
                ZStack{
                    Color.gray.opacity(0.1).ignoresSafeArea()
                    VStack {   
                       MountainView(pattern: currentPattern, update:true,scale:1)
                                .frame(width: 300, height: 500, alignment: .center)
                                .rotationEffect(.degrees(180), anchor: .center)
                                .scaledToFit()
                                .mask { RoundedRectangle(cornerRadius: 6, style: .continuous) }
                                .overlay(alignment:.bottomLeading){
                                    Button(action: {
                                            likenow.toggle()
                                        likes.append(currentPattern)
                                    }, label: {
                                        Image(systemName: (likenow) ? "heart.fill" : "heart")
                                            .font(.headline)
                                            .padding(15)
                                            .background {
                                                Circle()
                                                    .fill(.regularMaterial)   
                                            }
                                            .padding()
                                    })
                                }
                                .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 14)
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        currentPattern=Pattern()
                                        likenow=false
                                    }
                                }
                    }
                    .popover(isPresented: .constant(showGrid), content: {
                        VStack {
                            if isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                ScrollView {
                                    LazyVGrid(columns: gridColumns) {
                                        ForEach(patterns, id: \.id) { pattern in
                                            MountainView(pattern: pattern,update: false,scale:0.5)
                                                
                                                .aspectRatio(300/500, contentMode: .fill)
                                                
                                                .rotationEffect(.degrees(180), anchor: .center)
                                                .mask { RoundedRectangle(cornerRadius: 6, style: .continuous) }
                                        
                                            
                                        }
                                        
                                    }
                                    
                                    .padding()
                                }
                            }
                        }
                        .onAppear {
                            isLoading = true
                            
                            DispatchQueue.main.async {
                                let loadedPatterns = PatternStorage.shared.loadPatterns()
                                patterns = loadedPatterns+likes
                                likes=[]
                                
                                PatternStorage.shared.save(patterns: patterns)
                                isLoading = false
                            }
                            
                        }
                        .onDisappear {
                            showGrid = false
                            isLoading=true
                        }
                    })
                    
                    .padding()
                }
                .overlay(alignment: .topTrailing){
                    
                        Button(action: {
                            withAnimation(.easeInOut) {
                                showGrid.toggle()
                            }
                        }, label: {
                            Image(systemName: "photo.stack.fill")
                                .font(.title2)
                                .padding()
                            
                        })
                        .padding()
                    
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showView = true
                }
            }
        }
    }
}

